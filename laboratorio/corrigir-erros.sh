#!/bin/bash
#===============================================================================
# SCRIPT DE CORREÇÃO AUTOMÁTICA - ERROS DO KERNEL MOONSTONE
#===============================================================================

set -e

KERNEL_DIR="/home/deivi/Projetos/Android16-Kernel/kernel-moonstone-devs"
LOG="/tmp/fix-kernel-$(date +%H%M%S).log"

echo "╔════════════════════════════════════════════════════════════════╗"
echo "║          🔧 CORREÇÃO AUTOMÁTICA - KERNEL MOONSTONE             ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""
echo "⏰ Início: $(date '+%H:%M:%S')"
echo "📁 Kernel: $KERNEL_DIR"
echo ""

cd "$KERNEL_DIR"

#===============================================================================
# CORREÇÃO 1: FT3519T Touchscreen
#===============================================================================
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔧 CORREÇÃO 1: Desativando FT3519T (firmware faltando)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if grep -q "CONFIG_TOUCHSCREEN_FT3519T=y" .config 2>/dev/null; then
    sed -i 's/CONFIG_TOUCHSCREEN_FT3519T=y/CONFIG_TOUCHSCREEN_FT3519T=n/' .config
    echo "✅ FT3519T desativado no .config"
else
    echo "ℹ️  FT3519T já desativado ou não encontrado"
fi

#===============================================================================
# CORREÇÃO 2: Tracing (rmnet_trace.h)
#===============================================================================
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔧 CORREÇÃO 2: Desativando Tracing problemático"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Desativar tracing que causa erros com Clang 21
CONFIGS_TO_DISABLE=(
    "CONFIG_TRACING"
    "CONFIG_EVENT_TRACING"
    "CONFIG_FTRACE"
    "CONFIG_FUNCTION_TRACER"
)

for config in "${CONFIGS_TO_DISABLE[@]}"; do
    if grep -q "${config}=y" .config 2>/dev/null; then
        sed -i "s/${config}=y/${config}=n/" .config
        echo "✅ $config desativado"
    fi
done

#===============================================================================
# CORREÇÃO 3: Flags de Compilação
#===============================================================================
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔧 CORREÇÃO 3: Configurando flags de compilação"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

cat > /tmp/kernel-flags.sh << 'FLAGEOF'
#!/bin/bash
# Flags para Clang 21+
export ARCH=arm64
export LLVM=1
export CC=clang
export KCFLAGS="-Wno-format -Wno-format-security -Wno-unused-variable -Wno-error"
export KBUILD_BUILD_USER="deivison"
export KBUILD_BUILD_HOST="DeiviPC"
FLAGEOF

chmod +x /tmp/kernel-flags.sh
echo "✅ Flags configuradas"
echo ""
echo "Para usar, execute:"
echo "   source /tmp/kernel-flags.sh"

#===============================================================================
# RESUMO
#===============================================================================
echo ""
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║                      ✅ CORREÇÕES APLICADAS                    ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""
echo "1. FT3519T desativado (firmware faltando)"
echo "2. Tracing desativado (erros com Clang 21)"
echo "3. Flags de compilação configuradas"
echo ""
echo "⏰ Fim: $(date '+%H:%M:%S')"
echo ""
echo "🚀 Próximo passo:"
echo "   source /tmp/kernel-flags.sh"
echo "   cd $KERNEL_DIR"
echo "   make -j$(nproc) Image.gz"
echo ""
