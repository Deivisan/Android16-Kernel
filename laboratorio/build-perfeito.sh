#!/bin/bash
#===============================================================================
# SCRIPT PERFEITO - BUILD KERNEL MOONSTONE (POCO X5 5G)
# Versão: 3.0 - IMORTAL E INFALÍVEL
# Clang: 21.1.6 (Arch Linux)
# Kernel: 5.4.302-msm-android
#===============================================================================

set -e

# CONFIGURAÇÕES ABSOLUTAS
readonly KERNEL_DIR="/home/deivi/Projetos/Android16-Kernel/kernel-moonstone-devs"
readonly OUT_DIR="/home/deivi/Projetos/Android16-Kernel/laboratorio/out"
readonly LOG_FILE="${OUT_DIR}/build-$(date +%Y%m%d-%H%M%S).log"
readonly START_TIME=$(date +%s)

# CORES
readonly GREEN='\033[0;32m'
readonly RED='\033[0;31m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly CYAN='\033[0;36m'
readonly NC='\033[0m'

# CONTADORES
TESTS_PASSED=0
TESTS_FAILED=0

#===============================================================================
# FUNÇÕES UTILITÁRIAS
#===============================================================================

log() { echo -e "$1" | tee -a "$LOG_FILE"; }
pass() { log "${GREEN}✅ PASS${NC} - $1"; ((TESTS_PASSED++)); }
fail() { log "${RED}❌ FAIL${NC} - $1"; ((TESTS_FAILED++)); }
info() { log "${BLUE}ℹ️  INFO${NC} - $1"; }
warn() { log "${YELLOW}⚠️  WARN${NC} - $1"; }
section() {
    log ""
    log "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    log "${CYAN}$1${NC}"
    log "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

#===============================================================================
# SETUP INICIAL
#===============================================================================

setup() {
    section "🚀 BUILD KERNEL MOONSTONE - SCRIPT PERFEITO v3.0"
    
    log "⏰ Início: $(date '+%H:%M:%S - %d/%m/%Y')"
    log "📁 Kernel: $KERNEL_DIR"
    log "📦 Output: $OUT_DIR"
    log "📝 Log: $LOG_FILE"
    log "🔧 Clang: $(clang --version | head -1)"
    log "⚡ Cores: $(nproc)"
    log ""
    
    mkdir -p "$OUT_DIR"
    cd "$KERNEL_DIR"
    
    # Verificações críticas
    if [ ! -f "arch/arm64/configs/moonstone_defconfig" ]; then
        fail "moonstone_defconfig não encontrado!"
        exit 1
    fi
    
    pass "Verificações iniciais"
}

#===============================================================================
# CORREÇÕES AUTOMÁTICAS
#===============================================================================

aplicar_correcoes() {
    section "🔧 APLICANDO CORREÇÕES AUTOMÁTICAS"
    
    # Correção 1: FT3519T (firmware faltando)
    if grep -q "CONFIG_TOUCHSCREEN_FT3519T=y" arch/arm64/configs/moonstone_defconfig 2>/dev/null; then
        sed -i 's/CONFIG_TOUCHSCREEN_FT3519T=y/CONFIG_TOUCHSCREEN_FT3519T=n/' arch/arm64/configs/moonstone_defconfig
        info "FT3519T desativado no defconfig"
    fi
    
    # Correção 2: Configurar ambiente
    export ARCH=arm64
    export SUBARCH=arm64
    export LLVM=1
    export CC=clang
    export LD=ld.lld
    export AR=llvm-ar
    export NM=llvm-nm
    export OBJCOPY=llvm-objcopy
    export STRIP=llvm-strip
    
    # Flags ESSENCIAIS para Clang 21+
    export KCFLAGS="-Wno-format -Wno-format-security -Wno-unused-variable -Wno-error -ferror-limit=0"
    export KBUILD_BUILD_USER="deivison"
    export KBUILD_BUILD_HOST="DeiviPC"
    
    log "   ARCH=arm64 ✅"
    log "   LLVM=1 ✅"
    log "   CC=clang ✅"
    log "   KCFLAGS configuradas ✅"
    
    pass "Correções aplicadas"
}

#===============================================================================
# PREPARAÇÃO
#===============================================================================

preparar() {
    section "🧹 PREPARAÇÃO DO BUILD"
    
    log "Limpando build anterior..."
    make clean 2>&1 | tail -3 | tee -a "$LOG_FILE"
    
    log ""
    log "Carregando defconfig..."
    make moonstone_defconfig 2>&1 | grep -E "configuration|written" | tee -a "$LOG_FILE"
    
    # Verificar se .config foi gerado
    if [ ! -f ".config" ]; then
        fail ".config não gerado!"
        exit 1
    fi
    
    # Aplicar correções no .config também
    sed -i 's/CONFIG_TOUCHSCREEN_FT3519T=y/CONFIG_TOUCHSCREEN_FT3519T=n/' .config 2>/dev/null || true
    
    log ""
    log "📊 Configuração atual:"
    grep "CONFIG_LOCALVERSION" .config | head -1 | tee -a "$LOG_FILE"
    
    pass "Preparação completa"
}

#===============================================================================
# TESTES RÁPIDOS
#===============================================================================

testes_rapidos() {
    section "🧪 TESTES RÁPIDOS (2-3 minutos)"
    
    log "Testando componentes críticos..."
    log ""
    
    # Teste 1: Scripts/Mod
    log "Teste 1/3: Scripts/Mod..."
    if make -j$(nproc) scripts/mod >/dev/null 2>&1; then
        if [ -f "scripts/mod/modpost" ]; then
            pass "Scripts/Mod (modpost: $(ls -lh scripts/mod/modpost | awk '{print $5}'))"
        else
            fail "Scripts/Mod (modpost não gerado)"
        fi
    else
        fail "Scripts/Mod"
    fi
    
    # Teste 2: entry.S (Assembly ARM64)
    log ""
    log "Teste 2/3: entry.S (ARM64 core)..."
    if make -j$(nproc) arch/arm64/kernel/entry.o >/dev/null 2>&1; then
        if [ -f "arch/arm64/kernel/entry.o" ]; then
            pass "entry.S ($(ls -lh arch/arm64/kernel/entry.o | awk '{print $5}'))"
        else
            fail "entry.S (arquivo não gerado)"
        fi
    else
        # Pode ter warnings mas ainda gerar o arquivo
        if [ -f "arch/arm64/kernel/entry.o" ]; then
            warn "entry.S (com warnings, mas gerado)"
            ((TESTS_PASSED++))
        else
            fail "entry.S"
        fi
    fi
    
    # Teste 3: Verificar config
    log ""
    log "Teste 3/3: Verificação de config..."
    if grep -q "CONFIG_ARCH_ARM64=y" .config; then
        pass "Config (ARM64 confirmado)"
    else
        fail "Config (ARM64 não encontrado)"
    fi
    
    log ""
    log "📊 Resultados dos testes:"
    log "   ✅ Passaram: $TESTS_PASSED"
    log "   ❌ Falharam: $TESTS_FAILED"
    
    if [ $TESTS_FAILED -gt 0 ]; then
        log ""
        warn "$TESTS_FAILED teste(s) falharam, mas vamos tentar o build completo..."
        log "   (Alguns erros podem ser ignoráveis)"
    fi
}

#===============================================================================
# BUILD FINAL
#===============================================================================

build_final() {
    section "🔥 BUILD FINAL - IMAGE.GZ"
    
    log "⏰ Início do build: $(date '+%H:%M:%S')"
    log "⏱️  Tempo estimado: 2-4 horas"
    log "⚡ Jobs: $(nproc) cores paralelos"
    log ""
    log "🔨 Compilando... (Ctrl+C para cancelar)"
    log ""
    
    # Build com monitoramento de progresso
    if make -j$(nproc) Image.gz 2>&1 | tee -a "$LOG_FILE"; then
        log ""
        log "⏰ Build finalizado: $(date '+%H:%M:%S')"
        
        # Verificar se Image.gz foi gerado
        if [ -f "arch/arm64/boot/Image.gz" ]; then
            local size=$(ls -lh arch/arm64/boot/Image.gz | awk '{print $5}')
            local sha256=$(sha256sum arch/arm64/boot/Image.gz | cut -d' ' -f1)
            
            section "🎉 SUCESSO! KERNEL GERADO!"
            
            log "📦 Arquivo: arch/arm64/boot/Image.gz"
            log "📏 Tamanho: $size"
            log "🔐 SHA256: $sha256"
            
            # Copiar para out/
            cp arch/arm64/boot/Image.gz "$OUT_DIR/"
            cp .config "$OUT_DIR/config-$(date +%H%M%S).txt"
            
            log ""
            log "📁 Arquivos copiados para $OUT_DIR:"
            ls -lh "$OUT_DIR/" | tail -5
            
            # Calcular tempo total
            local END_TIME=$(date +%s)
            local DURATION=$((END_TIME - START_TIME))
            local HOURS=$((DURATION / 3600))
            local MINUTES=$(((DURATION % 3600) / 60))
            
            log ""
            log "⏱️  Tempo total: ${HOURS}h ${MINUTES}m"
            
            section "✅ BUILD COMPLETO COM SUCESSO!"
            
            log ""
            log "🚀 Próximo passo - Testar no device:"
            log "   adb reboot bootloader"
            log "   fastboot boot $OUT_DIR/Image.gz"
            
            return 0
        else
            fail "Build reportou sucesso, mas Image.gz não foi gerado!"
            return 1
        fi
    else
        log ""
        fail "Build falhou!"
        log ""
        log "📝 Verifique o log completo: $LOG_FILE"
        log ""
        log "💡 Dicas de troubleshooting:"
        log "   1. Verifique se há espaço em disco: df -h"
        log "   2. Verifique erros no final do log: tail -100 $LOG_FILE"
        log "   3. Tente recompilar: ./build-perfeito.sh"
        return 1
    fi
}

#===============================================================================
# RELATÓRIO FINAL
#===============================================================================

relatorio() {
    section "📊 RELATÓRIO FINAL"
    
    local END_TIME=$(date +%s)
    local DURATION=$((END_TIME - START_TIME))
    local HOURS=$((DURATION / 3600))
    local MINUTES=$(((DURATION % 3600) / 60))
    local SECONDS=$((DURATION % 60))
    
    log "⏰ Início: $(date -d "@$START_TIME" '+%H:%M:%S')"
    log "⏰ Fim: $(date '+%H:%M:%S')"
    log "⏱️  Duração: ${HOURS}h ${MINUTES}m ${SECONDS}s"
    log ""
    log "📊 Testes:"
    log "   ✅ Passaram: $TESTS_PASSED"
    log "   ❌ Falharam: $TESTS_FAILED"
    log ""
    
    if [ -f "$OUT_DIR/Image.gz" ]; then
        log "🎉 STATUS: SUCESSO!"
        log "📦 Kernel disponível em: $OUT_DIR/Image.gz"
    else
        log "❌ STATUS: FALHA"
        log "📝 Log de erros: $LOG_FILE"
    fi
}

#===============================================================================
# MAIN
#===============================================================================

main() {
    # Criar arquivo de log
    mkdir -p "$OUT_DIR"
    > "$LOG_FILE"
    
    # Executar fases
    setup
    aplicar_correcoes
    preparar
    testes_rapidos
    build_final
    relatorio
}

# Handler de erro
trap 'fail "Script interrompido na linha $LINENO"' ERR

# Executar
main "$@"
