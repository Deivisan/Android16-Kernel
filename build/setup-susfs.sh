#!/bin/bash
# =============================================================================
# setup-susfs.sh - Integração SUSFS ao kernel (root hiding avançado)
# =============================================================================
# SUSFS adiciona patches de kernel para ocultar root de apps de detecção
# =============================================================================

set -e

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Diretórios
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
KERNEL_DIR="${SCRIPT_DIR}/../kernel-moonstone-devs"
SUSFS_DIR="${SCRIPT_DIR}/../susfs4ksu"

echo -e "${BLUE}🛡️  SUSFS Setup Script${NC}"
echo "======================"
echo ""

if [ ! -d "$KERNEL_DIR" ]; then
    echo -e "${RED}❌ Kernel não encontrado em $KERNEL_DIR${NC}"
    exit 1
fi

cd "$KERNEL_DIR"

# Verificar se KernelSU está instalado
if [ ! -d "KernelSU" ]; then
    echo -e "${RED}❌ KernelSU não encontrado! Execute primeiro: ./setup-kernelsu-next.sh${NC}"
    exit 1
fi

# =============================================================================
# Clonar susfs4ksu
# =============================================================================
echo -e "${BLUE}📦 Clonando susfs4ksu...${NC}"

if [ ! -d "$SUSFS_DIR" ]; then
    cd "${SCRIPT_DIR}/.."
    git clone --depth=1 https://gitlab.com/simonpunk/susfs4ksu.git
    echo -e "${GREEN}   ✅ susfs4ksu clonado${NC}"
else
    echo -e "${YELLOW}   ⚠️  susfs4ksu já existe, atualizando...${NC}"
    cd "$SUSFS_DIR"
    git pull || true
    echo -e "${GREEN}   ✅ susfs4ksu atualizado${NC}"
fi

# Verificar estrutura
if [ ! -d "$SUSFS_DIR/kernel_patches" ]; then
    echo -e "${RED}❌ Estrutura do susfs4ksu incorreta${NC}"
    exit 1
fi

cd "$KERNEL_DIR"

# =============================================================================
# Copiar arquivos SUSFS
# =============================================================================
echo -e "${BLUE}📂 Copiando arquivos SUSFS para o kernel...${NC}"

# Criar backup
mkdir -p .backup-susfs

# Copiar fs/
if [ -d "$SUSFS_DIR/kernel_patches/fs" ]; then
    echo "   Copiando arquivos fs/..."
    for file in "$SUSFS_DIR/kernel_patches/fs"/*; do
        if [ -f "$file" ]; then
            filename=$(basename "$file")
            if [ -f "fs/$filename" ]; then
                cp "fs/$filename" ".backup-susfs/fs_$filename.bak"
            fi
            cp "$file" "fs/"
            echo "     ✓ $filename"
        fi
    done
fi

# Copiar include/linux/
if [ -d "$SUSFS_DIR/kernel_patches/include/linux" ]; then
    echo "   Copiando arquivos include/linux/..."
    for file in "$SUSFS_DIR/kernel_patches/include/linux"/*; do
        if [ -f "$file" ]; then
            filename=$(basename "$file")
            if [ -f "include/linux/$filename" ]; then
                cp "include/linux/$filename" ".backup-susfs/include_$filename.bak"
            fi
            cp "$file" "include/linux/"
            echo "     ✓ $filename"
        fi
    done
fi

# =============================================================================
# Aplicar patches
# =============================================================================
echo -e "${BLUE}🔧 Aplicando patches SUSFS...${NC}"

# Listar patches disponíveis
echo "   Patches disponíveis:"
ls -1 "$SUSFS_DIR/kernel_patches/"*.patch 2>/dev/null | while read patch; do
    echo "     • $(basename "$patch")"
done

# Tentar encontrar patch apropriado para 5.4
PATCH_FILE=""

# Verificar patches específicos
if [ -f "$SUSFS_DIR/kernel_patches/50_add_susfs_in_gki-android12-5.4.patch" ]; then
    PATCH_FILE="$SUSFS_DIR/kernel_patches/50_add_susfs_in_gki-android12-5.4.patch"
elif [ -f "$SUSFS_DIR/kernel_patches/50_add_susfs_in_gki-android13-5.4.patch" ]; then
    PATCH_FILE="$SUSFS_DIR/kernel_patches/50_add_susfs_in_gki-android13-5.4.patch"
elif [ -f "$SUSFS_DIR/kernel_patches/50_add_susfs_in_gki-android14-5.4.patch" ]; then
    PATCH_FILE="$SUSFS_DIR/kernel_patches/50_add_susfs_in_gki-android14-5.4.patch"
else
    # Usar patch genérico de 5.4 ou 5.10
    PATCH_FILE=$(ls "$SUSFS_DIR/kernel_patches/"*5.4*.patch 2>/dev/null | head -1 || true)
    if [ -z "$PATCH_FILE" ]; then
        PATCH_FILE=$(ls "$SUSFS_DIR/kernel_patches/"*5.10*.patch 2>/dev/null | head -1 || true)
    fi
fi

if [ -n "$PATCH_FILE" ] && [ -f "$PATCH_FILE" ]; then
    echo "   Aplicando: $(basename "$PATCH_FILE")"
    
    # Tentar aplicar patch
    if patch -p1 --dry-run -i "$PATCH_FILE" > /tmp/susfs_patch.log 2>&1; then
        patch -p1 -i "$PATCH_FILE"
        echo -e "${GREEN}   ✅ Patch aplicado com sucesso${NC}"
    else
        echo -e "${YELLOW}   ⚠️  Patch falhou no dry-run, verificando erros...${NC}"
        cat /tmp/susfs_patch.log
        
        echo ""
        echo -e "${YELLOW}   Tentando aplicar com fuzzy matching...${NC}"
        if patch -p1 -f --fuzz=3 -i "$PATCH_FILE" > /tmp/susfs_patch_fuzzy.log 2>&1; then
            echo -e "${GREEN}   ✅ Patch aplicado com fuzzy matching${NC}"
        else
            echo -e "${RED}   ❌ Falha ao aplicar patch${NC}"
            echo "   Erro salvo em: /tmp/susfs_patch_fuzzy.log"
            echo ""
            echo -e "${YELLOW}   ⚠️  SUSFS requer integração manual para este kernel${NC}"
            echo "   Verifique os arquivos copiados e faça ajustes manuais."
        fi
    fi
else
    echo -e "${YELLOW}   ⚠️  Nenhum patch específico encontrado para kernel 5.4${NC}"
    echo "   Arquivos foram copiados, mas patches podem precisar de ajustes manuais."
fi

# Aplicar patch de hooks minimizados (se existir)
if [ -f "$SUSFS_DIR/kernel_patches/60_scope-minimized_manual_hooks.patch" ]; then
    echo "   Aplicando: 60_scope-minimized_manual_hooks.patch"
    if patch -p1 --dry-run -i "$SUSFS_DIR/kernel_patches/60_scope-minimized_manual_hooks.patch" > /dev/null 2>&1; then
        patch -p1 -i "$SUSFS_DIR/kernel_patches/60_scope-minimized_manual_hooks.patch"
        echo -e "${GREEN}   ✅ Hooks minimizados aplicados${NC}"
    else
        echo -e "${YELLOW}   ⚠️  Patch de hooks falhou (pode não ser necessário)${NC}"
    fi
fi

# =============================================================================
# Configurar defconfig
# =============================================================================
echo -e "${BLUE}⚙️  Configurando defconfig para SUSFS...${NC}"

DEFCONFIG="arch/arm64/configs/moonstone_defconfig"

# Adicionar configs SUSFS
SUSFS_CONFIGS='
# SUSFS Support
CONFIG_KSU_SUSFS=y
CONFIG_KSU_SUSFS_SUS_PATH=y
CONFIG_KSU_SUSFS_SUS_MOUNT=y
CONFIG_KSU_SUSFS_SUS_KSTAT=y
CONFIG_KSU_SUSFS_SUS_OVERLAYFS=y
CONFIG_KSU_SUSFS_SUS_MOUNT_MNT_ID=y
CONFIG_KSU_SUSFS_HIDE_KSU=y
'

if ! grep -q "CONFIG_KSU_SUSFS" "$DEFCONFIG"; then
    echo "$SUSFS_CONFIGS" >> "$DEFCONFIG"
    echo -e "${GREEN}   ✅ Configs SUSFS adicionadas${NC}"
else
    echo -e "${YELLOW}   ⚠️  Configs SUSFS já existem${NC}"
fi

# =============================================================================
# Instalar módulo SUSFS (para userspace)
# =============================================================================
echo ""
echo -e "${BLUE}📱 Nota sobre módulo SUSFS:${NC}"
echo "   O módulo SUSFS para userspace deve ser instalado via KernelSU Manager"
echo "   após o kernel ser flashado."
echo ""
echo "   Download: https://github.com/sidex15/susfs4ksu-module/releases"

echo ""
echo -e "${GREEN}================================${NC}"
echo -e "${GREEN}✅ SUSFS Setup concluído!${NC}"
echo -e "${Green}================================${NC}"
echo ""
echo "Arquivos copiados:"
echo "  • fs/susfs*.c"
echo "  • include/linux/susfs*.h"
echo ""
echo "Configs adicionadas ao defconfig:"
echo "  • CONFIG_KSU_SUSFS=y"
echo "  • CONFIG_KSU_SUSFS_SUS_PATH=y"
echo "  • CONFIG_KSU_SUSFS_SUS_MOUNT=y"
echo "  • CONFIG_KSU_SUSFS_SUS_KSTAT=y"
echo "  • CONFIG_KSU_SUSFS_SUS_OVERLAYFS=y"
echo ""
echo "Próximo passo:"
echo "  ./build-kernelsu.sh - Compilar kernel completo"
echo ""
