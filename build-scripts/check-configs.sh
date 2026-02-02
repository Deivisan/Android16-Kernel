#!/bin/bash
# check-configs.sh - Verificar configs críticas para Halium/LXC
# Uso: ./check-configs.sh [caminho/.config]

CONFIG_FILE="${1:-../kernel-source/.config}"

if [ ! -f "$CONFIG_FILE" ]; then
    echo "❌ Arquivo .config não encontrado: $CONFIG_FILE"
    echo "Uso: $0 [caminho/.config]"
    exit 1
fi

echo "🔍 Verificando configs em: $CONFIG_FILE"
echo ""

CONFIGS_CRITICAS="USER_NS CGROUP_DEVICE CGROUP_PIDS CGROUP_MEM_RES_CTLR SYSVIPC POSIX_MQUEUE IKCONFIG PROC IKCONFIG_PROC SECURITY_APPARMOR DEFAULT_SECURITY"

FALTANDO=0

for CONFIG in $CONFIGS_CRITICAS; do
    VALUE=$(grep "^CONFIG_$CONFIG[= ]" "$CONFIG_FILE" 2>/dev/null || echo "NOT_FOUND")
    
    if echo "$VALUE" | grep -q "=y"; then
        echo "✅ CONFIG_$CONFIG: OK"
    elif echo "$VALUE" | grep -q "=m"; then
        echo "⚠️  CONFIG_$CONFIG: Módulo (recomendado built-in =y)"
    elif echo "$VALUE" | grep -q "NOT_FOUND"; then
        echo "❌ CONFIG_$CONFIG: AUSENTE (is not set)"
        FALTANDO=$((FALTANDO + 1))
    else
        echo "❌ CONFIG_$CONFIG: $VALUE"
        FALTANDO=$((FALTANDO + 1))
    fi
done

echo ""
if [ $FALTANDO -eq 0 ]; then
    echo "✅ Todas configs críticas estão habilitadas!"
    exit 0
else
    echo "❌ $FALTANDO config(s) faltando ou incorreta(s)"
    echo "Execute: make ARCH=arm64 menuconfig"
    exit 1
fi
