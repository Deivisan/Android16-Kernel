#!/bin/bash
# build-kernel.sh - Compilar kernel ARM64 com Halium patches
# Uso: ./build-kernel.sh [diretorio_kernel] [numero_jobs]

set -e  # Exit on error

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configurações
KERNEL_DIR="${1:-../kernel-source}"
JOBS="${2:-$(nproc)}"
OUT_DIR="${3:-../out}"

# Verificar diretório
echo -e "${YELLOW}🔧 Verificando diretório do kernel...${NC}"
if [ ! -d "$KERNEL_DIR" ]; then
    echo -e "${RED}❌ Diretório não encontrado: $KERNEL_DIR${NC}"
    echo "Clone o kernel source primeiro:"
    echo "  git clone https://github.com/MiCode/Xiaomi_Kernel_OpenSource -b moonstone-q-oss $KERNEL_DIR"
    exit 1
fi

cd "$KERNEL_DIR"

# Verificar toolchains
echo -e "${YELLOW}🔍 Verificando toolchains...${NC}"
if ! command -v aarch64-linux-gnu-gcc &> /dev/null; then
    echo -e "${RED}❌ aarch64-linux-gnu-gcc não encontrado${NC}"
    echo "Instale: sudo pacman -S aarch64-linux-gnu-gcc"
    exit 1
fi

if ! command -v clang &> /dev/null; then
    echo -e "${YELLOW}⚠️  clang não encontrado, usando GCC${NC}"
    USE_CLANG=0
else
    echo -e "${GREEN}✅ clang encontrado${NC}"
    USE_CLANG=1
fi

# Configurar ambiente
echo -e "${YELLOW}⚙️  Configurando ambiente de build...${NC}"
export ARCH=arm64
export SUBARCH=arm64
export CROSS_COMPILE=aarch64-linux-gnu-

if [ $USE_CLANG -eq 1 ]; then
    export CC=clang
    export CLANG_TRIPLE=aarch64-linux-gnu-
    export KCFLAGS="-O2 -pipe"
    export KAFLAGS="-O2 -pipe"
    echo -e "${GREEN}✅ Usando Clang${NC}"
else
    export KCFLAGS="-O2 -pipe -mtune=cortex-a76"
    export KAFLAGS="-O2 -pipe -mtune=cortex-a76"
    echo -e "${GREEN}✅ Usando GCC${NC}"
fi

# Verificar .config
echo -e "${YELLOW}📋 Verificando .config...${NC}"
if [ ! -f ".config" ]; then
    echo -e "${YELLOW}⚠️  .config não encontrado, criando do backup...${NC}"
    if [ -f "../backups/poco-x5-5g-rose-2025-02-01/kernel-config-5.4.302-eclipse.txt" ]; then
        cp ../backups/poco-x5-5g-rose-2025-02-01/kernel-config-5.4.302-eclipse.txt .config
        echo -e "${GREEN}✅ .config copiado do backup${NC}"
    else
        echo -e "${RED}❌ Backup não encontrado. Execute make defconfig manualmente${NC}"
        exit 1
    fi
fi

# Verificar configs críticas
echo -e "${YELLOW}🔍 Verificando configs críticas...${NC}"
if [ -f "../build-scripts/check-configs.sh" ]; then
    if ! ../build-scripts/check-configs.sh .config; then
        echo -e "${YELLOW}⚠️  Configs faltando. Continuar mesmo assim? (s/N)${NC}"
        read -r resposta
        if [[ ! "$resposta" =~ ^[Ss]$ ]]; then
            exit 1
        fi
    fi
else
    echo -e "${YELLOW}⚠️  check-configs.sh não encontrado, pulando verificação${NC}"
fi

# Criar diretório de output
mkdir -p "$OUT_DIR"

# Compilar
echo -e "${YELLOW}⚡ Iniciando compilação com $JOBS jobs...${NC}"
echo -e "${YELLOW}⏱️  Tempo estimado: 4-8 horas (Ryzen 7 5700G)${NC}"
echo ""

START_TIME=$(date +%s)

if ! time make -j"$JOBS" Image.gz 2>&1 | tee "$OUT_DIR/build.log"; then
    echo -e "${RED}❌ Compilação falhou!${NC}"
    echo "Verifique: $OUT_DIR/build.log"
    exit 1
fi

END_TIME=$(date +%s)
ELAPSED=$((END_TIME - START_TIME))
HOURS=$((ELAPSED / 3600))
MINUTES=$(((ELAPSED % 3600) / 60))

# Verificar resultado
echo ""
echo -e "${YELLOW}📦 Verificando resultado...${NC}"

if [ ! -f "arch/arm64/boot/Image.gz" ]; then
    echo -e "${RED}❌ Image.gz não encontrado!${NC}"
    exit 1
fi

# Copiar output
OUTPUT_FILE="$OUT_DIR/Image.gz-$(date +%Y%m%d-%H%M%S)"
cp arch/arm64/boot/Image.gz "$OUTPUT_FILE"

SIZE=$(du -h arch/arm64/boot/Image.gz | cut -f1)

echo -e "${GREEN}✅ Build completo!${NC}"
echo ""
echo -e "${GREEN}📊 Estatísticas:${NC}"
echo "  Tempo: ${HOURS}h ${MINUTES}m"
echo "  Output: $OUTPUT_FILE"
echo "  Tamanho: $SIZE"
echo "  Log: $OUT_DIR/build.log"
echo ""
echo -e "${YELLOW}🚀 Próximo passo: Testar no device${NC}"
echo "  adb reboot bootloader"
echo "  fastboot boot $OUTPUT_FILE"
