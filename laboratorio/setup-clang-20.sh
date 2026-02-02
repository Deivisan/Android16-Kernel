#!/bin/bash
#===============================================================================
# SETUP GOOGLE CLANG 20.0 (r416183b) PARA KERNEL MOONSTONE
#===============================================================================

set -e

LAB_DIR="/home/deivi/Projetos/Android16-Kernel/laboratorio"
TOOLCHAIN_DIR="${LAB_DIR}/toolchain/google-clang-r416183b"
DOWNLOAD_DIR="${LAB_DIR}/downloads"

# URL do Google Clang r416183b (baseado em Clang 12.0.5, usado pelos devs)
# Nota: Google não disponibiliza tarballs diretos, então vamos baixar via git com depth=1
CLANG_REPO="https://android.googlesource.com/platform/prebuilts/clang/host/linux-x86"
CLANG_VERSION="clang-r416183b"

echo "╔════════════════════════════════════════════════════════════════╗"
echo "║          SETUP GOOGLE CLANG r416183b (Android Clang)           ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""
echo "📁 Diretório: ${TOOLCHAIN_DIR}"
echo "🔗 Repositório: ${CLANG_REPO}"
echo "🔖 Versão: ${CLANG_VERSION}"
echo ""

# Criar diretórios
mkdir -p "${TOOLCHAIN_DIR}"
mkdir -p "${DOWNLOAD_DIR}"

# Verificar se já existe
if [ -f "${TOOLCHAIN_DIR}/bin/clang" ]; then
    echo "✅ Google Clang já instalado!"
    echo ""
    echo "📊 Informações:"
    "${TOOLCHAIN_DIR}/bin/clang" --version | head -1
    echo ""
    echo "🎯 Toolchain pronta para uso!"
    exit 0
fi

echo "⬇️  Baixando Google Clang r416183b..."
echo "   Isso pode levar alguns minutos..."
echo ""

# Método 1: Tentar baixar via git (shallow clone)
cd "${DOWNLOAD_DIR}"

if [ -d "linux-x86" ]; then
    echo "🧹 Limpando download anterior..."
    rm -rf "linux-x86"
fi

echo "📦 Clonando repositório (shallow clone)..."
if git clone --depth=1 --filter=blob:none --sparse "${CLANG_REPO}" linux-x86 2>&1 | tee /tmp/clone.log; then
    echo "✅ Repositório clonado"
    
    cd linux-x86
    
    echo "📂 Selecionando apenas ${CLANG_VERSION}..."
    git sparse-checkout set "${CLANG_VERSION}" 2>&1 | tee -a /tmp/clone.log
    
    echo "📥 Checkout dos arquivos..."
    git checkout 2>&1 | tee -a /tmp/clone.log
    
    if [ -d "${CLANG_VERSION}/bin" ]; then
        echo "✅ Toolchain baixada com sucesso!"
        
        # Mover para local final
        echo "📦 Movendo para ${TOOLCHAIN_DIR}..."
        mv "${CLANG_VERSION}"/* "${TOOLCHAIN_DIR}/"
        
        # Limpar
        cd "${LAB_DIR}"
        rm -rf "${DOWNLOAD_DIR}/linux-x86"
        
        echo ""
        echo "🎉 SUCESSO!"
        echo ""
        echo "📊 Toolchain instalada:"
        "${TOOLCHAIN_DIR}/bin/clang" --version | head -1
        echo ""
        echo "📁 Local: ${TOOLCHAIN_DIR}"
        echo ""
        echo "🔧 Para usar, configure:"
        echo "   export PATH=\"${TOOLCHAIN_DIR}/bin:\$PATH\""
        echo "   export CC=\"${TOOLCHAIN_DIR}/bin/clang\""
        echo "   export LLVM=1"
        
        exit 0
    else
        echo "❌ Erro: bin/ não encontrado após checkout"
        exit 1
    fi
else
    echo ""
    echo "❌ Falha ao baixar via git"
    echo ""
    echo "📝 Log do erro:"
    tail -20 /tmp/clone.log
    echo ""
    echo "💡 Alternativa: Use o clang do sistema"
    echo "   sudo pacman -S clang llvm"
    echo ""
    exit 1
fi
