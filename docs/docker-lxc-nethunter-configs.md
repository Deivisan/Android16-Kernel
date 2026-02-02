# Docker/LXC/Nethunter - Configurações de Kernel

**Data:** 2025-02-02  
**Status:** A pesquisar  
**Responsável:** Agente Secundário (Kimi K2.5)

---

## 🎯 OBJETIVO

Documentar todas as CONFIG_* necessárias para:
- Docker completo
- LXC completo
- Kali NetHunter
- Containers em geral

---

## 📋 CONFIGS PARA DOCKER/LXC

### Obrigatórias (SEM ELAS NÃO FUNCIONA)
```
CONFIG_NAMESPACES=y                     # Namespaces (PID, network, mount, etc)
CONFIG_USER_NS=y                        # User namespaces (containers unprivileged)
CONFIG_NET_NS=y                         # Network namespaces
CONFIG_PID_NS=y                         # PID namespaces
CONFIG_UTS_NS=y                         # UTS namespaces
CONFIG_MOUNT_NS=y                       # Mount namespaces

CONFIG_CGROUPS=y                        # Control groups base
CONFIG_CGROUP_DEVICE=y                  # Device cgroup (Docker)
CONFIG_CGROUP_PIDS=y                    # PIDs cgroup
CONFIG_CGROUP_MEM_RES_CTLR=y            # Memory cgroup
CONFIG_CGROUP_MEM_RES_CTLR_SWAP=y       # Swap cgroup
CONFIG_CGROUP_NET_PRIO=y                # Network priority cgroup
CONFIG_CGROUP_FREEZER=y                 # freezer cgroup

CONFIG_SYSVIPC=y                        # System V IPC
CONFIG_POSIX_MQUEUE=y                   # POSIX message queues

CONFIG_OVERLAY_FS=y                     # Overlay filesystem (Docker layers)
CONFIG_VETH=y                           # Virtual ethernet devices
CONFIG_BRIDGE=y                         # Bridge networking
CONFIG_NETFILTER=y                      # Firewall (iptables)
CONFIG_NETFILTER_XTABLES=y              # iptables support
CONFIG_IP_NF_IPTABLES=y                 # IP tables
CONFIG_IP6_NF_IPTABLES=y                # IPv6 tables
```

### Recomendadas (PARA FUNCIONAMENTO COMPLETO)
```
CONFIG_MEMCG=y                          # Memory cgroup (alternativo)
CONFIG_MEMCG_SWAP=y                     # Swap accounting
CONFIG_MEMCG_KMEM=y                     # Kernel memory accounting
CONFIG_RD_XZ=y                          # Initrd compression
CONFIG_RD_LZ4=y                         # LZ4 compression
CONFIG_BLK_DEV_THROTTLING=y             # I/O throttling
CONFIG_CFQ_GROUP_IOSCHED=y              # CFQ I/O scheduler
CONFIG_NAMESPACES=y                     # Namespaces
CONFIG_NET_NS=y                         # Network namespace
CONFIG_PID_NS=y                         # PID namespace
CONFIG_UTS_NS=y                         # UTS namespace
CONFIG_USER_NS=y                        # User namespace (CRÍTICO!)
```

### Para Security (OPCIONAL)
```
CONFIG_SECURITY=y                       # Security framework
CONFIG_SECURITY_APPARMOR=y              # AppArmor
CONFIG_SECURITY_SELINUX=y               # SELinux (Android usa)
```

---

## 📋 CONFIGS PARA KALI NETHUNTER

### Wireless Drivers
```
CONFIG_CFG80211=y                       # cfg80211 API
CONFIG_CFG80211_CRDA_SUPPORT=y          # CRDA support
CONFIG_MAC80211=y                       # 802.11 stack
CONFIG_MAC80211_MESH=y                  # Mesh networking
CONFIG_MAC80211_LEDS=y                  # LED support
CONFIG_CFG80211_WEXT=y                  # WEXT compatibility
CONFIG_CFG80211_DEBUGFS=y               # Debug filesystem
CONFIG_CFG80211_INTERNAL_REGDB=y        # Internal regdb

CONFIG_NL80211_TESTMODE=y               # Test mode
CONFIG_CFG80211_DEVELOPER_WARNINGS=y    # Developer warnings
CONFIG_CFG80211_REG_CELLULAR_HINTS=y    # Cellular hints
CONFIG_CFG80211_REG_STATIC=y            # Static regulatory
```

### Monitor Mode / Injection
```
CONFIG_MAC80211=y                       # Base 802.11
CONFIG_MAC80211_HAS_RC=y                # Rate control
CONFIG_MAC80211_RC_MINSTREL=y           # Minstrel rate control
CONFIG_MAC80211_RC_MINSTREL_HT=y        # HT rate control
CONFIG_MAC80211_RC_MINSTREL_VHT=y       # VHT rate control
CONFIG_MAC80211_RC_DEFAULT_MINSTREL=y   # Default rate control

CONFIG_CFG80211=y                       # cfg80211
CONFIG_CFG80211_WEXT=y                  # WEXT
CONFIG_CFG80211_DEFAULT_PS=y            # Default power save
```

### USB Gadget
```
CONFIG_USB_GADGET=y                     # USB Gadget
CONFIG_USB_GADGETFS=y                   # Gadget filesystem
CONFIG_USB_F_FS=y                       # FunctionFS
CONFIG_USB_U_ETHER=y                    # Ethernet gadget
CONFIG_USB_F_ECM=y                      # ECM gadget
CONFIG_USB_F_RNDIS=y                    # RNDIS gadget
CONFIG_USB_F_MASS_STORAGE=y             # Mass storage gadget
```

### Network Tools
```
CONFIG_NETFILTER=y                      # Firewall
CONFIG_NETFILTER_XTABLES=y              # iptables
CONFIG_IP_NF_IPTABLES=y                 # IP tables
CONFIG_IP_NF_FILTER=y                   # IP filter
CONFIG_IP_NF_MANGLE=y                   # IP mangling
CONFIG_IP_NF_RAW=y                      # Raw IP
CONFIG_IP6_NF_IPTABLES=y                # IPv6 tables
CONFIG_IP6_NF_FILTER=y                  # IPv6 filter
CONFIG_IP6_NF_MANGLE=y                  # IPv6 mangling
CONFIG_IP6_NF_RAW=y                     # IPv6 raw

CONFIG_NF_CONNTRACK=y                   # Connection tracking
CONFIG_NF_CONNTRACK_IPV4=y              # IPv4 conntrack
CONFIG_NF_CONNTRACK_IPV6=y              # IPv6 conntrack
CONFIG_NETFILTER_CONNCOUNT=y            # Connection count
```

---

## 🔗 DEPENDÊNCIAS ENTRE CONFIGS

```
Cgroups v1 (usado pelo Docker/LXC)
├── CONFIG_CGROUPS=y
│   ├── CONFIG_CGROUP_DEVICE=y
│   ├── CONFIG_CGROUP_PIDS=y
│   ├── CONFIG_CGROUP_MEM_RES_CTLR=y
│   └── CONFIG_CGROUP_NET_PRIO=y
│
Namespaces
├── CONFIG_NAMESPACES=y
│   ├── CONFIG_USER_NS=y (CRÍTICO!)
│   ├── CONFIG_NET_NS=y
│   ├── CONFIG_PID_NS=y
│   └── CONFIG_UTS_NS=y
│
Overlay Filesystem
├── CONFIG_OVERLAY_FS=y
│   └── CONFIG_OVERLAY_FS_REDIRECT_DIR=y (opcional)
│
Networking
├── CONFIG_VETH=y
├── CONFIG_BRIDGE=y
└── CONFIG_NETFILTER=y
```

---

## ⚠️ CONFLITOS CONHECIDOS

### SELinux vs AppArmor
```
⚠️ NÃO USAR AMBOS!
Escolha um:
- CONFIG_SECURITY_SELINUX=y (Android usa)
- CONFIG_SECURITY_APPARMOR=y (Ubuntu Touch usa)
```

### Cgroups v1 vs v2
```
⚠️ KERNEL 5.4 USA CGROUPS V1 POR PADRÃO
Docker/LXC funcionam melhor com v1

Se usar v2:
CONFIG_CGROUP_SCHED=y
CONFIG_CGROUP_RDMA=y
CONFIG_CGROUP_MISC=y
```

---

## 📊 CHECKLIST DE VERIFICAÇÃO

### Verificar se Docker funciona:
```bash
adb shell cat /proc/config.gz | grep -E "USER_NS|CGROUP_DEVICE|OVERLAY_FS"

# Esperado:
CONFIG_USER_NS=y
CONFIG_CGROUP_DEVICE=y
CONFIG_OVERLAY_FS=y
```

### Verificar se NetHunter funciona:
```bash
adb shell cat /proc/config.gz | grep -E "MAC80211|CFG80211"

# Esperado:
CONFIG_MAC80211=y
CONFIG_CFG80211=y
```

---

## 🔧 TROUBLESHOOTING - PROBLEMAS COMUNS

### Problema 1: "Your kernel does not support cgroup memory limit"
**Causa:** CONFIG_CGROUP_MEM_RES_CTLR ou CONFIG_MEMCG não habilitado

**Solução:**
```bash
# Verificar config
adb shell cat /proc/config.gz | grep MEMCG

# Deve mostrar:
CONFIG_MEMCG=y
# ou
CONFIG_CGROUP_MEM_RES_CTLR=y

# Se não tiver, recompilar kernel com:
make menuconfig
# General Setup > Control Group support > Memory controller
```

**Mitigação temporária:**
```bash
# Desabilitar memory limit no Docker
adb shell docker run --memory="" <container>
```

---

### Problema 2: "Cannot start container: failed to create cgroup"
**Causa:** Cgroups não montados ou configs faltando

**Solução:**
```bash
# Verificar se cgroups estão montados
adb shell mount | grep cgroup

# Se não estiver, montar manualmente:
adb shell mount -t tmpfs none /sys/fs/cgroup
adb shell mkdir -p /sys/fs/cgroup/memory
adb shell mkdir -p /sys/fs/cgroup/devices
adb shell mount -t cgroup none /sys/fs/cgroup/memory -o memory
adb shell mount -t cgroup none /sys/fs/cgroup/devices -o devices
```

**Verificar configs:**
```bash
adb shell cat /proc/config.gz | grep -E "CGROUPS|CGROUP_DEVICE|CGROUP_PIDS"
```

---

### Problema 3: "overlay: filesystem on '/var/lib/docker' not supported"
**Causa:** CONFIG_OVERLAY_FS não habilitado

**Solução:**
```bash
# Verificar suporte a overlay
adb shell cat /proc/config.gz | grep OVERLAY_FS

# Deve mostrar:
CONFIG_OVERLAY_FS=y

# Alternativa: usar vfs driver (sem camadas)
adb shell dockerd --storage-driver=vfs
```

---

### Problema 4: "failed to create shim: OCI runtime create failed"
**Causa:** Namespaces não configurados ou runc incompátivel

**Solução:**
```bash
# Verificar namespaces
adb shell cat /proc/config.gz | grep -E "USER_NS|PID_NS|NET_NS"

# Todos devem estar =y
CONFIG_USER_NS=y
CONFIG_PID_NS=y
CONFIG_NET_NS=y

# Verificar versão do runc
adb shell runc --version
```

---

### Problema 5: NetHunter - "Monitor mode not supported"
**Causa:** Driver WiFi não suporta monitor mode ou configs faltando

**Solução:**
```bash
# Verificar configs wireless
adb shell cat /proc/config.gz | grep -E "CFG80211|MAC80211"

# Devem estar:
CONFIG_CFG80211=y
CONFIG_MAC80211=y
CONFIG_NL80211_TESTMODE=y

# Verificar driver atual
adb shell ls -la /vendor/lib/modules/ | grep wifi

# Se driver for proprietário (qcom), monitor mode pode não funcionar
```

---

### Problema 6: "iptables: No chain/target/match by that name"
**Causa:** Módulos netfilter não carregados

**Solução:**
```bash
# Verificar configs netfilter
adb shell cat /proc/config.gz | grep -E "NETFILTER|IP_NF_IPTABLES|IP6_NF_IPTABLES"

# Carregar módulos (se compilados como módulos)
adb shell insmod /vendor/lib/modules/xt_conntrack.ko
adb shell insmod /vendor/lib/modules/xt_addrtype.ko
adb shell insmod /vendor/lib/modules/xt_tcpudp.ko
```

---

### Problema 7: "write /proc/self/oom_score_adj: permission denied"
**Causa:** CONFIG_USER_NS não habilitado (containers unprivileged)

**Solução:**
```bash
# Verificar
adb shell cat /proc/config.gz | grep USER_NS

# Se não tiver, recompilar kernel
# OU rodar container como root (não recomendado)
adb shell docker run --privileged <container>
```

---

## ✅ COMANDOS DE VERIFICAÇÃO COMPLETOS

### Verificação Completa de Docker:
```bash
#!/bin/bash
# save as: check-docker.sh

echo "=== Verificando configs Docker/LXC ==="
echo ""

configs=(
    "CONFIG_NAMESPACES"
    "CONFIG_USER_NS"
    "CONFIG_NET_NS"
    "CONFIG_PID_NS"
    "CONFIG_UTS_NS"
    "CONFIG_CGROUPS"
    "CONFIG_CGROUP_DEVICE"
    "CONFIG_CGROUP_PIDS"
    "CONFIG_CGROUP_MEM_RES_CTLR"
    "CONFIG_CGROUP_FREEZER"
    "CONFIG_SYSVIPC"
    "CONFIG_POSIX_MQUEUE"
    "CONFIG_OVERLAY_FS"
    "CONFIG_VETH"
    "CONFIG_BRIDGE"
    "CONFIG_NETFILTER"
    "CONFIG_IP_NF_IPTABLES"
    "CONFIG_IP6_NF_IPTABLES"
)

for config in "${configs[@]}"; do
    result=$(adb shell cat /proc/config.gz 2>/dev/null | gunzip 2>/dev/null | grep "^$config=y" | head -1)
    if [ -n "$result" ]; then
        echo "✅ $config"
    else
        echo "❌ $config - AUSENTE"
    fi
done

echo ""
echo "=== Verificando cgroups ==="
adb shell cat /proc/cgroups

echo ""
echo "=== Verificando namespaces ==="
adb shell ls -la /proc/self/ns/
```

### Verificação Completa de NetHunter:
```bash
#!/bin/bash
# save as: check-nethunter.sh

echo "=== Verificando configs NetHunter ==="
echo ""

configs=(
    "CONFIG_CFG80211"
    "CONFIG_CFG80211_CRDA_SUPPORT"
    "CONFIG_MAC80211"
    "CONFIG_MAC80211_MESH"
    "CONFIG_NL80211_TESTMODE"
    "CONFIG_USB_GADGET"
    "CONFIG_USB_GADGETFS"
)

for config in "${configs[@]}"; do
    result=$(adb shell cat /proc/config.gz 2>/dev/null | gunzip 2>/dev/null | grep "^$config=y" | head -1)
    if [ -n "$result" ]; then
        echo "✅ $config"
    else
        echo "❌ $config - AUSENTE"
    fi
done

echo ""
echo "=== Verificando interfaces wireless ==="
adb shell ip link | grep wlan

echo ""
echo "=== Verificando drivers ==="
adb shell lsmod | grep -E "cfg80211|mac80211|wlan"
```

---

## 📊 CHECKLIST DE IMPLEMENTAÇÃO

### Fase 1: Configs Obrigatórias (Docker funcional)
- [ ] CONFIG_NAMESPACES=y
- [ ] CONFIG_USER_NS=y
- [ ] CONFIG_CGROUPS=y
- [ ] CONFIG_CGROUP_DEVICE=y
- [ ] CONFIG_CGROUP_PIDS=y
- [ ] CONFIG_OVERLAY_FS=y
- [ ] CONFIG_NETFILTER=y
- [ ] CONFIG_VETH=y
- [ ] CONFIG_BRIDGE=y

### Fase 2: Configs Recomendadas (Performance)
- [ ] CONFIG_CGROUP_MEM_RES_CTLR=y
- [ ] CONFIG_MEMCG=y
- [ ] CONFIG_BLK_DEV_THROTTLING=y
- [ ] CONFIG_CFQ_GROUP_IOSCHED=y

### Fase 3: Configs NetHunter
- [ ] CONFIG_CFG80211=y
- [ ] CONFIG_MAC80211=y
- [ ] CONFIG_NL80211_TESTMODE=y
- [ ] CONFIG_USB_GADGET=y

### Fase 4: Testes
- [ ] Docker info funciona
- [ ] Docker run hello-world funciona
- [ ] LXC-checkconfig passa
- [ ] Monitor mode testado (se hardware permitir)

---

## 🔗 REFERÊNCIAS OFICIAIS

### Docker
- Docker Kernel Requirements: https://docs.docker.com/engine/install/binaries/#kernel-requirements
- Docker on ARM: https://docs.docker.com/build/building/multi-platform/
- Moby Project: https://github.com/moby/moby/blob/master/contrib/check-config.sh

### LXC
- LXC Kernel Requirements: https://linuxcontainers.org/lxc/getting-started/
- Ubuntu LXC Guide: https://documentation.ubuntu.com/lxc/en/latest/
- LXC-checkconfig: https://github.com/lxc/lxc/blob/main/src/lxc/lxc-checkconfig.in

### NetHunter
- Kali NetHunter Kernel Requirements: https://www.kali.org/docs/nethunter/nethunter-kernel-requirements/
- NetHunter GitHub: https://github.com/offensive-security/kali-nethunter
- Wireless Drivers: https://www.kali.org/docs/nethunter/wireless-cards/

### Kernel
- Kernel Config Docs: https://www.kernel.org/doc/html/latest/admin-guide/kernel-parameters.html
- Cgroups v1: https://www.kernel.org/doc/html/latest/admin-guide/cgroup-v1/index.html
- Namespaces: https://man7.org/linux/man-pages/man7/namespaces.7.html
- OverlayFS: https://www.kernel.org/doc/html/latest/filesystems/overlayfs.html

### Snapdragon/ARM64
- ARM64 Kernel Build: https://www.kernel.org/doc/html/latest/arm64/index.html
- Qualcomm Open Source: https://www.codeaurora.org/

---

**Documento:** ✅ COMPLETO  
**Autor:** Agente Secundário (Kimi K2.5)  
**Data:** 2025-02-02  
**Status:** Pronto para uso pelo Agente Primário
