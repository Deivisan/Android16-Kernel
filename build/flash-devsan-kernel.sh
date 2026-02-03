#!/usr/bin/env bash
# DevSan AGI - Script de Teste e Flash do Kernel 5.4.302
# Uso: ./flash-devsan-kernel.sh [test|flash|backup]

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
KERNEL="$PROJECT_ROOT/kernel-moonstone-devs/arch/arm64/boot/Image.gz"
ZIP="$PROJECT_ROOT/build/out/DevSan-AGI-Kernel-5.4.302-moonstone-slotb.zip"

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

banner() {
    echo -e "${BLUE}"
    cat <<'EOF'
 ###########################################
 ###########################################
  ######    ##   ##   #####   #####   #####
  ##   ##   ##   ##   ##      ##      ##
  ##   ##   ##   ##   #####   #####   #####
  ##   ##   ##   ##   ##          ##      ##
  ######     #####    #####   #####   #####
                               
 ###########################################
     DevSan AGI Kernel for moonstone
   (POCO X5 5G) - Slot B Only Edition
 ###########################################
EOF
    echo -e "${NC}"
}

usage() {
    echo "Uso: $0 [comando]"
    echo ""
    echo "Comandos:"
    echo "  test     - Boot temporário (seguro, não grava)"
    echo "  flash    - Flash permanente no slot B"
    echo "  backup   - Fazer backup do boot_b atual"
    echo "  verify   - Verificar kernel"
    echo ""
    echo "Exemplo:"
    echo "  $0 test     # Testar sem modificar nada"
    echo "  $0 backup   # Backup antes de flashar"
    echo "  $0 flash    # Flash permanente"
    exit 1
}

check_kernel() {
    if [ ! -f "$KERNEL" ]; then
        echo -e "${RED}ERRO: Kernel não encontrado: $KERNEL${NC}"
        echo "Compile primeiro: ./build/build-5.4.302.sh --tracing-fix -j12"
        exit 1
    fi
    echo -e "${GREEN}✅ Kernel encontrado:${NC}"
    ls -lh "$KERNEL"
}

check_zip() {
    if [ ! -f "$ZIP" ]; then
        echo -e "${RED}ERRO: ZIP não encontrado: $ZIP${NC}"
        exit 1
    fi
    echo -e "${GREEN}✅ ZIP encontrado:${NC}"
    ls -lh "$ZIP"
}

cmd_test() {
    banner
    check_kernel
    echo ""
    echo -e "${YELLOW}⚠️  MODO TESTE - Boot temporário (não grava nada)${NC}"
    echo ""
    echo -e "${BLUE}Comando que será executado:${NC}"
    echo "  fastboot boot \"$KERNEL\""
    echo ""
    read -p "Conecte o device em fastboot e pressione Enter..."
    
    echo -e "${YELLOW}🚀 Iniciando boot temporário...${NC}"
    fastboot boot "$KERNEL"
    
    echo ""
    echo -e "${GREEN}✅ Kernel enviado!${NC}"
    echo -e "${YELLOW}⏳ Aguarde o boot (pode levar 1-2 minutos)...${NC}"
    echo ""
    echo -e "${BLUE}Para verificar:${NC}"
    echo "  adb wait-for-device"
    echo "  adb shell uname -a"
    echo ""
    echo -e "${YELLOW}💡 Se funcionar, rode: $0 flash${NC}"
}

cmd_backup() {
    banner
    echo -e "${BLUE}💾 Fazendo backup do boot_b atual...${NC}"
    echo ""
    
    TIMESTAMP=$(date +%Y%m%d-%H%M%S)
    BACKUP_FILE="$PROJECT_ROOT/backups/boot_b_backup_$TIMESTAMP.img"
    
    adb shell "dd if=/dev/block/by-name/boot_b of=/sdcard/boot_b_backup.img bs=1048576" || {
        echo -e "${RED}ERRO: Falha no backup${NC}"
        exit 1
    }
    
    adb pull /sdcard/boot_b_backup.img "$BACKUP_FILE"
    
    echo -e "${GREEN}✅ Backup salvo em:${NC}"
    ls -lh "$BACKUP_FILE"
}

cmd_flash() {
    banner
    check_kernel
    echo ""
    echo -e "${YELLOW}⚠️  FLASH PERMANENTE NO SLOT B${NC}"
    echo -e "${YELLOW}⚠️  Isso substituirá o kernel do slot B${NC}"
    echo ""
    
    # Verificar se tem backup
    if ! ls "$PROJECT_ROOT/backups/"*boot_b_backup*.img 2>/dev/null | grep -q .; then
        echo -e "${RED}⚠️  Nenhum backup encontrado!${NC}"
        echo -e "${YELLOW}Recomendo fazer backup primeiro:${NC} $0 backup"
        read -p "Deseja continuar mesmo assim? (s/N): " confirm
        [ "$confirm" != "s" ] && exit 1
    else
        echo -e "${GREEN}✅ Backup encontrado${NC}"
    fi
    
    echo ""
    read -p "Conecte o device em fastboot e pressione Enter..."
    
    echo -e "${YELLOW}🚀 Flashando kernel no slot B...${NC}"
    fastboot flash boot_b "$KERNEL"
    
    echo -e "${YELLOW}🔄 Ativando slot B...${NC}"
    fastboot set_active b
    
    echo -e "${GREEN}✅ Flash completo!${NC}"
    echo -e "${YELLOW}🔄 Reboot...${NC}"
    fastboot reboot
    
    echo ""
    echo -e "${BLUE}Verificação pós-boot:${NC}"
    echo "  adb wait-for-device"
    echo "  adb shell uname -a"
}

cmd_verify() {
    banner
    check_kernel
    echo ""
    echo -e "${BLUE}ℹ️  Verificando kernel...${NC}"
    file "$KERNEL"
    
    echo ""
    echo -e "${BLUE}ℹ️  Tamanho:${NC}"
    ls -lh "$KERNEL"
    
    echo ""
    echo -e "${BLUE}ℹ️  Versão (strings):${NC}"
    strings "$KERNEL" | grep "Linux version" | head -1 || echo "Não disponível"
}

# Main
case "${1:-}" in
    test) cmd_test ;;
    flash) cmd_flash ;;
    backup) cmd_backup ;;
    verify) cmd_verify ;;
    *) usage ;;
esac
