#!/bin/bash
# 🚀 build-moonstone-docker.sh - Script Principal de Build com Docker
# DevSan AGI - Kernel Android16 (Moonstone) Build System
# Target: Snapdragon 695 (moonstone/rose) - MSM 5.4
# Toolchain: Clang r416183b (Android NDK r23b)

set -e  # Parar em qualquer erro
set -o pipefail

# Cores ANSI
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Diretírios
KERNEL_SOURCE="/home/deivi/Projetos/Android16-Kernel/kernel-moonstone-devs"
LAB_DIR="/home/deivi/Projetos/Android16-Kernel/laboratorio"
OUTPUT_DIR="$LAB_DIR/out"
CACHE_DIR="$HOME/.ccache"
LOGS_DIR="$LAB_DIR/logs"
SCRIPTS_DIR="$LAB_DIR/scripts"

# Logs
BUILD_LOG="$LOGS_DIR/build-$(date +%Y%m%d-%H%M%S).log"
SUMMARY_LOG="$LOGS_DIR/summary-$(date +%Y%m%d-%H%M%S).txt"

# Variáveis de build
JOBS=${JOBS:-$(nproc)}  # Usar todos os CPUs por padrão
BUILD_TYPE=${BUILD_TYPE:-qgki}
ARCH=arm64
SUBARCH=arm64

# Banner
banner() {
    echo -e "${CYAN}"
    echo "╔══════════════════════════════════════════════════════════╗"
    echo "║  🦞 DevSan AGI - Android Kernel Build System v1.0      ║"
    echo "║  Target: POCO X5 5G (moonstone) - Snapdragon 695      ║"
    echo "║  Kernel: MSM 5.4 - Android 11                        ║"
    echo "║  Toolchain: Clang r416183b (Android NDK r23b)        ║"
    echo "╚══════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

# Função de log
log() {
    echo -e "${CYAN}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$BUILD_LOG"
}

# Função de sucesso
success() {
    echo -e "${GREEN}✅ $1${NC}"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ✅ $1" | tee -a "$BUILD_LOG"
}

# Função de aviso
warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ⚠ $1" | tee -a "$BUILD_LOG"
}

# Função de erro
error() {
    echo -e "${RED}❌ $1${NC}"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ❌ $1" | tee -a "$BUILD_LOG"
}

# Criar diretórios necessários
mkdir_dirs() {
    log "📁 Criando estrutura de diretórios..."
    mkdir -p "$OUTPUT_DIR" "$LOGS_DIR" "$CACHE_DIR" "$SCRIPTS_DIR"
    success "Estrutura de diretórios criada"
}

# Iniciar Docker
start_docker() {
    log "🐳 Iniciando ambiente Docker..."
    
    # Verificar se Docker está rodando
    if ! docker info &> /dev/null; then
        error "Docker não está rodando!"
        exit 1
    fi
    
    success "Docker pronto"
}

# Validar build
validate_build() {
    log "✅ Validando ambiente de build..."
    
    if [ ! -x "$SCRIPTS_DIR/validate-build.sh" ]; then
        error "Script de validação não encontrado: $SCRIPTS_DIR/validate-build.sh"
        exit 1
    fi
    
    # Executar validação dentro do Docker
    docker-compose -f "$LAB_DIR/docker-compose.yml" exec -T kernel-build \
        bash -c "KERNEL_DIR=/kernel OUTPUT_DIR=/output /scripts/validate-build.sh"
    
    local exit_code=$?
    
    if [ $exit_code -eq 0 ]; then
        success "Validação aprovada!"
    else
        error "Validação falhou! Corrija os erros antes de continuar."
        exit 1
    fi
}

# Aplicar correções
apply_fixes() {
    log "🔧 Aplicando correções automáticas..."
    
    if [ ! -x "$SCRIPTS_DIR/apply-fixes.sh" ]; then
        error "Script de correções não encontrado: $SCRIPTS_DIR/apply-fixes.sh"
        exit 1
    fi
    
    # Executar correções dentro do Docker
    docker-compose -f "$LAB_DIR/docker-compose.yml" exec -T kernel-build \
        bash -c "KERNEL_DIR=/kernel /scripts/apply-fixes.sh"
    
    success "Correções aplicadas!"
}

# Compilar kernel
compile_kernel() {
    log "⚡ Iniciando compilação do kernel..."
    log "📊 Configurações:"
    log "   Jobs: $JOBS"
    log "   Arch: $ARCH"
    log "   Subarch: $SUBARCH"
    log "   Build type: $BUILD_TYPE"
    
    local start_time=$(date +%s)
    
    # Executar compilação dentro do Docker
    docker-compose -f "$LAB_DIR/docker-compose.yml" exec -T kernel-build bash -c "
        set -e
        
        echo '🔧 Configurando ambiente de build...'
        export ARCH=$ARCH
        export SUBARCH=$SUBARCH
        export CROSS_COMPILE=aarch64-linux-gnu-
        export CC=clang
        export CLANG_TRIPLE=aarch64-linux-gnu-
        export KCFLAGS='-O2 -pipe'
        export KAFLAGS='-O2 -pipe'
        
        cd /kernel
        
        # Limpar build anterior se solicitado
        if [ '$(echo "${CLEAN:-no}")' = 'yes' ]; then
            echo '🧹 Limpando build anterior...'
            make clean && make mrproper
        fi
        
        # Carregar defconfig
        echo '📝 Carregando moonstone_defconfig...'
        make ARCH=$ARCH moonstone_defconfig
        
        # Verificar configs críticas
        echo '✅ Verificando configs críticas...'
        for config in USER_NS CGROUP_DEVICE SYSVIPC POSIX_MQUEUE IKCONFIG_PROC; do
            value=\$(grep "CONFIG_\$config[= ]" .config 2>/dev/null | cut -d= -f2)
            if [ \"\$value\" = 'y' ]; then
                echo \"   ✓ CONFIG_\$config = OK\"
            else
                echo \"   ❌ CONFIG_\$config = FALTANDO\"
                exit 1
            fi
        done
        
        # Compilar
        echo '⚡ Compilando com $JOBS jobs...'
        time make -j$JOBS Image.gz
        
        # Verificar resultado
        if [ -f arch/arm64/boot/Image.gz ]; then
            SIZE=\$(stat -c%s arch/arm64/boot/Image.gz)
            SIZE_MB=\$((\$SIZE / 1024 / 1024))
            echo \"✅ Build concluído! Tamanho: \${SIZE_MB}MB\"
            cp arch/arm64/boot/Image.gz /output/
            
            # Copiar artefatos adicionais
            [ -f vmlinux ] && cp vmlinux /output/
            [ -f System.map ] && cp System.map /output/
            [ -d arch/arm64/boot/dts ] && cp -r arch/arm64/boot/dts /output/
            
            echo '📦 Artefatos copiados para /output'
        else
            echo '❌ Build falhou - Image.gz não encontrado!'
            exit 1
        fi
    "
    
    local exit_code=$?
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    if [ $exit_code -eq 0 ]; then
        success "Compilação concluída com sucesso!"
        success "Tempo: $((duration / 60)) minutos e $((duration % 60)) segundos"
    else
        error "Compilação falhou com código: $exit_code"
        exit 1
    fi
}

# Verificar resultado
verify_result() {
    log "✅ Verificando resultado do build..."
    
    if [ -f "$OUTPUT_DIR/Image.gz" ]; then
        local size=$(stat -c%s "$OUTPUT_DIR/Image.gz")
        local size_mb=$((size / 1024 / 1024))
        
        log "📦 Artefatos gerados:"
        log "   ✓ Image.gz: ${size_mb}MB"
        
        if [ -f "$OUTPUT_DIR/vmlinux" ]; then
            log "   ✓ vmlinux: $(stat -c%s "$OUTPUT_DIR/vmlinux") bytes"
        fi
        
        if [ -f "$OUTPUT_DIR/System.map" ]; then
            log "   ✓ System.map: $(stat -c%s "$OUTPUT_DIR/System.map") bytes"
        fi
        
        success "Build validado com sucesso!"
        
        # Calcular SHA256
        log "🔒 Calculando SHA256..."
        local sha256=$(sha256sum "$OUTPUT_DIR/Image.gz" | awk '{print $1}')
        echo "   SHA256: $sha256" | tee -a "$BUILD_LOG"
    else
        error "Image.gz não encontrado em: $OUTPUT_DIR"
        exit 1
    fi
}

# Gerar relatório
generate_report() {
    log "📝 Gerando relatório final..."
    
    cat > "$SUMMARY_LOG" << EOF
╔══════════════════════════════════════════════════════════╗
║  🦞 DevSan AGI - Build Report - Moonstone Kernel       ║
╚══════════════════════════════════════════════════════════╝

📅 Data: $(date '+%Y-%m-%d %H:%M:%S')

🎯 Target:
   Device: POCO X5 5G (moonstone/rose)
   SoC: Snapdragon 695 (SM6375)
   Arch: ARM64 (armv8.2-a)
   Kernel: MSM 5.4 + Android Patches
   Toolchain: Clang r416183b (Android 12.0.8)

🔧 Build Configurações:
   Jobs: $JOBS
   Arch: $ARCH
   Subarch: $SUBARCH
   Build Type: $BUILD_TYPE

📊 Artefatos:
EOF
    
    if [ -f "$OUTPUT_DIR/Image.gz" ]; then
        local size=$(stat -c%s "$OUTPUT_DIR/Image.gz")
        local size_mb=$((size / 1024 / 1024))
        echo "   ✓ Image.gz: ${size_mb}MB ($size bytes)" >> "$SUMMARY_LOG"
    else
        echo "   ❌ Image.gz: FALTANDO" >> "$SUMMARY_LOG"
    fi
    
    if [ -f "$OUTPUT_DIR/vmlinux" ]; then
        echo "   ✓ vmlinux: $(stat -c%s "$OUTPUT_DIR/vmlinux") bytes" >> "$SUMMARY_LOG"
    fi
    
    if [ -f "$OUTPUT_DIR/System.map" ]; then
        echo "   ✓ System.map: $(stat -c%s "$OUTPUT_DIR/System.map") bytes" >> "$SUMMARY_LOG"
    fi
    
    cat >> "$SUMMARY_LOG" << EOF

📋 Logs:
   Build Log: $BUILD_LOG
   Summary Log: $SUMMARY_LOG

✅ Status: BUILD COMPLETO!

📦 Localização dos artefatos:
   $OUTPUT_DIR/

🚀 Próximos passos:
   1. Conectar device em fastboot
   2. Testar: fastboot boot $OUTPUT_DIR/Image.gz
   3. Se funcionar: flashar em slot B
   4. Reboot e verificar dmesg

╚══════════════════════════════════════════════════════════╝
EOF
    
    success "Relatório gerado: $SUMMARY_LOG"
    cat "$SUMMARY_LOG"
}

# Função principal
main() {
    banner
    
    log "🚀 Iniciando processo de build..."
    log "📋 Log de build: $BUILD_LOG"
    
    # Executar fases
    mkdir_dirs
    start_docker
    
    # Perguntar se quer limpar
    read -p "$(echo -e ${YELLOW}"Deseja limpar builds anteriores? [y/N]: "${NC})" clean_confirm
    CLEAN=${clean_confirm:-no}
    
    validate_build
    apply_fixes
    compile_kernel
    verify_result
    generate_report
    
    log ""
    success "🎉 BUILD COMPLETADO COM SUCESSO! 🎉"
    log ""
    log "📦 Kernel compilado: $OUTPUT_DIR/Image.gz"
    log "📝 Log completo: $BUILD_LOG"
    log "📋 Relatório: $SUMMARY_LOG"
    log ""
    log "🚀 Pronto para teste no device!"
    log ""
    log "💡 Para testar:"
    log "   adb reboot bootloader"
    log "   fastboot boot $OUTPUT_DIR/Image.gz"
    log ""
}

# Executar
main "$@"
