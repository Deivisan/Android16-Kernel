#!/bin/bash
#===============================================================================
# SCRIPT DE BUILD BULLETPROOF - KERNEL MOONSTONE (POCO X5 5G)
# Kernel: 5.4.302-msm-android (QGKI)
# Device: POCO X5 5G (moonstone) - SM6375/Blair
# Author: DevSan AGI para Deivison Santana
# Versão: 1.0 - IMUNE A ERROS
#===============================================================================

set -euo pipefail  # Modo estrito: erro em falha, undefined var, pipe fail

#===============================================================================
# CONFIGURAÇÕES IMUTÁVEIS
#===============================================================================
readonly LAB_DIR="/home/deivi/Projetos/Android16-Kernel/laboratorio"
readonly KERNEL_SRC="/home/deivi/Projetos/Android16-Kernel/kernel-moonstone-devs"
readonly TOOLCHAIN_DIR="${LAB_DIR}/toolchain/google-clang"
readonly BUILDTOOLS_DIR="${LAB_DIR}/build-tools"
readonly OUT_DIR="${LAB_DIR}/out"
readonly LOG_FILE="${LAB_DIR}/build-$(date +%Y%m%d-%H%M%S).log"

# Toolchain correta (Google Clang r416183b = Android Clang 14.0.6)
readonly CLANG_VERSION="clang-r416183b"
readonly CLANG_URL="https://android.googlesource.com/platform/prebuilts/clang/host/linux-x86/+archive/refs/heads/main/${CLANG_VERSION}.tar.gz"

# Build tools do Android
readonly BUILDTOOLS_URL="https://android.googlesource.com/platform/build/+archive/refs/heads/main/build-tools.tar.gz"

#===============================================================================
# CORES E OUTPUT
#===============================================================================
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

info() { echo -e "${BLUE}[INFO]${NC} $1" | tee -a "${LOG_FILE}"; }
success() { echo -e "${GREEN}[SUCCESS]${NC} $1" | tee -a "${LOG_FILE}"; }
warning() { echo -e "${YELLOW}[WARNING]${NC} $1" | tee -a "${LOG_FILE}"; }
error() { echo -e "${RED}[ERROR]${NC} $1" | tee -a "${LOG_FILE}"; exit 1; }

#===============================================================================
# FUNÇÕES DE SETUP
#===============================================================================

setup_directories() {
    info "Criando estrutura de diretórios..."
    mkdir -p "${TOOLCHAIN_DIR}"
    mkdir -p "${BUILDTOOLS_DIR}"
    mkdir -p "${OUT_DIR}"
    mkdir -p "${LAB_DIR}/logs"
    success "Diretórios criados"
}

download_toolchain() {
    if [ -d "${TOOLCHAIN_DIR}/bin" ]; then
        success "Toolchain já existe em ${TOOLCHAIN_DIR}"
        return 0
    fi

    info "Baixando Google Clang ${CLANG_VERSION}..."
    info "URL: ${CLANG_URL}"
    
    cd "${TOOLCHAIN_DIR}"
    if command -v wget &> /dev/null; then
        wget -q --show-progress "${CLANG_URL}" -O clang.tar.gz 2>&1 | tee -a "${LOG_FILE}"
    elif command -v curl &> /dev/null; then
        curl -L "${CLANG_URL}" -o clang.tar.gz 2>&1 | tee -a "${LOG_FILE}"
    else
        error "wget ou curl não encontrado"
    fi

    info "Extraindo toolchain..."
    tar -xzf clang.tar.gz --strip-components=1
    rm -f clang.tar.gz
    
    if [ ! -f "${TOOLCHAIN_DIR}/bin/clang" ]; then
        error "Falha ao extrair toolchain - clang não encontrado"
    fi
    
    success "Toolchain instalado: $(${TOOLCHAIN_DIR}/bin/clang --version | head -1)"
}

verify_kernel_source() {
    info "Verificando kernel source..."
    
    if [ ! -d "${KERNEL_SRC}" ]; then
        error "Kernel source não encontrado em ${KERNEL_SRC}"
    fi
    
    if [ ! -f "${KERNEL_SRC}/Makefile" ]; then
        error "Makefile não encontrado no kernel source"
    fi
    
    if [ ! -f "${KERNEL_SRC}/arch/arm64/configs/moonstone_defconfig" ]; then
        error "moonstone_defconfig não encontrado"
    fi
    
    # Verificar versão do kernel
    local kernel_version
    kernel_version=$(grep "^VERSION =" "${KERNEL_SRC}/Makefile" | awk '{print $3}')
    local patchlevel
    patchlevel=$(grep "^PATCHLEVEL =" "${KERNEL_SRC}/Makefile" | awk '{print $3}')
    local sublevel
    sublevel=$(grep "^SUBLEVEL =" "${KERNEL_SRC}/Makefile" | awk '{print $3}')
    
    info "Kernel version: ${kernel_version}.${patchlevel}.${sublevel}"
    success "Kernel source verificado"
}

#===============================================================================
# FUNÇÃO DE BUILD PRINCIPAL
#===============================================================================

build_kernel() {
    info "================================================"
    info "INICIANDO BUILD DO KERNEL MOONSTONE"
    info "================================================"
    info "Início: $(date)"
    info "Log: ${LOG_FILE}"
    
    # Configurar ambiente EXATAMENTE como os devs fazem
    export ROOT_DIR="${KERNEL_SRC}"
    export KERNEL_DIR="${KERNEL_SRC}"
    export OUT_DIR="${OUT_DIR}"
    
    # Toolchain Google Clang (CRÍTICO!)
    export PATH="${TOOLCHAIN_DIR}/bin:${PATH}"
    export CC="${TOOLCHAIN_DIR}/bin/clang"
    export CXX="${TOOLCHAIN_DIR}/bin/clang++"
    export AR="${TOOLCHAIN_DIR}/bin/llvm-ar"
    export NM="${TOOLCHAIN_DIR}/bin/llvm-nm"
    export OBJCOPY="${TOOLCHAIN_DIR}/bin/llvm-objcopy"
    export OBJDUMP="${TOOLCHAIN_DIR}/bin/llvm-objdump"
    export READELF="${TOOLCHAIN_DIR}/bin/llvm-readelf"
    export STRIP="${TOOLCHAIN_DIR}/bin/llvm-strip"
    export LD="${TOOLCHAIN_DIR}/bin/ld.lld"
    
    # Flags do Android Kernel
    export LLVM=1
    export LLVM_IAS=1
    export ARCH=arm64
    export SUBARCH=arm64
    export CROSS_COMPILE="aarch64-linux-gnu-"
    export CLANG_TRIPLE="aarch64-linux-gnu"
    
    # Configurações de build
    export KCFLAGS="-D__ANDROID_COMMON_KERNEL__"
    export KBUILD_BUILD_USER="deivison"
    export KBUILD_BUILD_HOST="DeiviPC"
    export LOCALVERSION="-qgki"
    
    # Verificações CRÍTICAS antes do build
    info "Verificando toolchain..."
    if ! command -v clang &> /dev/null; then
        error "clang não encontrado no PATH"
    fi
    
    local clang_full_path
    clang_full_path=$(which clang)
    info "Usando clang: ${clang_full_path}"
    info "Versão: $(clang --version | head -1)"
    
    # Ir para diretório do kernel
    cd "${KERNEL_SRC}"
    info "Diretório de trabalho: $(pwd)"
    
    # LIMPEZA INTELIGENTE (não fazer mrproper que apaga .config)
    info "Limpando build anterior..."
    make -j"$(nproc)" clean 2>&1 | tee -a "${LOG_FILE}" || warning "Clean falhou (pode ser ignorado)"
    
    # CONFIGURAR KERNEL
    info "Configurando kernel (moonstone_defconfig)..."
    make -j"$(nproc)" ARCH=arm64 moonstone_defconfig 2>&1 | tee -a "${LOG_FILE}"
    
    if [ ! -f ".config" ]; then
        error ".config não foi gerado"
    fi
    
    info "Configuração aplicada:"
    grep "CONFIG_LOCALVERSION" .config | head -1 | tee -a "${LOG_FILE}"
    
    # COMPILAR!
    local jobs
    jobs=$(nproc)
    info "Compilando com ${jobs} jobs..."
    info "Isso pode levar 2-4 horas..."
    info "$(date): Build iniciado"
    
    if make -j"${jobs}" ARCH=arm64 LLVM=1 Image.gz 2>&1 | tee -a "${LOG_FILE}"; then
        info "$(date): Build finalizado"
    else
        error "Build falhou! Verifique ${LOG_FILE}"
    fi
    
    # VERIFICAR RESULTADO
    local image_path="${KERNEL_SRC}/arch/arm64/boot/Image.gz"
    
    if [ ! -f "${image_path}" ]; then
        error "Image.gz não foi gerado em ${image_path}"
    fi
    
    # SUCESSO!
    success "================================================"
    success "BUILD COMPLETADO COM SUCESSO!"
    success "================================================"
    success "Kernel: ${image_path}"
    success "Tamanho: $(ls -lh "${image_path}" | awk '{print $5}')"
    success "SHA256: $(sha256sum "${image_path}" | cut -d' ' -f1)"
    success "Fim: $(date)"
    
    # Copiar para out
    cp "${image_path}" "${OUT_DIR}/Image.gz"
    cp "${KERNEL_SRC}/.config" "${OUT_DIR}/config-$(date +%Y%m%d-%H%M%S)"
    
    success "Arquivos copiados para: ${OUT_DIR}"
    ls -lh "${OUT_DIR}"
    
    return 0
}

#===============================================================================
# MENU PRINCIPAL
#===============================================================================

show_menu() {
    echo ""
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║       LABORATÓRIO DE BUILD - KERNEL MOONSTONE              ║"
    echo "║       POCO X5 5G (SM6375) - Android 13 QGKI                ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo ""
    echo "Diretório: ${LAB_DIR}"
    echo "Kernel: ${KERNEL_SRC}"
    echo "Toolchain: ${TOOLCHAIN_DIR}"
    echo "Output: ${OUT_DIR}"
    echo ""
}

main() {
    show_menu
    
    # Setup
    setup_directories
    download_toolchain
    verify_kernel_source
    
    # Build
    build_kernel
    
    success "Processo completo!"
}

# Handler de erro
trap 'error "Script interrompido na linha $LINENO"' ERR

# Executar
main "$@"
