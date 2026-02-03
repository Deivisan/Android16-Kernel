#!/bin/bash
# =============================================================================
# build-kernelsu.sh - Compilar kernel 5.4.302 + KernelSU-Next + SUSFS + Docker
# =============================================================================

set -e

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configurações
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
KERNEL_DIR="${SCRIPT_DIR}/../kernel-moonstone-devs"
BUILD_DIR="${SCRIPT_DIR}"
OUTPUT_DIR="${BUILD_DIR}/out"
JOBS=$(nproc)

# Timestamp
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
LOG_FILE="${BUILD_DIR}/build-kernelsu-${TIMESTAMP}.log"

echo -e "${BLUE}🚀 Build KernelSU + SUSFS + Docker${NC}"
echo "===================================="
echo ""

# Verificar kernel
if [ ! -d "$KERNEL_DIR" ]; then
    echo -e "${RED}❌ Kernel não encontrado em $KERNEL_DIR${NC}"
    exit 1
fi

# Verificar NDK
NDK_PATH="${NDK_PATH:-$HOME/Downloads/android-ndk-r26d}"
if [ ! -d "$NDK_PATH" ]; then
    echo -e "${RED}❌ Android NDK não encontrado em $NDK_PATH${NC}"
    echo "   Baixe em: https://developer.android.com/ndk/downloads"
    exit 1
fi

echo -e "${BLUE}📋 Configurações:${NC}"
echo "   Kernel: $KERNEL_DIR"
echo "   NDK: $NDK_PATH"
echo "   Jobs: $JOBS"
echo "   Log: $LOG_FILE"
echo ""

# Criar diretórios
mkdir -p "$OUTPUT_DIR"

# Navegar para kernel
cd "$KERNEL_DIR"

# =============================================================================
# Configurar ambiente
# =============================================================================
echo -e "${BLUE}🔧 Configurando ambiente de build...${NC}"

export NDK_PATH
export CLANG_BIN="$NDK_PATH/toolchains/llvm/prebuilt/linux-x86_64/bin"
export ARCH=arm64
export SUBARCH=arm64
export CC="$CLANG_BIN/clang"
export CXX="$CLANG_BIN/clang++"
export CLANG_TRIPLE=aarch64-linux-gnu-
export CROSS_COMPILE=aarch64-linux-gnu-
export CROSS_COMPILE_ARM32=arm-linux-gnueabi-
export LLVM=1
export PATH="$CLANG_BIN:$PATH"

# Flags para ignorar warnings (essencial para KernelSU em 5.4)
export KCFLAGS="-Wno-error -O2 -pipe"
export KAFLAGS="-Wno-error"

echo -e "${GREEN}   ✅ Ambiente configurado${NC}"

# =============================================================================
# Verificar integração KernelSU
# =============================================================================
echo -e "${BLUE}🔍 Verificando integração KernelSU...${NC}"

if [ ! -d "KernelSU" ]; then
    echo -e "${RED}❌ KernelSU não encontrado!${NC}"
    echo "   Execute primeiro: ./setup-kernelsu-next.sh"
    exit 1
fi

if [ ! -L "drivers/kernelsu" ]; then
    echo -e "${RED}❌ Link drivers/kernelsu não encontrado!${NC}"
    echo "   Execute primeiro: ./setup-kernelsu-next.sh"
    exit 1
fi

echo -e "${GREEN}   ✅ KernelSU integrado${NC}"

# Verificar SUSFS
if [ -f "fs/susfs.c" ]; then
    echo -e "${GREEN}   ✅ SUSFS detectado${NC}"
    SUSFS_ENABLED=1
else
    echo -e "${YELLOW}   ⚠️  SUSFS não detectado (opcional)${NC}"
    SUSFS_ENABLED=0
fi

# =============================================================================
# Configurar kernel
# =============================================================================
echo -e "${BLUE}⚙️  Configurando kernel...${NC}"

# Limpar build anterior (mantendo .config se existir)
if [ -f ".config" ]; then
    echo "   Limpando objetos compilados..."
    make clean 2>&1 | tee -a "$LOG_FILE"
else
    echo "   Primeiro build, carregando defconfig..."
fi

# Carregar defconfig
echo "   Carregando moonstone_defconfig..."
make ARCH=arm64 moonstone_defconfig 2>&1 | tee -a "$LOG_FILE"

# Atualizar com novos defaults (se houver)
make ARCH=arm64 olddefconfig 2>&1 | tee -a "$LOG_FILE"

echo -e "${GREEN}   ✅ Configuração carregada${NC}"

# Verificar configs críticas
echo -e "${BLUE}🔍 Verificando configs críticas...${NC}"

CHECK_CONFIGS=(
    "CONFIG_KSU:KernelSU"
    "CONFIG_OVERLAY_FS:OverlayFS"
    "CONFIG_USER_NS:User Namespaces"
    "CONFIG_CGROUP_DEVICE:Cgroup Device"
)

for config_pair in "${CHECK_CONFIGS[@]}"; do
    IFS=: read -r config_name config_desc <<< "$config_pair"
    if grep -q "^${config_name}=y" .config; then
        echo -e "   ${GREEN}✓${NC} $config_desc"
    else
        echo -e "   ${RED}✗${NC} $config_desc (FALTANDO!)"
    fi
done

# =============================================================================
# Compilar
# =============================================================================
echo ""
echo -e "${BLUE}🔨 Iniciando compilação...${NC}"
echo "   Isso pode levar 30-60 minutos..."
echo "   Log: $LOG_FILE"
echo ""

# Build
START_TIME=$(date +%s)

if make ARCH=arm64 -j"$JOBS" Image.gz 2>&1 | tee -a "$LOG_FILE"; then
    END_TIME=$(date +%s)
    BUILD_TIME=$((END_TIME - START_TIME))
    
    echo ""
    echo -e "${GREEN}✅ Build concluído com sucesso!${NC}"
    echo "   Tempo: $((BUILD_TIME / 60))m $((BUILD_TIME % 60))s"
else
    echo ""
    echo -e "${RED}❌ Build falhou!${NC}"
    echo "   Verifique o log: $LOG_FILE"
    echo ""
    echo "Últimas 20 linhas do erro:"
    tail -20 "$LOG_FILE"
    exit 1
fi

# =============================================================================
# Verificar e copiar artefatos
# =============================================================================
echo ""
echo -e "${BLUE}📦 Processando artefatos...${NC}"

KERNEL_IMAGE="arch/arm64/boot/Image.gz"

if [ ! -f "$KERNEL_IMAGE" ]; then
    echo -e "${RED}❌ Kernel não foi gerado!${NC}"
    exit 1
fi

# Verificar tamanho
KERNEL_SIZE=$(stat -c%s "$KERNEL_IMAGE")
KERNEL_SIZE_MB=$(echo "scale=2; $KERNEL_SIZE / 1024 / 1024" | bc)

if (( $(echo "$KERNEL_SIZE_MB < 10" | bc -l) )); then
    echo -e "${RED}❌ Kernel muito pequeno (${KERNEL_SIZE_MB}MB) - possível erro${NC}"
    exit 1
fi

echo -e "   Tamanho do kernel: ${GREEN}${KERNEL_SIZE_MB}MB${NC}"

# Copiar para output
OUTPUT_NAME="Image-kernelsu-${TIMESTAMP}.gz"
CONFIG_NAME="config-kernelsu-${TIMESTAMP}.txt"

cp "$KERNEL_IMAGE" "${OUTPUT_DIR}/${OUTPUT_NAME}"
cp ".config" "${OUTPUT_DIR}/${CONFIG_NAME}"

# Calcular SHA256
cd "$OUTPUT_DIR"
sha256sum "$OUTPUT_NAME" > "${OUTPUT_NAME}.sha256"

echo -e "${GREEN}   ✅ Artefatos salvos em:${NC}"
echo "      ${OUTPUT_DIR}/${OUTPUT_NAME}"
echo "      ${OUTPUT_DIR}/${CONFIG_NAME}"
echo "      ${OUTPUT_DIR}/${OUTPUT_NAME}.sha256"

# =============================================================================
# Verificar símbolos KernelSU
# =============================================================================
echo ""
echo -e "${BLUE}🔍 Verificando integração KernelSU...${NC}"

if strings "$KERNEL_IMAGE" | grep -qi "kernelsu\|ksu"; then
    echo -e "   ${GREEN}✓ Strings do KernelSU encontrados no kernel${NC}"
else
    echo -e "   ${YELLOW}⚠️  Strings do KernelSU não encontrados (pode ser normal)${NC}"
fi

if [ -f "System.map" ]; then
    KSU_SYMBOLS=$(grep -c "ksu_" System.map 2>/dev/null || echo "0")
    echo "   Símbolos KSU no System.map: $KSU_SYMBOLS"
fi

# =============================================================================
# Criar AnyKernel3 ZIP
# =============================================================================
echo ""
echo -e "${BLUE}📦 Criando AnyKernel3 ZIP...${NC}"

ANYKERNEL_DIR="${SCRIPT_DIR}/../anykernel3-poco-x5"
if [ -d "$ANYKERNEL_DIR" ]; then
    # Copiar kernel
    cp "${OUTPUT_DIR}/${OUTPUT_NAME}" "$ANYKERNEL_DIR/Image.gz"
    
    # Criar ZIP
    cd "$ANYKERNEL_DIR"
    ZIP_NAME="DevSan-KernelSU-5.4.302-${TIMESTAMP}.zip"
    zip -r "${OUTPUT_DIR}/${ZIP_NAME}" . -x "*.zip" -x "*.gz" -x "*.sha256" 2>/dev/null || true
    
    # Restaurar
    rm -f "$ANYKERNEL_DIR/Image.gz"
    
    if [ -f "${OUTPUT_DIR}/${ZIP_NAME}" ]; then
        echo -e "${GREEN}   ✅ AnyKernel3 ZIP criado:${NC} ${ZIP_NAME}"
    fi
else
    echo -e "${YELLOW}   ⚠️  Diretório anykernel3-poco-x5 não encontrado${NC}"
fi

# =============================================================================
# Resumo final
# =============================================================================
echo ""
echo -e "${GREEN}================================${NC}"
echo -e "${GREEN}🎉 BUILD CONCLUÍDO COM SUCESSO!${NC}"
echo -e "${GREEN}================================${NC}"
echo ""
echo "📊 Resumo:"
echo "   Kernel: ${OUTPUT_NAME}"
echo "   Tamanho: ${KERNEL_SIZE_MB}MB"
echo "   Tempo: $((BUILD_TIME / 60))m $((BUILD_TIME % 60))s"
echo "   Log: ${LOG_FILE}"
echo ""
echo "📁 Arquivos em: ${OUTPUT_DIR}/"
echo ""
echo "🧪 Próximos passos:"
echo "   1. Teste temporário:"
echo "      adb reboot bootloader"
echo "      fastboot boot ${OUTPUT_DIR}/${OUTPUT_NAME}"
echo ""
echo "   2. Verificar KernelSU:"
echo "      adb shell uname -a"
echo "      adb shell su -c 'ksud --version'"
echo ""
echo "   3. Instalar KernelSU Manager:"
echo "      https://github.com/KernelSU-Next/KernelSU-Next/releases"
echo ""
