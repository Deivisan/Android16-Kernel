#!/bin/bash
# ✅ validate-build.sh - Valida ambiente de build antes de compilar
# DevSan AGI - Verificações de pré-build

set -e

KERNEL_DIR="${KERNEL_DIR:-/kernel}"
OUTPUT_DIR="${OUTPUT_DIR:-/output}"
LOG_FILE="${LOG_FILE:-/logs/validate-build.log}"

echo "✅ DevSan Build Validator - Moonstone"
echo "📁 Kernel: $KERNEL_DIR"
echo "📤 Output: $OUTPUT_DIR"
echo "📋 Log: $LOG_FILE"
echo ""

# Criar diretórios
mkdir -p "$(dirname "$LOG_FILE")" "$OUTPUT_DIR"

# Função de log
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

ERRORS=0
WARNINGS=0

log "🔍 Iniciando validações..."

# 1. Verificar kernel source
log "1️⃣ Verificando kernel source..."
if [ ! -d "$KERNEL_DIR" ]; then
    log "   ❌ ERRO: Kernel source não encontrado: $KERNEL_DIR"
    ((ERRORS++))
else
    log "   ✓ Kernel source OK"
    
    # Verificar arquivos críticos
    if [ ! -f "$KERNEL_DIR/Makefile" ]; then
        log "   ❌ ERRO: Makefile não encontrado"
        ((ERRORS++))
    else
        log "   ✓ Makefile OK"
    fi
    
    if [ ! -f "$KERNEL_DIR/.config" ]; then
        log "   ⚠ AVISO: .config não encontrado"
        ((WARNINGS++))
    else
        log "   ✓ .config OK"
    fi
fi

# 2. Verificar toolchain
log "2️⃣ Verificando toolchain..."
if command -v clang &> /dev/null; then
    CLANG_VERSION=$(clang --version | head -1)
    log "   ✓ Clang encontrado: $CLANG_VERSION"
else
    log "   ❌ ERRO: Clang não encontrado"
    ((ERRORS++))
fi

# 3. Verificar espaço em disco
log "3️⃣ Verificando espaço em disco..."
SPACE_AVAILABLE=$(df -BG "$OUTPUT_DIR" | tail -1 | awk '{print $4}')
if [ "$SPACE_AVAILABLE" -lt 50 ]; then
    log "   ❌ ERRO: Espaço insuficiente (${SPACE_AVAILABLE}GB < 50GB)"
    ((ERRORS++))
else
    log "   ✓ Espaço OK (${SPACE_AVAILABLE}GB disponíveis)"
fi

# 4. Verificar RAM disponível
log "4️⃣ Verificando RAM..."
RAM_TOTAL=$(free -g | awk '/^Mem:/ {print $2}')
if [ "$RAM_TOTAL" -lt 8 ]; then
    log "   ❌ ERRO: RAM insuficiente (${RAM_TOTAL}GB < 8GB)"
    ((ERRORS++))
else
    log "   ✓ RAM OK (${RAM_TOTAL}GB)"
fi

# 5. Verificar configs críticas
log "5️⃣ Verificando configs críticas..."
if [ -f "$KERNEL_DIR/.config" ]; then
    CRITICAL=(
        "CONFIG_USER_NS"
        "CONFIG_CGROUP_DEVICE"
        "CONFIG_SYSVIPC"
        "CONFIG_POSIX_MQUEUE"
    )
    
    for config in "${CRITICAL[@]}"; do
        if grep -q "^${config}=y" "$KERNEL_DIR/.config"; then
            log "   ✓ $config = y"
        else
            log "   ❌ $config = FALTANDO"
            ((ERRORS++))
        fi
    done
else
    log "   ⚠ AVISO: .config não encontrado"
    ((WARNINGS++))
fi

# 6. Verificar ccache
log "6️⃣ Verificando ccache..."
if command -v ccache &> /dev/null; then
    CCACHE_DIR=$(ccache -s | grep "cache directory" | awk '{print $3}')
    CCACHE_SIZE=$(ccache -s | grep "cache size" | awk '{print $3" "$4}')
    log "   ✓ ccache OK: $CCACHE_SIZE em $CCACHE_DIR"
else
    log "   ⚠ AVISO: ccache não encontrado (opcional)"
    ((WARNINGS++))
fi

# 7. Verificar NDK
log "7️⃣ Verificando NDK..."
NDK_PATH="/opt/android-ndk-r23b"
if [ -d "$NDK_PATH" ]; then
    CLANG_PATH="$NDK_PATH/toolchains/llvm/prebuilt/linux-x86_64/bin/clang"
    if [ -f "$CLANG_PATH" ]; then
        CLANG_VER=$("$CLANG_PATH" --version | head -1)
        log "   ✓ NDK r23b OK: $CLANG_VER"
    else
        log "   ❌ ERRO: Clang não encontrado no NDK"
        ((ERRORS++))
    fi
else
    log "   ⚠ AVISO: NDK não encontrado (usando Clang do sistema)"
    ((WARNINGS++))
fi

# Relatório final
log ""
log "📊 Resultado da Validação:"
log "   Erros: $ERRORS"
log "   Avisos: $WARNINGS"
log ""

if [ $ERRORS -eq 0 ]; then
    log "✅ VALIDAÇÃO APROVADA - Pronto para compilar!"
    exit 0
else
    log "❌ VALIDAÇÃO FALHOU - Corrija os erros antes de compilar!"
    exit 1
fi
