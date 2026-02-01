# 🎯 CHECKLIST - Kernel Build Process

> Checklist técnico passo a passo para compilação do kernel Halium

---

## FASE 1: PRÉ-REQUISITOS (PC Arch Linux)

### Hardware/Software Check
- [ ] CPU: AMD Ryzen 7 5700G confirmado (8C/16T)
- [ ] RAM: 14GB total, 9.7GB+ disponível
- [ ] Espaço em disco: 50GB+ livre em SSD NVMe
- [ ] OS: Arch Linux atualizado (`sudo pacman -Syu`)
- [ ] Kernel: Zen 6.18.7 (verificar: `uname -r`)

### Toolchain Installation
```bash
# Executar e verificar cada um:
sudo pacman -S aarch64-linux-gnu-gcc clang llvm lld make bc cpio kmod git

which aarch64-linux-gnu-gcc  # ✅ /usr/bin/aarch64-linux-gnu-gcc
which clang                  # ✅ /usr/bin/clang
which make                   # ✅ /usr/bin/make
which bc                     # ✅ /usr/bin/bc
```

- [ ] aarch64-linux-gnu-gcc instalado
- [ ] clang instalado
- [ ] make instalado
- [ ] bc instalado

### Repository Setup
- [ ] Repo clonado em `~/Projetos/Android16-Kernel/`
- [ ] Branch atual: `main`
- [ ] Backups extraídos e verificados

```bash
cd ~/Projetos/Android16-Kernel/
ls -lh backups/poco-x5-5g-rose-2025-02-01/
# device-images-backup-2025-02-01.tar.xz (12M)
# kernel-config-5.4.302-eclipse.txt (175K)
```

---

## FASE 2: KERNEL SOURCE

### Obter Source Code

**Opção A - Xiaomi (Preferida):**
- [ ] Verificar disponibilidade: https://github.com/MiCode/Xiaomi_Kernel_OpenSource
- [ ] Procurar branches: `moonstone-q-oss`, `moonstone-r-oss`, `rose-*`
- [ ] Se encontrado:
```bash
git clone https://github.com/MiCode/Xiaomi_Kernel_OpenSource.git \
  -b moonstone-q-oss kernel-source
```

**Opção B - Generic msm-5.4 (Fallback):**
- [ ] Se Xiaomi não disponibilizou:
```bash
git clone https://github.com/android-linux-stable/msm-5.4.git kernel-source
```

**Opção C - Upstream Linux (Último recurso):**
- [ ] Se nada acima funcionar:
```bash
git clone --depth=1 https://github.com/torvalds/linux.git -b v5.4 kernel-source
# AVISO: Requer MUITO mais patches!
```

### Verificar Source
- [ ] Diretório `kernel-source/` existe
- [ ] Arquivo `Makefile` presente
- [ ] Versão correta: 5.4.x
```bash
cd kernel-source
grep "^VERSION =" Makefile  # Deve mostrar 5
grep "^PATCHLEVEL =" Makefile  # Deve mostrar 4
```

---

## FASE 3: CONFIGURAÇÃO

### Copiar Config Base
- [ ] Copiar config do backup:
```bash
cp backups/poco-x5-5g-rose-2025-02-01/kernel-config-5.4.302-eclipse.txt \
   kernel-source/.config
```

- [ ] Verificar cópia:
```bash
ls -lh kernel-source/.config  # ~175KB
```

### Verificar Configs Críticas (Automático)
- [ ] Rodar script de verificação:
```bash
cd kernel-source
../build-scripts/check-configs.sh .config
```

**Resultado esperado:**
```
✅ CONFIG_USER_NS: OK
✅ CONFIG_CGROUP_DEVICE: OK
✅ CONFIG_CGROUP_PIDS: OK
✅ CONFIG_SYSVIPC: OK
✅ CONFIG_POSIX_MQUEUE: OK
✅ CONFIG_IKCONFIG_PROC: OK
✅ CONFIG_SECURITY_APPARMOR: OK
```

**Se mostrar ❌:**
- [ ] Editar configs:
```bash
make ARCH=arm64 menuconfig
# Navegar e habilitar configs faltando
# OU usar sed:
sed -i 's/# CONFIG_USER_NS is not set/CONFIG_USER_NS=y/' .config
# (repetir para cada config faltante)
```

### Configs Manual (Menuconfig)
Se precisar editar manualmente:

```bash
cd kernel-source
make ARCH=arm64 menuconfig
```

Navegar e habilitar:
- [ ] General setup → Namespaces support → User namespace (=y)
- [ ] General setup → System V IPC (=y)
- [ ] General setup → POSIX Message Queues (=y)
- [ ] General setup → Kernel .config support → Enable access... (=y)
- [ ] Control Group support → Memory controller (=y)
- [ ] Control Group support → I/O controller (=y)
- [ ] Control Group support → Device controller (=y)
- [ ] Control Group support → PIDs controller (=y)
- [ ] Security options → AppArmor support (=y)
- [ ] Security options → Default security module (AppArmor)

---

## FASE 4: PATCHES HALIUM

### Clonar Patches
- [ ] Clonar repositório:
```bash
cd ~/Projetos/Android16-Kernel/
git clone https://github.com/Halium/hybris-patches.git
```

### Aplicar Patches
- [ ] Aplicar no kernel:
```bash
cd kernel-source
../hybris-patches/apply-patches.sh --mb
```

- [ ] Verificar aplicação:
```bash
git log --oneline -10
# Deve mostrar commits tipo:
# a1b2c3d (HEAD) hybris: binder modifications
# e4f5g6h hybris: ashmem support
# ...
```

**Se falhar:**
- [ ] Tentar aplicar manualmente:
```bash
for patch in ../hybris-patches/patches/*.patch; do
    echo "Aplicando: $patch"
    patch -p1 < "$patch" || echo "❌ Falhou: $patch"
done
```

---

## FASE 5: COMPILAÇÃO

### Preparar Ambiente
```bash
cd kernel-source

export ARCH=arm64
export SUBARCH=arm64
export CROSS_COMPILE=aarch64-linux-gnu-
export CC=clang
export CLANG_TRIPLE=aarch64-linux-gnu-
export KCFLAGS="-O2 -pipe"
export KAFLAGS="-O2 -pipe"
```

### Iniciar Build
```bash
# Tempo estimado: 4-8 horas (Ryzen 7 5700G, -j16)
time make -j$(nproc) Image.gz 2>&1 | tee ../out/build-$(date +%Y%m%d-%H%M%S).log
```

### Monitorar
Durante compilação:
- [ ] Sem erros de "command not found"
- [ ] Sem "out of memory"
- [ ] Progresso visível (arquivos .o sendo compilados)

**Se "out of memory":**
- [ ] Reduzir paralelismo: `make -j8` em vez de `-j16`

### Verificar Resultado
- [ ] Arquivo gerado:
```bash
ls -lh arch/arm64/boot/Image.gz
```
**Esperado:** 15-25MB

- [ ] Verificar tipo:
```bash
file arch/arm64/boot/Image.gz
# "gzip compressed data..."
```

- [ ] Copiar para out/:
```bash
cp arch/arm64/boot/Image.gz \
   ../out/Image.gz-$(date +%Y%m%d-%H%M%S)
```

---

## FASE 6: TESTE NO DEVICE

### Preparar Device
- [ ] Cabo USB conectado
- [ ] Device com Android funcionando (Slot A)
- [ ] Depuração USB habilitada
- [ ] Bootloader desbloqueado (já está)

### Boot Temporário (SEGURO)
```bash
# Reboot para fastboot
adb reboot bootloader

# Boot temporário (NÃO FLASHA!)
fastboot boot out/Image.gz-YYYYMMDD-HHMMSS
```

### Verificar
- [ ] Device bootou?
- [ ] Tela funciona?
- [ ] Touch responde?

**Se bootou:**
```bash
# Capturar logs:
adb shell dmesg > logs/dmesg-halium-$(date +%Y%m%d-%H%M%S).log
adb shell uname -a
# Deve mostrar kernel version novo
```

**Se NÃO bootou:**
- [ ] Device reiniciou automaticamente?
- [ ] Pegar logs via `fastboot oem dmesg` (se suportado)
- [ ] Voltar ao Android: `fastboot reboot` (volta sozinho para Slot A)

---

## FASE 7: FLASH PERMANENTE (OPCIONAL)

**SÓ fazer se FASE 6 funcionou!**

### Backup Slot B
- [ ] Salvar boot_b atual (se quiser):
```bash
fastboot boot_b backup-boot-b-$(date +%Y%m%d).img
```

### Flash em Slot B
```bash
# Flash kernel
fastboot flash boot_b out/Image.gz-YYYYMMDD-HHMMSS

# Flash DTBO (do backup)
fastboot flash dtbo_b backups/poco-x5-5g-rose-2025-02-01/device-images/dtbo.img

# Desabilitar verificação
fastboot --disable-verity --disable-verification flash vbmeta_b \
  backups/poco-x5-5g-rose-2025-02-01/device-images/vbmeta.img

# Ativar slot B
fastboot set_active b

# Reboot
fastboot reboot
```

### Verificar Dual Boot
- [ ] Device bootou em Slot B?
- [ ] Testar funcionalidades básicas
- [ ] **CRÍTICO:** Testar switch para Slot A:
```bash
adb reboot bootloader
fastboot set_active a
fastboot reboot
```
- [ ] Android original ainda funciona?

**Se Android não bootar:**
- [ ] Recuperar via fastboot:
```bash
fastboot --set-active=a
fastboot reboot
```

---

## FASE 8: DOCUMENTAÇÃO

### Registrar Resultados
- [ ] Build sucedido: Documentar tempo, tamanho, configs
- [ ] Build falhou: Documentar erro, tentativa de solução
- [ ] Teste no device: Documentar o que funciona/não funciona
- [ ] Atualizar este CHECKLIST com aprendizados

### Commit
```bash
git add -A
git commit -m "kernel: Build v5.4.302-halium para POCO X5 5G

- Configs habilitadas: USER_NS, CGROUP_DEVICE, etc
- Patches: hybris-patches aplicados
- Build time: Xh Ym
- Size: XXMB
- Test: [bootou/não bootou]
- Status: [funcional/parcial/não funcional]"
```

---

## ✅ CRITÉRIOS DE CONCLUSÃO

### Sucesso Total
- [ ] Kernel compilou sem erros
- [ ] Todas configs críticas habilitadas
- [ ] Boot temporário funcionou
- [ ] Slot B boota corretamente
- [ ] Slot A (Android) ainda funciona
- [ ] Pronto para instalar Halium/Droidian

### Sucesso Parcial
- [ ] Kernel compilou
- [ ] Boota mas com limitações
- [ ] Documentar limitações
- [ ] Identificar próximos passos

### Falha
- [ ] Kernel não compilou OU
- [ ] Não boota no device
- [ ] Documentar erros
- [ ] Analisar próxima tentativa

---

## 🚨 EMERGÊNCIAS

### Recuperação de Brick (se slot B falhar)
```bash
# Device em fastboot
fastboot set_active a  # Volta para Android
fastboot reboot

# Se não funcionar, flashar Android original de volta:
# (Ter imagens de fábrica salvas)
```

### Recuperação de Config
```bash
# Se .config foi corrompido:
cd kernel-source
cp ../backups/poco-x5-5g-rose-2025-02-01/kernel-config-5.4.302-eclipse.txt .config
```

---

**Iniciar processo:** `bun run build` ou `./build-scripts/build-kernel.sh`  
**Verificar configs:** `bun run check` ou `./build-scripts/check-configs.sh`  
**Documento criado:** 2025-02-01  
**Última atualização:** 2025-02-01
