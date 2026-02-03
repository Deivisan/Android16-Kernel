# 🦞 DevSan Kernel Build Laboratory - Moonstone

> Ambiente de build profissional para kernel Android POCO X5 5G
> Versão: 1.0.0
> DevSan AGI

---

## 📋 Estrutura

```
laboratorio/
├── 📄 Dockerfile                      # Imagem Docker Ubuntu 20.04 + NDK r23b
├── 📄 docker-compose.yml              # Configuração Docker Compose
├── 📜 build-moonstone-docker.sh     # Script principal de build
├── 📜 scripts/                      # Scripts auxiliares
│   ├── setup-docker.sh              # Setup inicial automático
│   ├── validate-build.sh            # Validações pré-build
│   └── apply-fixes.sh              # Correções automáticas
├── 📦 out/                          # Output do build (Image.gz)
├── 📋 logs/                         # Logs de build e resumos
├── 📄 DOCKER-BUILD-GUIDE.md      # Guia completo
├── 📄 KNOWN-ISSUES.md            # Erros conhecidos
├── 📄 EXPECTED-OUTPUT.md         # Output esperado
└── 📄 README.md                     # Este arquivo
```

---

## 🚀 Quick Start

### Setup Inicial (Uma vez)

```bash
cd /home/deivi/Projetos/Android16-Kernel/laboratorio
./scripts/setup-docker.sh
```

### Compilar Kernel

```bash
cd /home/deivi/Projetos/Android16-Kernel/laboratorio
./build-moonstone-docker.sh
```

### Variáveis de Build

```bash
# Compilar com 8 jobs (padrão: nproc)
JOBS=8 ./build-moonstone-docker.sh

# Compilar com limpeza anterior
CLEAN=yes ./build-moonstone-docker.sh

# Compilar tipo específico
BUILD_TYPE=qgki ./build-moonstone-docker.sh
```

---

## 📚 Documentação

- **DOCKER-BUILD-GUIDE.md** - Guia completo de build
  - Como funciona o sistema
  - Como customizar builds
  - Troubleshooting detalhado
  - Como testar no device

- **KNOWN-ISSUES.md** - Erros conhecidos
  - Erros documentados
  - Soluções testadas
  - Como contribuir com novos erros

- **EXPECTED-OUTPUT.md** - Output esperado
  - Arquivos gerados
  - Métricas de build
  - Validação do kernel
  - Checklists de teste

---

## 🔧 Scripts

### build-moonstone-docker.sh (Principal)

Script principal que orquestra todo o processo:

1. ✅ Valida ambiente (toolchain, espaço, configs)
2. 🔧 Aplica correções automáticas (tracing, format strings)
3. ⚡ Compila com NDK r23b Clang r416183b
4. ✅ Valida resultado (tamanho, SHA256)
5. 📝 Gera relatório completo

Uso:
```bash
./build-moonstone-docker.sh
```

### setup-docker.sh (Setup Inicial)

Configura ambiente Docker automaticamente:

1. Verifica Docker instalado
2. Cria estrutura de diretórios
3. Configura ccache (50GB)
4. Valida pré-requisitos
5. Prepara scripts auxiliares

Uso:
```bash
./scripts/setup-docker.sh
```

### validate-build.sh (Validação)

Verifica ambiente antes de compilar:

1. Verifica kernel source
2. Verifica toolchain (Clang)
3. Valida configs críticas
4. Verifica espaço em disco
5. Verifica RAM disponível
6. Verifica ccache

Uso:
```bash
./scripts/validate-build.sh
```

### apply-fixes.sh (Correções)

Aplica correções automáticas:

1. Corrige arquivos de tracing
2. Corrige strings de formato em codecs
3. Verifica techpacks problemáticos
4. Ajusta configs críticas
5. Ajusta permissões

Uso:
```bash
./scripts/apply-fixes.sh
```

---

## 🐳 Docker

### Build Image

```bash
cd /home/deivi/Projetos/Android16-Kernel/laboratorio
docker-compose build --no-cache
```

### Start Container

```bash
docker-compose up -d
docker-compose exec kernel-build bash
```

### Stop Container

```bash
docker-compose down
```

---

## 📊 Diretórios Importantes

### out/ (Output)

Arquivos gerados pelo build:
- `Image.gz` - Kernel comprimido (15-25MB)
- `vmlinux` - ELF não-comprimido (50-100MB)
- `System.map` - Símbolos do kernel (10-20MB)
- `dts/` - Device Tree Blobs

### logs/ (Logs)

Logs de build e resumos:
- `build-YYYYMMDD-HHMMSS.log` - Log completo
- `summary-YYYYMMDD-HHMMSS.txt` - Resumo

### scripts/ (Auxiliares)

Scripts de automação e correção:
- `setup-docker.sh` - Setup inicial
- `validate-build.sh` - Validação
- `apply-fixes.sh` - Correções

---

## 🎯 Target Device

- **Device:** POCO X5 5G (moonstone/rose)
- **SoC:** Snapdragon 695 (SM6375)
- **CPU:** Qualcomm Kryo 660 (2x2.4GHz + 6x1.8GHz)
- **GPU:** Adreno 619
- **Kernel:** MSM 5.4 + Android Patches
- **Toolchain:** Clang r416183b (Android NDK r23b)
- **Arch:** ARM64 (armv8.2-a)

---

## ⚡ Performance

### Ryzen 7 5700G (16 threads)

- **1° Build (sem ccache):** 2-3 horas
- **Rebuild (com ccache):** 30-45 minutos
- **Jobs recomendados:** 8-16

### Configuração Otimizada

```bash
# /home/deivi/.ccache/ccache.conf
max_size = 50G
compression = true
umask = 002
stats_log = true
```

---

## 🔍 Debugging

### Verificar Log de Build

```bash
tail -f /home/deivi/Projetos/Android16-Kernel/laboratorio/logs/build-*.log
```

### Verificar ccache Stats

```bash
docker-compose exec kernel-build ccache -s
```

### Verificar Status do Container

```bash
docker-compose ps
docker-compose logs kernel-build
```

---

## 🤝 Contribuindo

Para melhorar o sistema:

1. Documentar novo erro em `KNOWN-ISSUES.md`
2. Adicionar correção em `apply-fixes.sh`
3. Testar e validar
4. Atualizar `DOCKER-BUILD-GUIDE.md`
5. Atualizar este README

---

## 📝 Notas Importantes

- ✅ **Dockerfile** baixa NDK r23b automaticamente
- ✅ **ccache** configurado com 50GB
- ✅ **Correções automáticas** para tracing e format strings
- ✅ **Validações** pré-build para evitar tempo perdido
- ✅ **Logs detalhados** para debugging
- ⚠️ **Format strings** em codecs requerem correção manual em alguns casos
- ⚠️ **Techpacks problemáticos** identificados mas não desativados automaticamente

---

## 🎉 Checklist de Build Completo

Antes de considerar build como "bem-sucedido", verificar:

- [ ] Image.gz existe (15-25MB)
- [ ] vmlinux existe
- [ ] System.map existe
- [ ] SHA256 calculado
- [ ] Build log sem erros
- [ ] Summary log gerado
- [ ] Configs críticas habilitadas
- [ ] Validações passadas

**Se TODOS checkmarks, build está pronto para teste!**

---

**🦞 DevSan AGI - v1.0.0 - 2026**  
**Author:** Deivison Santana (@deivisan)  
**Project:** Android16 Kernel - Moonstone Build System  
**Target:** POCO X5 5G (Snapdragon 695)
