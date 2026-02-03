#!/bin/bash
# =============================================================================
# apply-tracing-fixes.sh - Corrige TRACE_INCLUDE_PATH para Clang
# =============================================================================
# Autor: DevSan
# Data: 2026-02-03
# Propósito: Aplicar correções necessárias para compilar kernel 5.4.302
#            com Clang (resolve problema de tracing system)
#
# PROBLEMA:
#   Headers de techpack usam #define TRACE_INCLUDE_PATH .
#   Clang não resolve paths relativos '.' corretamente em macros
#   Resultado: #include "./rmnet_trace.h" -> file not found
#
# SOLUÇÃO:
#   Alterar TRACE_INCLUDE_PATH de '.' para paths absolutos relativos ao kernel root
#
# USO:
#   ./apply-tracing-fixes.sh [caminho_para_kernel]
#
# EXEMPLO:
#   cd /home/deivi/Projetos/android16-kernel
#   ./build/apply-tracing-fixes.sh kernel-moonstone-devs
# =============================================================================

set -e

# Diretório do kernel (default: kernel-moonstone-devs)
KERNEL_DIR="${1:-kernel-moonstone-devs}"

if [ ! -d "$KERNEL_DIR" ]; then
    echo "❌ Erro: Diretório '$KERNEL_DIR' não encontrado!"
    echo "Uso: $0 [caminho_para_kernel]"
    exit 1
fi

echo "🔧 Aplicando correções de tracing em: $KERNEL_DIR"
echo ""

# Mapa de arquivos para corrigir e seus respectivos paths
# Formato: ["caminho/relativo/do/header"]="TRACE_INCLUDE_PATH correto"
declare -A TRACE_FIXES=(
    # Techpack DATARMNET (Rede)
    ["techpack/datarmnet/core/rmnet_trace.h"]="../../techpack/datarmnet/core"
    ["techpack/datarmnet/core/wda.h"]="../../techpack/datarmnet/core"
    ["techpack/datarmnet/core/dfc.h"]="../../techpack/datarmnet/core"
    
    # Techpack Camera
    ["techpack/camera/drivers/cam_utils/cam_trace.h"]="techpack/camera/drivers/cam_utils"
    
    # Techpack Display
    ["techpack/display/rotator/sde_rotator_trace.h"]="../../techpack/display/rotator"
    ["techpack/display/msm/sde/sde_trace.h"]="../../techpack/display/msm/sde"
    
    # Techpack DataIPA
    ["techpack/dataipa/drivers/platform/msm/ipa/ipa_v3/ipa_trace.h"]="../../techpack/dataipa/drivers/platform/msm/ipa/ipa_v3"
    ["techpack/dataipa/drivers/platform/msm/ipa/ipa_clients/rndis_ipa_trace.h"]="../../techpack/dataipa/drivers/platform/msm/ipa/ipa_clients"
    
    # Techpack Video
    ["techpack/video/msm/vidc/msm_vidc_events.h"]="../../techpack/video/msm/vidc"
    
    # Kernel Scheduler (WALT)
    ["kernel/sched/walt/trace.h"]="../../kernel/sched/walt"
)

# Contadores
FIXED_COUNT=0
SKIPPED_COUNT=0
BACKUP_COUNT=0

# Aplicar correções
for file in "${!TRACE_FIXES[@]}"; do
    full_path="$KERNEL_DIR/$file"
    new_path="${TRACE_FIXES[$file]}"
    
    if [ -f "$full_path" ]; then
        # Criar backup se não existir
        if [ ! -f "$full_path.bak" ]; then
            cp "$full_path" "$full_path.bak"
            BACKUP_COUNT=$((BACKUP_COUNT + 1))
        fi
        
        # Verificar se precisa de correção
        if grep -q "^#define TRACE_INCLUDE_PATH" "$full_path" 2>/dev/null; then
            current_path=$(grep "^#define TRACE_INCLUDE_PATH" "$full_path" | head -1 | awk '{print $3}')
            if [ "$current_path" != "$new_path" ]; then
                sed -i "s|^#define TRACE_INCLUDE_PATH.*|#define TRACE_INCLUDE_PATH $new_path|" "$full_path"
                echo "  ✅ $file"
                echo "     Alterado para: TRACE_INCLUDE_PATH $new_path"
                FIXED_COUNT=$((FIXED_COUNT + 1))
            else
                echo "  ⏭️  $file (já corrigido)"
                SKIPPED_COUNT=$((SKIPPED_COUNT + 1))
            fi
        else
            echo "  ⚠️  $file (TRACE_INCLUDE_PATH não encontrado)"
            SKIPPED_COUNT=$((SKIPPED_COUNT + 1))
        fi
    else
        echo "  ⚠️  $file (não encontrado)"
        SKIPPED_COUNT=$((SKIPPED_COUNT + 1))
    fi
done

echo ""
echo "📊 Resumo:"
echo "  ✅ Corrigidos: $FIXED_COUNT"
echo "  ⏭️  Pulados: $SKIPPED_COUNT"
echo "  💾 Backups criados: $BACKUP_COUNT"
echo ""

# Instruções para restaurar
echo "💡 Para restaurar arquivos originais:"
echo "   find $KERNEL_DIR -name '*.bak' -exec sh -c 'mv \"\$1\" \"\${1%.bak}\"' _ {} \;"
echo ""

if [ $FIXED_COUNT -gt 0 ]; then
    echo "✅ Correções aplicadas com sucesso!"
    echo "   Próximo passo: Executar build do kernel"
else
    echo "ℹ️  Nenhuma correção necessária (todos os arquivos já estão corrigidos)"
fi
