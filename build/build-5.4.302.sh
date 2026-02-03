#!/bin/bash
# =============================================================================
# build-5.4.302.sh - Script de build nativo para kernel 5.4.302
# =============================================================================
# Autor: DevSan
# Data: 2026-02-03
# Propósito: Compilar kernel Linux 5.4.302 para POCO X5 5G (AOSP)
#
# ESTRATÉGIA:
#   Fase 1: Build base sem modificações (provar que código compila)
#   Fase 2: Adicionar configs Docker/LXC (após Fase 1 OK)
#
# REQUISITOS:
#   - Android NDK r26d (~/Downloads/android-ndk-r26d)
#   - kernel-moonstone-devs/ (5.4.302, clonado)
#   - apply-tracing-fixes.sh (executado antes)
#
# USO:
#   ./build-5.4.302.sh [opções]
#
# OPÇÕES:
#   --clean          - Limpa build anterior (make clean && make mrproper)
#   --tracing-fix    - Aplica correções de tracing automaticamente
#   --docker-configs - Adiciona configs Docker/LXC (Fase 2)
#   -j<N>            - Número de jobs (default: $(nproc))
#
# EXEMPLOS:
#   # Build limpo com correções de tracing:
#   ./build-5.4.302.sh --clean --tracing-fix
#
#   # Build rápido (sem clean, sem modificações):
#   ./build-5.4.302.sh
#
#   # Build com configs Docker/LXC:
#   ./build-5.4.302.sh --tracing-fix --docker-configs
# =============================================================================

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configurações
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
KERNEL_DIR="$PROJECT_ROOT/kernel-moonstone-devs"
BUILD_LOG="$PROJECT_ROOT/build/build-5.4.302-$(date +%Y%m%d-%H%M%S).log"

# Flags de controle
DO_CLEAN=0
DO_TRACING_FIX=0
DO_DOCKER_CONFIGS=0
JOBS=$(nproc)

# Parse argumentos
while [[ $# -gt 0 ]]; do
    case $1 in
        --clean)
            DO_CLEAN=1
            shift
            ;;
        --tracing-fix)
            DO_TRACING_FIX=1
            shift
            ;;
        --docker-configs)
            DO_DOCKER_CONFIGS=1
            shift
            ;;
        -j*)
            JOBS="${1#-j}"
            shift
            ;;
        --help|-h)
            echo "Uso: $0 [opções]"
            echo ""
            echo "Opções:"
            echo "  --clean          Limpa build anterior"
            echo "  --tracing-fix    Aplica correções de tracing"
            echo "  --docker-configs Adiciona configs Docker/LXC"
            echo "  -j<N>            Número de jobs (default: $(nproc))"
            echo "  --help           Mostra esta ajuda"
            exit 0
            ;;
        *)
            echo -e "${RED}❌ Opção desconhecida: $1${NC}"
            echo "Use --help para ver opções disponíveis"
            exit 1
            ;;
    esac
done

# Header
echo -e "${BLUE}=============================================================================${NC}"
echo -e "${BLUE}  🦞 DevSan Kernel Build - 5.4.302 AOSP${NC}"
echo -e "${BLUE}  POCO X5 5G (moonstone) - Build Nativo${NC}"
echo -e "${BLUE}=============================================================================${NC}"
echo ""

# Verificações pré-build
echo -e "${YELLOW}🔍 Verificações pré-build...${NC}"

# 1. Verificar kernel directory
if [ ! -d "$KERNEL_DIR" ]; then
    echo -e "${RED}❌ Erro: Diretório kernel-moonstone-devs não encontrado!${NC}"
    echo "   Esperado: $KERNEL_DIR"
    exit 1
fi
echo -e "${GREEN}  ✅ Kernel source: $KERNEL_DIR${NC}"

# 2. Verificar versão do kernel
if [ -f "$KERNEL_DIR/Makefile" ]; then
    KERNEL_VERSION=$(head -5 "$KERNEL_DIR/Makefile" | grep -E "VERSION|PATCHLEVEL|SUBLEVEL" | cut -d'=' -f2 | tr '\n' '.' | sed 's/\.$//')
    echo -e "${GREEN}  ✅ Versão do kernel: $KERNEL_VERSION${NC}"
else
    echo -e "${RED}❌ Erro: Makefile não encontrado no kernel source${NC}"
    exit 1
fi

# 3. Verificar NDK
NDK_PATH="${NDK_PATH:-$HOME/Downloads/android-ndk-r26d}"
if [ ! -d "$NDK_PATH" ]; then
    echo -e "${RED}❌ Erro: Android NDK não encontrado em $NDK_PATH${NC}"
    echo "   Baixe o NDK r26d de: https://developer.android.com/ndk/downloads"
    exit 1
fi
echo -e "${GREEN}  ✅ Android NDK: $NDK_PATH${NC}"

# 4. Verificar clang
CLANG_BIN="$NDK_PATH/toolchains/llvm/prebuilt/linux-x86_64/bin"
if [ ! -f "$CLANG_BIN/clang" ]; then
    echo -e "${RED}❌ Erro: clang não encontrado em $CLANG_BIN${NC}"
    exit 1
fi
CLANG_VERSION=$("$CLANG_BIN/clang" --version | head -1)
echo -e "${GREEN}  ✅ Clang: $CLANG_VERSION${NC}"

# 5. Verificar defconfig
DEFCONFIG="arch/arm64/configs/moonstone_defconfig"
if [ ! -f "$KERNEL_DIR/$DEFCONFIG" ]; then
    echo -e "${RED}❌ Erro: Defconfig não encontrado: $DEFCONFIG${NC}"
    exit 1
fi
echo -e "${GREEN}  ✅ Defconfig: moonstone_defconfig${NC}"

echo ""

# Fase 1: Aplicar correções de tracing (se solicitado)
if [ $DO_TRACING_FIX -eq 1 ]; then
    echo -e "${YELLOW}🔧 Fase 1: Aplicando correções de tracing...${NC}"
    if [ -f "$SCRIPT_DIR/apply-tracing-fixes.sh" ]; then
        "$SCRIPT_DIR/apply-tracing-fixes.sh" "$KERNEL_DIR"
    else
        echo -e "${RED}❌ Script apply-tracing-fixes.sh não encontrado${NC}"
        exit 1
    fi
    echo ""
fi

# Fase 2: Limpeza (se solicitado)
if [ $DO_CLEAN -eq 1 ]; then
    echo -e "${YELLOW}🧹 Fase 2: Limpando build anterior...${NC}"
    cd "$KERNEL_DIR"
    make clean 2>/dev/null || true
    make mrproper 2>/dev/null || true
    echo -e "${GREEN}  ✅ Limpo!${NC}"
    echo ""
fi

# Fase 3: Configurar ambiente
echo -e "${YELLOW}⚙️  Fase 3: Configurando ambiente de build...${NC}"

export ARCH=arm64
export SUBARCH=arm64
export CC="$CLANG_BIN/clang"
export CXX="$CLANG_BIN/clang++"
export CLANG_TRIPLE=aarch64-linux-gnu-
export CROSS_COMPILE=aarch64-linux-gnu-
export CROSS_COMPILE_ARM32=arm-linux-gnueabi-
export LLVM=1
export PATH="$CLANG_BIN:$PATH"

# Flags de compilação
export KCFLAGS="-D__ANDROID_COMMON_KERNEL__ -O2 -pipe"
export KAFLAGS="-O2 -pipe"

# Outras variáveis importantes
export STOP_SHIP_TRACEPRINTK=1
export IN_KERNEL_MODULES=1
export DO_NOT_STRIP_MODULES=1

echo -e "${GREEN}  ✅ ARCH=arm64${NC}"
echo -e "${GREEN}  ✅ CC=clang${NC}"
echo -e "${GREEN}  ✅ LLVM=1${NC}"
echo -e "${GREEN}  ✅ JOBS=$JOBS${NC}"
echo ""

# Fase 4: Configurar kernel
echo -e "${YELLOW}⚙️  Fase 4: Configurando kernel...${NC}"
cd "$KERNEL_DIR"

# Carregar defconfig
make ARCH=arm64 moonstone_defconfig

echo -e "${GREEN}  ✅ Defconfig carregado${NC}"

# Se --docker-configs, adicionar configs adicionais
if [ $DO_DOCKER_CONFIGS -eq 1 ]; then
    echo -e "${YELLOW}    Adicionando configs Docker/LXC...${NC}"
    
    # Usar scripts/config para modificar configs
    CONFIG_SCRIPT="./scripts/config"
    
    if [ -f "$CONFIG_SCRIPT" ]; then
        # Namespaces
        $CONFIG_SCRIPT --enable CONFIG_USER_NS || true
        $CONFIG_SCRIPT --enable CONFIG_PID_NS || true
        $CONFIG_SCRIPT --enable CONFIG_UTS_NS || true
        $CONFIG_SCRIPT --enable CONFIG_IPC_NS || true
        $CONFIG_SCRIPT --enable CONFIG_NET_NS || true
        
        # Cgroups
        $CONFIG_SCRIPT --enable CONFIG_CGROUP_DEVICE || true
        $CONFIG_SCRIPT --enable CONFIG_CGROUP_PIDS || true
        
        # IPC
        $CONFIG_SCRIPT --enable CONFIG_SYSVIPC || true
        $CONFIG_SCRIPT --enable CONFIG_POSIX_MQUEUE || true
        
        # Security
        $CONFIG_SCRIPT --enable CONFIG_SECURITY_APPARMOR || true
        
        # OverlayFS (para Docker)
        $CONFIG_SCRIPT --enable CONFIG_OVERLAY_FS || true
        
        echo -e "${GREEN}  ✅ Configs Docker/LXC adicionados${NC}"
    else
        echo -e "${YELLOW}  ⚠️  scripts/config não encontrado, pulando configs adicionais${NC}"
    fi
fi

echo ""

# Fase 5: Compilar
echo -e "${YELLOW}🔨 Fase 5: Iniciando compilação...${NC}"
echo -e "${BLUE}   Alvo: Image.gz${NC}"
echo -e "${BLUE}   Jobs: $JOBS${NC}"
echo -e "${BLUE}   Log: $BUILD_LOG${NC}"
echo ""

START_TIME=$(date +%s)

# Compilar com tee para log
make ARCH=arm64 -j$JOBS Image.gz 2>&1 | tee "$BUILD_LOG"

END_TIME=$(date +%s)
BUILD_TIME=$((END_TIME - START_TIME))
MINUTES=$((BUILD_TIME / 60))
SECONDS=$((BUILD_TIME % 60))

echo ""

# Fase 6: Verificar resultado
echo -e "${YELLOW}📊 Fase 6: Verificando resultado...${NC}"

if [ -f "$KERNEL_DIR/arch/arm64/boot/Image.gz" ]; then
    KERNEL_SIZE=$(ls -lh "$KERNEL_DIR/arch/arm64/boot/Image.gz" | awk '{print $5}')
    KERNEL_BYTES=$(stat -c%s "$KERNEL_DIR/arch/arm64/boot/Image.gz")
    
    echo -e "${GREEN}=============================================================================${NC}"
    echo -e "${GREEN}  ✅ BUILD SUCESSO!${NC}"
    echo -e "${GREEN}=============================================================================${NC}"
    echo ""
    echo -e "📦 Kernel gerado:"
    echo -e "   Arquivo: arch/arm64/boot/Image.gz"
    echo -e "   Tamanho: $KERNEL_SIZE"
    echo -e "   Bytes: $KERNEL_BYTES"
    echo ""
    echo -e "⏱️  Tempo de build: ${MINUTES}m ${SECONDS}s"
    echo ""
    echo -e "📝 Log salvo em: $BUILD_LOG"
    echo ""
    echo -e "💡 Próximos passos:"
    echo -e "   1. Verificar kernel: file arch/arm64/boot/Image.gz"
    echo -e "   2. Testar no device: fastboot boot arch/arm64/boot/Image.gz"
    echo -e "   3. Se OK, empacotar para AnyKernel3"
    echo ""
    
    # Copiar para diretório de output
    mkdir -p "$PROJECT_ROOT/build/out"
    cp "$KERNEL_DIR/arch/arm64/boot/Image.gz" "$PROJECT_ROOT/build/out/Image-$(date +%Y%m%d-%H%M%S).gz"
    echo -e "📋 Kernel copiado para: build/out/"
    
    exit 0
else
    echo -e "${RED}=============================================================================${NC}"
    echo -e "${RED}  ❌ BUILD FALHOU!${NC}"
    echo -e "${RED}=============================================================================${NC}"
    echo ""
    echo -e "📝 Verifique o log completo: $BUILD_LOG"
    echo ""
    echo -e "💡 Dicas de troubleshooting:"
    echo -e "   - Verifique se apply-tracing-fixes.sh foi executado"
    echo -e "   - Verifique erros específicos no log"
    echo -e "   - Confirme que NDK r26d está correto"
    echo ""
    
    exit 1
fi
