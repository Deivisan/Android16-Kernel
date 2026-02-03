#!/bin/bash
# =============================================================================
# DevSan AGI - Kernel 5.4.302 Build Script (Docker/LXC Support)
# =============================================================================
# Compila kernel 5.4.302 com suporte completo a Docker/LXC/Halium
# Device: POCO X5 5G (moonstone/rose)
# =============================================================================

set -e  # Exit on error

# =============================================================================
# CORES E FORMATAÇÃO
# =============================================================================
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# =============================================================================
# FUNÇÕES AUXILIARES
# =============================================================================
log_info() {
    echo -e "${CYAN}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[✓]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[⚠]${NC} $1"
}

log_error() {
    echo -e "${RED}[✗]${NC} $1"
}

print_banner() {
    echo -e "${BOLD}${CYAN}"
    cat << "EOF"
    ____             _____              ___   ____________
   / __ \___  _   __/ ___/____ _____   /   | / ____/  _/ /
  / / / / _ \| | / /\__ \/ __ `/ __ \ / /| |/ / __ / // / 
 / /_/ /  __/| |/ /___/ / /_/ / / / // ___ / /_/ // // /  
/_____/\___/ |___//____/\__,_/_/ /_//_/  |_\____/___/_/   
                                                           
    Kernel Builder Pro - Docker/LXC Edition
    v5.4.302 | POCO X5 5G (moonstone/rose)
EOF
    echo -e "${NC}"
}

# =============================================================================
# CONFIGURAÇÕES
# =============================================================================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
KERNEL_DIR="$PROJECT_ROOT/kernel-moonstone-devs"
BUILD_DIR="$SCRIPT_DIR"
OUT_DIR="$BUILD_DIR/out"
CONFIG_FILE="$PROJECT_ROOT/configs/docker-lxc.config"
NDK_PATH="${NDK_PATH:-$HOME/Downloads/android-ndk-r26d}"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
BUILD_LOG="$BUILD_DIR/build-5.4.302-docker-$TIMESTAMP.log"

# Build options
JOBS="${JOBS:-$(nproc)}"
APPLY_TRACING_FIX="${APPLY_TRACING_FIX:-false}"  # Tracing já aplicado no build base

# =============================================================================
# VALIDAÇÕES PRÉ-BUILD
# =============================================================================
validate_environment() {
    log_info "Validando ambiente de build..."
    
    # Verificar kernel source
    if [ ! -d "$KERNEL_DIR" ]; then
        log_error "Kernel source não encontrado: $KERNEL_DIR"
        exit 1
    fi
    log_success "Kernel source: $KERNEL_DIR"
    
    # Verificar NDK
    if [ ! -d "$NDK_PATH" ]; then
        log_error "NDK não encontrado: $NDK_PATH"
        log_info "Download: https://developer.android.com/ndk/downloads"
        exit 1
    fi
    log_success "NDK: $NDK_PATH"
    
    # Verificar configs Docker/LXC
    if [ ! -f "$CONFIG_FILE" ]; then
        log_error "Config file não encontrado: $CONFIG_FILE"
        exit 1
    fi
    log_success "Docker/LXC configs: $CONFIG_FILE"
    
    # Verificar comandos necessários
    for cmd in make bc bison flex; do
        if ! command -v $cmd &> /dev/null; then
            log_error "Comando '$cmd' não encontrado. Instale: sudo pacman -S $cmd"
            exit 1
        fi
    done
    log_success "Comandos necessários instalados"
    
    # Criar diretórios
    mkdir -p "$OUT_DIR"
    log_success "Output dir: $OUT_DIR"
}

# =============================================================================
# APLICAR TRACING FIXES
# =============================================================================
apply_tracing_fixes() {
    if [ "$APPLY_TRACING_FIX" = true ]; then
        log_info "Aplicando fixes de tracing..."
        
        if [ -f "$BUILD_DIR/apply-tracing-fixes.sh" ]; then
            cd "$KERNEL_DIR"
            bash "$BUILD_DIR/apply-tracing-fixes.sh"
            log_success "Tracing fixes aplicados"
        else
            log_warn "Script apply-tracing-fixes.sh não encontrado, pulando..."
        fi
    fi
}

# =============================================================================
# CONFIGURAR KERNEL
# =============================================================================
configure_kernel() {
    log_info "Configurando kernel..."
    
    cd "$KERNEL_DIR"
    
    # Carregar defconfig base
    log_info "Carregando moonstone_defconfig..."
    make ARCH=arm64 moonstone_defconfig
    
    # Adicionar configs Docker/LXC
    log_info "Adicionando configs Docker/LXC..."
    cat "$CONFIG_FILE" >> .config
    
    # Regenerar .config com olddefconfig (resolve dependências)
    log_info "Resolvendo dependências (olddefconfig)..."
    make ARCH=arm64 olddefconfig
    
    log_success "Kernel configurado com suporte Docker/LXC"
}

# =============================================================================
# VERIFICAR CONFIGS CRÍTICAS
# =============================================================================
verify_configs() {
    log_info "Verificando configs críticas..."
    
    cd "$KERNEL_DIR"
    
    local critical_configs=(
        "CONFIG_USER_NS"
        "CONFIG_PID_NS"
        "CONFIG_NET_NS"
        "CONFIG_CGROUP_DEVICE"
        "CONFIG_CGROUP_PIDS"
        "CONFIG_SYSVIPC"
        "CONFIG_POSIX_MQUEUE"
        "CONFIG_OVERLAY_FS"
        "CONFIG_SECURITY_APPARMOR"
        "CONFIG_MEMCG"
        "CONFIG_BRIDGE"
        "CONFIG_NETFILTER"
    )
    
    local missing=0
    
    for config in "${critical_configs[@]}"; do
        if grep -q "^${config}=y" .config; then
            log_success "$config habilitado"
        else
            log_warn "$config NÃO habilitado ou ausente"
            missing=$((missing + 1))
        fi
    done
    
    if [ $missing -gt 0 ]; then
        log_warn "$missing configs críticas faltando"
        log_info "Continuando build (pode não suportar Docker completamente)..."
    else
        log_success "Todas as configs críticas habilitadas!"
    fi
}

# =============================================================================
# COMPILAR KERNEL
# =============================================================================
compile_kernel() {
    log_info "Iniciando compilação do kernel..."
    log_info "Jobs: $JOBS | Log: $BUILD_LOG"
    
    cd "$KERNEL_DIR"
    
    # Configurar variáveis de ambiente
    export ARCH=arm64
    export SUBARCH=arm64
    export CLANG_TRIPLE=aarch64-linux-gnu-
    export CROSS_COMPILE=aarch64-linux-gnu-
    export CC="$NDK_PATH/toolchains/llvm/prebuilt/linux-x86_64/bin/clang"
    export LD="$NDK_PATH/toolchains/llvm/prebuilt/linux-x86_64/bin/ld.lld"
    export AR="$NDK_PATH/toolchains/llvm/prebuilt/linux-x86_64/bin/llvm-ar"
    export NM="$NDK_PATH/toolchains/llvm/prebuilt/linux-x86_64/bin/llvm-nm"
    export OBJCOPY="$NDK_PATH/toolchains/llvm/prebuilt/linux-x86_64/bin/llvm-objcopy"
    export OBJDUMP="$NDK_PATH/toolchains/llvm/prebuilt/linux-x86_64/bin/llvm-objdump"
    export READELF="$NDK_PATH/toolchains/llvm/prebuilt/linux-x86_64/bin/llvm-readelf"
    export STRIP="$NDK_PATH/toolchains/llvm/prebuilt/linux-x86_64/bin/llvm-strip"
    
    # Desabilitar warnings-as-errors (techpacks têm muitos warnings de formato)
    export KCFLAGS="-Wno-error"
    export KAFLAGS="-Wno-error"
    
    # Compilar
    log_info "Compilando com Clang 17.0.2 (NDK r26d)..."
    echo -e "${YELLOW}Isso pode levar 4-8 horas...${NC}"
    
    time make -j"$JOBS" Image.gz 2>&1 | tee "$BUILD_LOG"
    
    if [ ! -f "arch/arm64/boot/Image.gz" ]; then
        log_error "Build falhou! Kernel Image.gz não encontrado"
        log_error "Veja o log: $BUILD_LOG"
        exit 1
    fi
    
    log_success "Kernel compilado com sucesso!"
}

# =============================================================================
# CRIAR ARTEFATOS
# =============================================================================
create_artifacts() {
    log_info "Criando artefatos de build..."
    
    cd "$KERNEL_DIR"
    
    local kernel_size=$(stat -c%s arch/arm64/boot/Image.gz)
    local kernel_size_mb=$(echo "scale=1; $kernel_size / 1024 / 1024" | bc)
    
    log_success "Kernel Image.gz: ${kernel_size_mb}MB"
    
    # Copiar kernel para output
    local output_kernel="$OUT_DIR/Image-docker-$TIMESTAMP.gz"
    cp arch/arm64/boot/Image.gz "$output_kernel"
    log_success "Kernel copiado: $output_kernel"
    
    # Gerar SHA256
    cd "$OUT_DIR"
    sha256sum "$(basename $output_kernel)" > "$(basename $output_kernel).sha256"
    log_success "SHA256 gerado"
    
    # Criar AnyKernel3 ZIP
    log_info "Criando AnyKernel3 ZIP..."
    
    local ak3_dir="$PROJECT_ROOT/anykernel3-poco-x5"
    
    if [ -d "$ak3_dir" ]; then
        # Copiar kernel para AnyKernel3
        cp "$KERNEL_DIR/arch/arm64/boot/Image.gz" "$ak3_dir/Image.gz"
        
        # Criar ZIP
        cd "$ak3_dir"
        local zip_name="DevSan-AGI-Kernel-5.4.302-docker-moonstone-slotb.zip"
        zip -r9 "$OUT_DIR/$zip_name" . -x '*.git*' -x 'README.md' -x '.gitignore'
        
        # Limpar
        rm -f "$ak3_dir/Image.gz"
        
        log_success "AnyKernel3 ZIP: $zip_name"
    else
        log_warn "AnyKernel3 template não encontrado, pulando ZIP..."
    fi
}

# =============================================================================
# SALVAR .CONFIG
# =============================================================================
save_config() {
    log_info "Salvando .config final..."
    
    cd "$KERNEL_DIR"
    
    local config_output="$OUT_DIR/config-docker-$TIMESTAMP.txt"
    cp .config "$config_output"
    
    log_success "Config salvo: $config_output"
}

# =============================================================================
# RESUMO FINAL
# =============================================================================
print_summary() {
    echo ""
    echo -e "${BOLD}${GREEN}═══════════════════════════════════════════════════════${NC}"
    echo -e "${BOLD}${GREEN}   BUILD COMPLETO - KERNEL 5.4.302 + DOCKER/LXC${NC}"
    echo -e "${BOLD}${GREEN}═══════════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "${CYAN}Artefatos gerados:${NC}"
    echo ""
    ls -lh "$OUT_DIR"/*$TIMESTAMP* 2>/dev/null || true
    ls -lh "$OUT_DIR"/*docker*.zip 2>/dev/null || true
    echo ""
    echo -e "${CYAN}Build log:${NC} $BUILD_LOG"
    echo -e "${CYAN}Kernel source:${NC} $KERNEL_DIR/arch/arm64/boot/Image.gz"
    echo ""
    echo -e "${YELLOW}Próximos passos:${NC}"
    echo "  1. Testar temporário: fastboot boot Image.gz"
    echo "  2. Flash via ZIP (Recovery): DevSan-AGI-Kernel-5.4.302-docker-moonstone-slotb.zip"
    echo "  3. Validar configs: docker info (após boot no device)"
    echo ""
    echo -e "${BOLD}${GREEN}DevSan AGI - Kernel Build System${NC}"
    echo ""
}

# =============================================================================
# MAIN
# =============================================================================
main() {
    print_banner
    
    log_info "Iniciando build do kernel 5.4.302 com suporte Docker/LXC..."
    log_info "Timestamp: $TIMESTAMP"
    echo ""
    
    validate_environment
    apply_tracing_fixes
    configure_kernel
    verify_configs
    compile_kernel
    create_artifacts
    save_config
    print_summary
    
    log_success "Build finalizado com sucesso!"
}

# Executar
main "$@"
