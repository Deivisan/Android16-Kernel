#!/bin/bash
#===============================================================================
# BATERIA DE TESTES INCREMENTAIS - KERNEL MOONSTONE
# Clang 20.0 / Google Clang r416183b
#===============================================================================

set -e

# CONFIGURAÇÕES
KERNEL_DIR="/home/deivi/Projetos/Android16-Kernel/kernel-moonstone-devs"
TEST_LOG="/home/deivi/Projetos/Android16-Kernel/laboratorio/testes-incrementais.log"
PASSED_TESTS=0
FAILED_TESTS=0

# CORES
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() { echo -e "$1" | tee -a "$TEST_LOG"; }
pass() { log "${GREEN}✅ PASS${NC} - $1"; ((PASSED_TESTS++)); }
fail() { log "${RED}❌ FAIL${NC} - $1"; ((FAILED_TESTS++)); }
info() { log "${BLUE}ℹ️  INFO${NC} - $1"; }
warn() { log "${YELLOW}⚠️  WARN${NC} - $1"; }

#===============================================================================
# SETUP INICIAL
#===============================================================================
setup() {
    log ""
    log "╔══════════════════════════════════════════════════════════════╗"
    log "║     BATERIA DE TESTES INCREMENTAIS - KERNEL MOONSTONE        ║"
    log "║     Clang 20.0 / Google Clang r416183b                       ║"
    log "╚══════════════════════════════════════════════════════════════╝"
    log ""
    log "⏰ Início: $(date)"
    log "📁 Kernel: $KERNEL_DIR"
    log ""
    
    cd "$KERNEL_DIR"
    
    # Verificar defconfig
    if [ ! -f "arch/arm64/configs/moonstone_defconfig" ]; then
        fail "moonstone_defconfig não encontrado"
        exit 1
    fi
    
    pass "Defconfig moonstone encontrado"
    
    # Limpar e configurar
    info "Limpando build anterior..."
    make clean 2>/dev/null || true
    
    info "Carregando defconfig..."
    make moonstone_defconfig >/dev/null 2>&1
    
    if [ ! -f ".config" ]; then
        fail "Falha ao carregar defconfig"
        exit 1
    fi
    
    pass "Defconfig carregado com sucesso"
    log ""
}

#===============================================================================
# TESTE 1: Scripts/Mod (Módulos Básicos)
#===============================================================================
teste_1_scripts_mod() {
    log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    log "TESTE 1: Scripts/Mod (Módulos Básicos)"
    log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    log "Descrição: Compila scripts básicos necessários para o build"
    log "Tempo estimado: 10-30 segundos"
    log ""
    
    cd "$KERNEL_DIR"
    
    if make -j$(nproc) scripts/mod 2>&1 | tee -a "$TEST_LOG" | tail -20; then
        if [ -f "scripts/mod/modpost" ]; then
            pass "Scripts/Mod compilado com sucesso"
            return 0
        else
            fail "modpost não foi gerado"
            return 1
        fi
    else
        fail "Falha ao compilar scripts/mod"
        return 1
    fi
}

#===============================================================================
# TESTE 2: Kernel Headers (Headers Essenciais)
#===============================================================================
teste_2_kernel_headers() {
    log ""
    log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    log "TESTE 2: Kernel Headers (Headers Essenciais)"
    log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    log "Descrição: Gera headers do kernel (asm-offsets, etc)"
    log "Tempo estimado: 30-60 segundos"
    log ""
    
    cd "$KERNEL_DIR"
    
    if make -j$(nproc) arch/arm64/kernel/asm-offsets.s 2>&1 | tee -a "$TEST_LOG" | tail -20; then
        if [ -f "include/generated/asm-offsets.h" ]; then
            pass "Headers gerados com sucesso"
            return 0
        else
            fail "asm-offsets.h não foi gerado"
            return 1
        fi
    else
        fail "Falha ao gerar headers"
        return 1
    fi
}

#===============================================================================
# TESTE 3: Kernel/BPF (Subsistema BPF)
#===============================================================================
teste_3_kernel_bpf() {
    log ""
    log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    log "TESTE 3: Kernel/BPF (Subsistema BPF)"
    log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    log "Descrição: Compila subsistema BPF (Berkeley Packet Filter)"
    log "Importância: Essencial para Android moderno e networking"
    log "Tempo estimado: 2-5 minutos"
    log ""
    
    cd "$KERNEL_DIR"
    
    if make -j$(nproc) kernel/bpf 2>&1 | tee -a "$TEST_LOG" | tail -30; then
        if [ -f "kernel/bpf/built-in.a" ] || [ -f "kernel/bpf/built-in.o" ]; then
            pass "Kernel/BPF compilado com sucesso"
            return 0
        else
            fail "built-in.a não encontrado"
            return 1
        fi
    else
        fail "Falha ao compilar kernel/bpf"
        return 1
    fi
}

#===============================================================================
# TESTE 4: Arch/ARM64/MM (Memory Management)
#===============================================================================
teste_4_arch_arm64_mm() {
    log ""
    log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    log "TESTE 4: Arch/ARM64/MM (Memory Management)"
    log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    log "Descrição: Compila gerenciamento de memória ARM64"
    log "Importância: Core do kernel, essencial para boot"
    log "Tempo estimado: 3-7 minutos"
    log ""
    
    cd "$KERNEL_DIR"
    
    if make -j$(nproc) arch/arm64/mm 2>&1 | tee -a "$TEST_LOG" | tail -30; then
        if [ -f "arch/arm64/mm/built-in.a" ]; then
            pass "Arch/ARM64/MM compilado com sucesso"
            return 0
        else
            fail "built-in.a não encontrado em arch/arm64/mm"
            return 1
        fi
    else
        fail "Falha ao compilar arch/arm64/mm"
        return 1
    fi
}

#===============================================================================
# TESTE 5: Kernel/Sched/WALT (Scheduler Qualcomm)
#===============================================================================
teste_5_kernel_sched_walt() {
    log ""
    log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    log "TESTE 5: Kernel/Sched/WALT (Scheduler Qualcomm)"
    log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    log "Descrição: Compila WALT scheduler (Window Assisted Load Tracking)"
    log "Importância: Específico da Qualcomm, frequentemente problemático"
    log "Tempo estimado: 2-5 minutos"
    log ""
    
    cd "$KERNEL_DIR"
    
    if make -j$(nproc) kernel/sched/walt 2>&1 | tee -a "$TEST_LOG" | tail -30; then
        if [ -f "kernel/sched/walt/built-in.a" ]; then
            pass "Kernel/Sched/WALT compilado com sucesso"
            return 0
        else
            warn "built-in.a não encontrado, verificando objetos individuais..."
            if ls kernel/sched/walt/*.o 1>/dev/null 2>&1; then
                pass "Objetos WALT compilados com sucesso"
                return 0
            else
                fail "Nenhum objeto WALT encontrado"
                return 1
            fi
        fi
    else
        fail "Falha ao compilar kernel/sched/walt"
        return 1
    fi
}

#===============================================================================
# TESTE 6: Techpack/Audio/Codecs/Bolero
#===============================================================================
teste_6_techpack_audio_bolero() {
    log ""
    log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    log "TESTE 6: Techpack/Audio/Codecs/Bolero (Drivers Audio)"
    log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    log "Descrição: Compila drivers de áudio Qualcomm (Bolero)"
    log "Importância: Frequentemente tem erros de formato"
    log "Tempo estimado: 3-8 minutos"
    log ""
    
    cd "$KERNEL_DIR"
    
    if make -j$(nproc) techpack/audio/asoc/codecs/bolero 2>&1 | tee -a "$TEST_LOG" | tail -30; then
        if [ -f "techpack/audio/asoc/codecs/bolero/built-in.a" ]; then
            pass "Techpack/Audio/Bolero compilado com sucesso"
            return 0
        else
            fail "built-in.a não encontrado em bolero"
            return 1
        fi
    else
        fail "Falha ao compilar techpack/audio/bolero"
        return 1
    fi
}

#===============================================================================
# TESTE 7: Techpack/Camera (Câmera Qualcomm)
#===============================================================================
teste_7_techpack_camera() {
    log ""
    log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    log "TESTE 7: Techpack/Camera (Câmera Qualcomm)"
    log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    log "Descrição: Compila drivers de câmera Qualcomm"
    log "Importância: Complexo, muitos warnings de formato"
    log "Tempo estimado: 5-10 minutos"
    log ""
    
    cd "$KERNEL_DIR"
    
    if make -j$(nproc) techpack/camera/drivers 2>&1 | tee -a "$TEST_LOG" | tail -30; then
        if ls techpack/camera/drivers/*/built-in.a 1>/dev/null 2>&1; then
            pass "Techpack/Camera compilado com sucesso"
            return 0
        else
            fail "built-in.a não encontrado em camera drivers"
            return 1
        fi
    else
        fail "Falha ao compilar techpack/camera"
        return 1
    fi
}

#===============================================================================
# TESTE 8: Build Final - Image.gz
#===============================================================================
teste_8_build_final() {
    log ""
    log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    log "TESTE 8: BUILD FINAL - Image.gz"
    log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    log "Descrição: Compilação completa do kernel"
    log "Tempo estimado: 2-4 horas"
    log ""
    
    cd "$KERNEL_DIR"
    
    log "🚀 Iniciando build completo..."
    log "Isso pode levar várias horas. Pressione Ctrl+C para cancelar."
    log ""
    
    if make -j$(nproc) Image.gz 2>&1 | tee -a "$TEST_LOG"; then
        if [ -f "arch/arm64/boot/Image.gz" ]; then
            local size=$(ls -lh arch/arm64/boot/Image.gz | awk '{print $5}')
            log ""
            log "🎉 SUCESSO! Kernel gerado:"
            log "   Arquivo: arch/arm64/boot/Image.gz"
            log "   Tamanho: $size"
            log "   SHA256:  $(sha256sum arch/arm64/boot/Image.gz | cut -d' ' -f1)"
            pass "BUILD FINAL COMPLETO!"
            
            # Copiar para out
            cp arch/arm64/boot/Image.gz /home/deivi/Projetos/Android16-Kernel/laboratorio/out/ 2>/dev/null || true
            return 0
        else
            fail "Image.gz não foi gerado após build bem-sucedido"
            return 1
        fi
    else
        fail "Build final falhou"
        return 1
    fi
}

#===============================================================================
# RELATÓRIO FINAL
#===============================================================================
relatorio_final() {
    log ""
    log "╔══════════════════════════════════════════════════════════════╗"
    log "║                    RELATÓRIO FINAL                           ║"
    log "╚══════════════════════════════════════════════════════════════╝"
    log ""
    log "⏰ Fim: $(date)"
    log ""
    log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    log "RESULTADOS:"
    log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    log "✅ Testes Passados: $PASSED_TESTS"
    log "❌ Testes Falhos:   $FAILED_TESTS"
    log ""
    
    TOTAL_TESTS=$((PASSED_TESTS + FAILED_TESTS))
    if [ $TOTAL_TESTS -gt 0 ]; then
        PERCENTAGE=$((PASSED_TESTS * 100 / TOTAL_TESTS))
        log "📊 Taxa de Sucesso: $PERCENTAGE% ($PASSED_TESTS/$TOTAL_TESTS)"
    fi
    
    log ""
    log "📝 Log completo: $TEST_LOG"
    log ""
    
    if [ $FAILED_TESTS -eq 0 ]; then
        log "🎉 TODOS OS TESTES PASSARAM!"
        log ""
        log "Próximo passo:"
        log "   fastboot boot arch/arm64/boot/Image.gz"
        return 0
    else
        log "⚠️  ALGUNS TESTES FALHARAM"
        log "Verifique o log para detalhes: $TEST_LOG"
        return 1
    fi
}

#===============================================================================
# MAIN
#===============================================================================
main() {
    # Limpar log anterior
    > "$TEST_LOG"
    
    # Setup
    setup
    
    # Executar testes sequenciais
    teste_1_scripts_mod
    teste_2_kernel_headers
    teste_3_kernel_bpf
    teste_4_arch_arm64_mm
    teste_5_kernel_sched_walt
    teste_6_techpack_audio_bolero
    teste_7_techpack_camera
    
    # Build final
    read -p "Deseja executar o build final completo? (2-4 horas) [s/N]: " resposta
    if [[ "$resposta" =~ ^[Ss]$ ]]; then
        teste_8_build_final
    else
        info "Build final pulado pelo usuário"
    fi
    
    # Relatório
    relatorio_final
}

# Executar
main "$@"
