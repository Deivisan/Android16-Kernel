#!/bin/bash
# build-kernel-docker.sh
# Script de build para kernel moonstone com correções automáticas

set -e

echo "🦞 DevSan Max - Kernel Moonstone Docker Build"
echo "============================================"
echo ""

# Configurar ambiente (já setado no Docker)
export KERNEL_DIR=/workspace/kernel-moonstone-devs
export OUTPUT_DIR=/workspace/output

echo "📊 Informações do Ambiente:"
echo "  KERNEL_DIR: ${KERNEL_DIR}"
echo "  OUTPUT_DIR: ${OUTPUT_DIR}"
echo "  CC: ${CC}"
echo "  CLANG: $(clang --version | head -1)"
echo "  CROSS_COMPILE: ${CROSS_COMPILE}"
echo ""

cd ${KERNEL_DIR}

# Criar diretório de output
mkdir -p ${OUTPUT_DIR}

# Criar .config a partir do defconfig
echo "⚙️  Carregando defconfig..."
make ARCH=${ARCH} moonstone_defconfig

# Verificar configuração
echo ""
echo "📋 Configuração Atual:"
echo "  LOCALVERSION: $(grep CONFIG_LOCALVERSION .config | cut -d= -f2)"
echo "  LTO: $(grep CONFIG_LTO_CLANG .config || echo não habilitado)"
echo "  CFI: $(grep CONFIG_CFI_CLANG .config || echo não habilitado)"
echo ""

# ==============================================================================
# CORREÇÃO AUTOMÁTICA PARA O PROBLEMA DE TRACING
# ==============================================================================
echo "🔧 Aplicando correções automáticas para tracing..."
echo ""

# Função para corrigir TRACE_INCLUDE_PATH em arquivos .h
fix_trace_include_path() {
    local file="$1"
    local relative_path="$2"

    echo "  📝 Corrigindo: ${file}"

    # Substituir TRACE_INCLUDE_PATH . por TRACE_INCLUDE_PATH <path>
    if grep -q "TRACE_INCLUDE_PATH ." "$file"; then
        # Backup do arquivo original
        cp "$file" "${file}.bak"

        # Aplicar correção
        sed -i "s|#define TRACE_INCLUDE_PATH .|#define TRACE_INCLUDE_PATH ${relative_path}|" "$file"

        echo "    ✅ Alterado de 'TRACE_INCLUDE_PATH .' para 'TRACE_INCLUDE_PATH ${relative_path}'"
    fi
}

# Corrigir todos os headers de tracing dos techpacks
echo "Techpack DATARMNET:"
fix_trace_include_path "techpack/datarmnet/core/rmnet_trace.h" "techpack/datarmnet/core"
fix_trace_include_path "techpack/datarmnet/core/wda.h" "techpack/datarmnet/core"
fix_trace_include_path "techpack/datarmnet/core/dfc.h" "techpack/datarmnet/core"

echo ""
echo "Techpack DATAIPA:"
fix_trace_include_path "techpack/dataipa/drivers/platform/msm/ipa/ipa_v3/ipa_trace.h" "techpack/dataipa/drivers/platform/msm/ipa/ipa_v3"
fix_trace_include_path "techpack/dataipa/drivers/platform/msm/ipa/ipa_clients/rndis_ipa_trace.h" "techpack/dataipa/drivers/platform/msm/ipa/ipa_clients"

echo ""
echo "Techpack CAMERA:"
fix_trace_include_path "techpack/camera/drivers/cam_utils/cam_trace.h" "techpack/camera/drivers/cam_utils"

echo ""
echo "Techpack DISPLAY:"
fix_trace_include_path "techpack/display/rotator/sde_rotator_trace.h" "techpack/display/rotator"
fix_trace_include_path "techpack/display/msm/sde/sde_trace.h" "techpack/display/msm/sde"

echo ""
echo "Techpack VIDEO:"
fix_trace_include_path "techpack/video/msm/vidc/msm_vidc_events.h" "techpack/video/msm/vidc"

echo ""
echo "Kernel WALT scheduler:"
# WALT scheduler não está em techpack, está em kernel/sched/walt
if [ -f "kernel/sched/walt/trace.h" ]; then
    fix_trace_include_path "kernel/sched/walt/trace.h" "kernel/sched/walt"
fi

echo ""
echo "✅ Correções de tracing aplicadas!"
echo ""

# ==============================================================================
# BUILD CONFIGURAÇÕES ADICIONAIS
# ==============================================================================
echo "⚙️  Configurando flags de build..."

# Adicionar flags extras
export KCFLAGS="${KCFLAGS} -D__ANDROID_COMMON_KERNEL__"
export KAFLAGS="${KAFLAGS} -D__ANDROID_COMMON_KERNEL__"

echo "  KCFLAGS: ${KCFLAGS}"
echo ""

# ==============================================================================
# COMPILAÇÃO
# ==============================================================================
echo "🔨 Iniciando compilação..."
echo "  Alvo: Image.gz"
echo "  Jobs: 8 (limitado para RAM do container)"
echo "  Tempo estimado: 2-4 horas (Docker pode ser mais lento)"
echo ""

# Limpar build anterior se existir
if [ -d "arch/arm64/boot/.Image.gz.cmd.d" ]; then
    echo "🧹 Limpando build anterior..."
    make ARCH=${ARCH} clean
fi

# Compilar
START_TIME=$(date +%s)
time make ARCH=${ARCH} \
    CC=${CC} \
    CLANG_TRIPLE=${CLANG_TRIPLE} \
    CROSS_COMPILE=${CROSS_COMPILE} \
    KCFLAGS="${KCFLAGS}" \
    KAFLAGS="${KAFLAGS}" \
    -j8 \
    Image.gz 2>&1 | tee ${OUTPUT_DIR}/build.log

END_TIME=$(date +%s)
BUILD_TIME=$((END_TIME - START_TIME))
BUILD_MINUTES=$((BUILD_TIME / 60))

echo ""
echo "⏱️  Build finalizado em ${BUILD_MINUTES} minutos"

# ==============================================================================
# VERIFICAÇÃO DO RESULTADO
# ==============================================================================
echo ""
echo "✅ Verificando resultado..."

if [ -f "arch/arm64/boot/Image.gz" ]; then
    KERNEL_SIZE=$(ls -lh arch/arm64/boot/Image.gz | awk '{print $5}')
    KERNEL_BYTES=$(stat -f%z arch/arm64/boot/Image.gz 2>/dev/null || stat -c%s arch/arm64/boot/Image.gz)

    echo ""
    echo "🎉 BUILD SUCESSO! 🎉"
    echo ""
    echo "📦 Kernel gerado:"
    echo "  Arquivo: arch/arm64/boot/Image.gz"
    echo "  Tamanho: ${KERNEL_SIZE}"
    echo "  Bytes: ${KERNEL_BYTES}"
    echo ""

    # Verificar se tamanho está correto (15-25MB)
    if [ ${KERNEL_BYTES} -gt 15000000 ] && [ ${KERNEL_BYTES} -lt 26000000 ]; then
        echo "✅ Tamanho OK (15-25MB)"
    else
        echo "⚠️  Tamanho fora do esperado (esperado: 15-25MB)"
    fi

    # Copiar para output directory
    cp arch/arm64/boot/Image.gz ${OUTPUT_DIR}/Image.gz
    cp System.map ${OUTPUT_DIR}/System.map 2>/dev/null || true
    cp vmlinux ${OUTPUT_DIR}/vmlinux 2>/dev/null || true

    echo ""
    echo "📦 Arquivos copiados para: ${OUTPUT_DIR}/"
    echo "  - Image.gz"
    echo "  - System.map (se disponível)"
    echo "  - vmlinux (se disponível)"
    echo ""

    # Extrair versão se possível
    VERSION=$(strings arch/arm64/boot/Image.gz | grep "Linux version" | head -1 || echo "Não foi possível extrair versão")
    echo "🔍 Versão: ${VERSION}"
    echo ""

    exit 0
else
    echo ""
    echo "❌ BUILD FALHOU!"
    echo ""
    echo "Verifique o log em: ${OUTPUT_DIR}/build.log"
    echo ""
    echo "Possíveis causas:"
    echo "  1. Erro de tracing (TRACE_INCLUDE_PATH)"
    echo "  2. Erro de toolchain (versão incorreta do Clang)"
    echo "  3. Out of memory (tente reduzir jobs)"
    echo "  4. Dependência faltando"
    echo ""

    # Mostrar últimos erros do log
    echo "📝 Últimas linhas do log:"
    tail -50 ${OUTPUT_DIR}/build.log
    echo ""

    exit 1
fi
