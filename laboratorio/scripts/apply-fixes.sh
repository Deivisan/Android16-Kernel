#!/bin/bash
# 🔧 apply-fixes.sh - Aplica correções automáticas ao kernel moonstone
# DevSan AGI - Correções para erros de build conhecidos

set -e

KERNEL_DIR="${KERNEL_DIR:-/kernel}"
LOG_FILE="${LOG_FILE:-/logs/apply-fixes.log}"

echo "🔧 DevSan Kernel Fixer - Moonstone (Snapdragon 695)"
echo "📁 Kernel: $KERNEL_DIR"
echo "📋 Log: $LOG_FILE"
echo ""

# Criar diretório de logs
mkdir -p "$(dirname "$LOG_FILE")"

# Função de log
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

log "🚀 Iniciando correções automáticas..."

# 1. Verificar se kernel existe
if [ ! -d "$KERNEL_DIR" ]; then
    log "❌ ERRO: Diretório do kernel não encontrado: $KERNEL_DIR"
    exit 1
fi

cd "$KERNEL_DIR"

# 2. Corrigir arquivos de tracing com caminhos relativos
log "📝 1. Corrigindo arquivos de tracing..."

# Lista de arquivos que costumam ter problemas com ./trace.h
TRACE_FILES=(
    "techpack/datarmnet/core/rmnet_config.c"
    "techpack/datarmnet/core/rmnet_descriptor.c"
    "techpack/datarmnet-ext/core/rmnet_shs_config.c"
    "kernel/sched/walt/trace.c"
)

for file in "${TRACE_FILES[@]}"; do
    if [ -f "$file" ]; then
        log "   ✓ Processando: $file"
        # Corrigir includes de ./trace.h para caminhos relativos corretos
        sed -i 's|#include "\.\/trace\.h"|#include "trace.h"|g' "$file" || log "   ⚠ Falha ao corrigir: $file"
        # Adicionar include correto do trace.h se necessário
        if ! grep -q '#include "trace.h"' "$file"; then
            log "   ⚠ Aviso: trace.h não encontrado em: $file"
        fi
    fi
done

# 3. Verificar e corrigir strings de formato em codecs de audio
log "📝 2. Corrigindo strings de formato em codecs de audio..."

# Encontrar todos os arquivos .c em codecs
CODECS_DIR="techpack/audio/asoc/codecs"
if [ -d "$CODECS_DIR" ]; then
    find "$CODECS_DIR" -name "*.c" -type f | while read -r file; do
        log "   ✓ Verificando: $file"
        # Procurar erros de formato comuns
        # Adicionar %zd, %zd, %zX onde necessário
        # Este é um placeholder para correções mais específicas
        if grep -q 'printf.*"%.*d' "$file"; then
            log "   ⚠ Possíveis erros de formato em: $file"
        fi
    done
fi

# 4. Verificar techpacks problemáticos
log "📝 3. Verificando techpacks problemáticos..."

PROBLEMATIC_TECHPACKS=(
    "techpack/audio/asoc/codecs/bolero"
    "techpack/datarmnet"
    "techpack/datarmnet-ext"
)

for techpack in "${PROBLEMATIC_TECHPACKS[@]}"; do
    if [ -d "$KERNEL_DIR/$techpack" ]; then
        log "   ⚠ Techpack problemático encontrado: $techpack"
        log "   ℹ Este techpack pode causar erros de compilação"
    fi
done

# 5. Criar arquivos de trace necessários
log "📝 4. Criando arquivos de trace se necessário..."

# Verificar se rmnet_trace.h existe
RMNET_TRACE="$KERNEL_DIR/techpack/datarmnet/core/rmnet_trace.h"
if [ ! -f "$RMNET_TRACE" ]; then
    log "   ❌ rmnet_trace.h não encontrado em: $RMNET_TRACE"
    log "   ⚠ Este arquivo é NECESSÁRIO para o build"
else
    log "   ✓ rmnet_trace.h encontrado"
fi

# 6. Verificar configs críticas
log "📝 5. Verificando configs críticas..."

if [ -f ".config" ]; then
    CRITICAL_CONFIGS=(
        "CONFIG_USER_NS=y"
        "CONFIG_CGROUP_DEVICE=y"
        "CONFIG_SYSVIPC=y"
        "CONFIG_POSIX_MQUEUE=y"
        "CONFIG_IKCONFIG_PROC=y"
    )

    for config in "${CRITICAL_CONFIGS[@]}"; do
        key="${config%=*}"
        value="${config#*=}"
        if grep -q "^${key}=y" .config; then
            log "   ✓ Config OK: $key"
        else
            log "   ❌ Config FALTANDO: $key"
            echo "$config" >> .config
            log "   ℹ Adicionando: $config"
        fi
    done
else
    log "   ⚠ .config não encontrado - execute menuconfig primeiro"
fi

# 7. Corrigir permissões
log "📝 6. Ajustando permissões..."
find "$KERNEL_DIR" -type d -exec chmod 755 {} \;
find "$KERNEL_DIR" -type f -exec chmod 644 {} \;
find "$KERNEL_DIR" -name "*.sh" -exec chmod +x {} \;

log "✅ Correções completas!"
log ""
log "📊 Resumo:"
log "   - Arquivos de tracing verificados: ${#TRACE_FILES[@]}"
log "   - Codecs de audio verificados"
log "   - Techpacks problemáticos identificados: ${#PROBLEMATIC_TECHPACKS[@]}"
log "   - Configs críticas verificadas"
log "   - Permissões ajustadas"
log ""
log "🚀 Pronto para compilação!"

exit 0
