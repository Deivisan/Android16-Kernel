#!/bin/bash
# build-moonstone-docker-main.sh
# Script principal para orquestrar build do kernel Moonstone via Docker
# Autor: DevSan Max
# Data: 2026-02-02

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo "🦞 DevSan Max - Kernel Moonstone Build Manager"
echo "================================================"
echo ""

# Configurações
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
KERNEL_DIR="/home/deivi/Projetos/Android16-Kernel/kernel-moonstone-devs"
DOCKER_IMAGE="moonstone-kernel-builder:latest"
DOCKER_CONTAINER="moonstone-build"
OUTPUT_DIR="/home/deivi/Projetos/Android16-Kernel/laboratorio/output"

echo "📊 Configurações:"
echo "  Script Dir: ${SCRIPT_DIR}"
echo "  Kernel Dir: ${KERNEL_DIR}"
echo "  Docker Image: ${DOCKER_IMAGE}"
echo "  Output Dir: ${OUTPUT_DIR}"
echo ""

# ==============================================================================
# FASE 1: VERIFICAÇÃO DO HOST
# ==============================================================================
echo "🔍 FASE 1: Verificando ambiente do host..."
echo ""

# Verificar se Docker está instalado
if ! command -v docker &> /dev/null; then
    echo -e "${RED}❌ Docker não encontrado!${NC}"
    echo "Por favor instale Docker antes de executar este script."
    exit 1
fi

echo -e "${GREEN}✅ Docker encontrado${NC}"
echo "  Versão: $(docker --version)"
echo ""

# Verificar se kernel-moonstone-devs existe
if [ ! -d "${KERNEL_DIR}" ]; then
    echo -e "${RED}❌ Diretório kernel-moonstone-devs não encontrado!${NC}"
    echo "  Esperado: ${KERNEL_DIR}"
    exit 1
fi

echo -e "${GREEN}✅ Kernel source encontrado${NC}"
echo ""

# Verificar espaço em disco
AVAILABLE_SPACE=$(df -BG "$HOME" | awk 'NR==2 {print $4}')
if [ "${AVAILABLE_SPACE}" -lt 50 ]; then
    echo -e "${YELLOW}⚠️  Aviso: Menos de 50GB disponível!${NC}"
    echo "  Recomendado: 50GB+ livres"
    echo ""
    read -p "Continuar mesmo assim? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
else
    echo -e "${GREEN}✅ Espaço em disco suficiente (${AVAILABLE_SPACE}GB)${NC}"
fi
echo ""

# ==============================================================================
# FASE 2: PREPARAÇÃO DO DOCKER
# ==============================================================================
echo "🐳 FASE 2: Preparando Docker..."
echo ""

# Criar diretório de output
mkdir -p "${OUTPUT_DIR}"

# Verificar se imagem já existe
if docker images | grep -q "${DOCKER_IMAGE}"; then
    echo -e "${YELLOW}⚠️  Imagem Docker já existe${NC}"
    read -p "Recriar imagem? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        REBUILD_DOCKER=1
    else
        REBUILD_DOCKER=0
    fi
else
    REBUILD_DOCKER=1
fi

if [ "${REBUILD_DOCKER}" -eq 1 ]; then
    echo "🔨 Buildando imagem Docker..."
    cd "${SCRIPT_DIR}"
    docker build -t "${DOCKER_IMAGE}" .
    echo -e "${GREEN}✅ Imagem Docker criada${NC}"
else
    echo -e "${GREEN}✅ Usando imagem Docker existente${NC}"
fi
echo ""

# ==============================================================================
# FASE 3: EXECUTAR BUILD NO DOCKER
# ==============================================================================
echo "🚀 FASE 3: Executando build no Docker..."
echo ""

# Remover container anterior se existir
if docker ps -a | grep -q "${DOCKER_CONTAINER}"; then
    echo "🧹 Removendo container anterior..."
    docker rm -f "${DOCKER_CONTAINER}" > /dev/null 2>&1 || true
fi

# Executar build no Docker
echo "🔨 Iniciando compilação..."
echo "  Este processo pode levar 2-4 horas"
echo "  Para monitorar logs: docker logs -f ${DOCKER_CONTAINER}"
echo ""

docker run --rm \
    --name "${DOCKER_CONTAINER}" \
    -v "${KERNEL_DIR}:/workspace/kernel-moonstone-devs:ro" \
    -v "${OUTPUT_DIR}:/workspace/output" \
    -e JOBS=8 \
    "${DOCKER_IMAGE}" \
    /workspace/build-kernel-docker.sh

DOCKER_EXIT_CODE=$?

echo ""
echo "⏱️  Docker finalizado com código: ${DOCKER_EXIT_CODE}"
echo ""

# ==============================================================================
# FASE 4: VERIFICAÇÃO DO RESULTADO
# ==============================================================================
echo "✅ FASE 4: Verificando resultado..."
echo ""

if [ "${DOCKER_EXIT_CODE}" -eq 0 ]; then
    if [ -f "${OUTPUT_DIR}/Image.gz" ]; then
        KERNEL_SIZE=$(ls -lh "${OUTPUT_DIR}/Image.gz" | awk '{print $5}')
        KERNEL_BYTES=$(stat -f%z "${OUTPUT_DIR}/Image.gz" 2>/dev/null || stat -c%s "${OUTPUT_DIR}/Image.gz")

        echo -e "${GREEN}🎉 BUILD SUCESSO! 🎉${NC}"
        echo ""
        echo "📦 Kernel gerado:"
        echo "  Arquivo: ${OUTPUT_DIR}/Image.gz"
        echo "  Tamanho: ${KERNEL_SIZE}"
        echo "  Bytes: ${KERNEL_BYTES}"
        echo ""

        # Verificar tamanho
        if [ ${KERNEL_BYTES} -gt 15000000 ] && [ ${KERNEL_BYTES} -lt 26000000 ]; then
            echo -e "${GREEN}✅ Tamanho correto (15-25MB)${NC}"
        else
            echo -e "${YELLOW}⚠️  Tamanho fora do esperado (esperado: 15-25MB)${NC}"
        fi

        # SHA256
        echo ""
        echo "🔒 SHA256:"
        sha256sum "${OUTPUT_DIR}/Image.gz"

        # SHA1
        echo "🔒 SHA1:"
        sha1sum "${OUTPUT_DIR}/Image.gz"

        echo ""
        echo "📋 Próximos passos:"
        echo "  1. Copiar Image.gz para diretório AnyKernel3"
        echo "  2. Atualizar ramdisk se necessário"
        echo "  3. Criar boot.img com AnyKernel3"
        echo "  4. Testar via fastboot boot"
        echo ""

        exit 0
    else
        echo -e "${RED}❌ Image.gz não encontrado!${NC}"
        echo "  Esperado em: ${OUTPUT_DIR}/Image.gz"
        exit 1
    fi
else
    echo -e "${RED}❌ Build falhou!${NC}"
    echo ""
    echo "Verifique o log: ${OUTPUT_DIR}/build.log"
    echo ""
    echo "Para ver detalhes do container:"
    echo "  docker logs ${DOCKER_CONTAINER}"

    # Mostrar últimos erros
    if [ -f "${OUTPUT_DIR}/build.log" ]; then
        echo ""
        echo "📝 Últimas linhas do log:"
        echo "----------------------------------------"
        tail -50 "${OUTPUT_DIR}/build.log"
    fi

    exit 1
fi
