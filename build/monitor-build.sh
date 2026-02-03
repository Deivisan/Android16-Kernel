#!/bin/bash
# Monitor de build - Mostra progresso do kernel compilation

LOG_FILE=$(ls -t build-5.4.302-docker-*.log 2>/dev/null | head -1)

if [ -z "$LOG_FILE" ]; then
    echo "❌ Log file não encontrado"
    exit 1
fi

echo "📊 Monitorando: $LOG_FILE"
echo ""

while true; do
    clear
    echo "🚀 KERNEL BUILD MONITOR - Docker/LXC Edition"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    
    # Contar compilações
    CC_COUNT=$(grep -c "^\s*CC\s" "$LOG_FILE" 2>/dev/null || echo 0)
    AS_COUNT=$(grep -c "^\s*AS\s" "$LOG_FILE" 2>/dev/null || echo 0)
    LD_COUNT=$(grep -c "^\s*LD\s" "$LOG_FILE" 2>/dev/null || echo 0)
    AR_COUNT=$(grep -c "^\s*AR\s" "$LOG_FILE" 2>/dev/null || echo 0)
    
    echo "📈 Arquivos compilados:"
    echo "  CC (Compilação):    $CC_COUNT"
    echo "  AS (Assembly):      $AS_COUNT"
    echo "  LD (Linking):       $LD_COUNT"
    echo "  AR (Archive):       $AR_COUNT"
    echo ""
    
    # Verificar erros
    ERROR_COUNT=$(grep -c "error:" "$LOG_FILE" 2>/dev/null || echo 0)
    WARN_COUNT=$(grep -c "warning:" "$LOG_FILE" 2>/dev/null || echo 0)
    
    echo "⚠️  Status:"
    echo "  Erros:    $ERROR_COUNT"
    echo "  Warnings: $WARN_COUNT"
    echo ""
    
    # Verificar se finalizou
    if grep -q "Image.gz" "$LOG_FILE" 2>/dev/null; then
        echo "✅ BUILD COMPLETO! Image.gz gerado"
        break
    fi
    
    if [ "$ERROR_COUNT" -gt 0 ]; then
        echo "❌ Build falhou com erros"
        echo ""
        echo "Últimos erros:"
        grep "error:" "$LOG_FILE" | tail -5
        break
    fi
    
    # Últimas linhas
    echo "📝 Últimas compilações:"
    tail -10 "$LOG_FILE" | grep -E "(CC|AS|LD|AR)" | tail -5
    echo ""
    echo "⏱️  Atualizando a cada 10 segundos... (Ctrl+C para sair)"
    
    sleep 10
done
