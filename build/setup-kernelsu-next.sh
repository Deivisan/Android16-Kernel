#!/bin/bash
# =============================================================================
# setup-kernelsu-next.sh - Integração KernelSU-Next ao kernel 5.4.302
# =============================================================================
# Uso: ./setup-kernelsu-next.sh [opções]
# Opções:
#   --manual    - Usar método manual (recomendado para 5.4)
#   --auto      - Tentar método automático (pode falhar em 5.4)
#   --clean     - Limpar integração anterior
# =============================================================================

set -e

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Diretórios
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
KERNEL_DIR="${SCRIPT_DIR}/../kernel-moonstone-devs"
LAB_DIR="${SCRIPT_DIR}/../lab-kernelsu"

echo -e "${BLUE}🛡️  KernelSU-Next Setup Script${NC}"
echo "================================"

# Verificar kernel source
if [ ! -d "$KERNEL_DIR" ]; then
    echo -e "${RED}❌ Erro: Kernel source não encontrado em $KERNEL_DIR${NC}"
    echo "   Clone o kernel primeiro:"
    echo "   git clone https://github.com/moonstone-devs/android_kernel_moonstone.git $KERNEL_DIR"
    exit 1
fi

# Parse argumentos
METHOD="manual"
CLEAN=0

while [[ $# -gt 0 ]]; do
    case $1 in
        --manual)
            METHOD="manual"
            shift
            ;;
        --auto)
            METHOD="auto"
            shift
            ;;
        --clean)
            CLEAN=1
            shift
            ;;
        --help)
            echo "Uso: $0 [opções]"
            echo ""
            echo "Opções:"
            echo "  --manual    Método manual (recomendado para kernel 5.4)"
            echo "  --auto      Método automático via script oficial"
            echo "  --clean     Remover integração anterior"
            echo "  --help      Mostrar esta ajuda"
            exit 0
            ;;
        *)
            echo -e "${RED}❌ Opção desconhecida: $1${NC}"
            exit 1
            ;;
    esac
done

# Limpar se solicitado
if [ $CLEAN -eq 1 ]; then
    echo -e "${YELLOW}🧹 Limpando integração anterior...${NC}"
    cd "$KERNEL_DIR"
    
    # Remover KernelSU
    if [ -d "KernelSU" ]; then
        rm -rf KernelSU
        echo "   ✓ Removido KernelSU/"
    fi
    
    # Remover drivers/kernelsu
    if [ -d "drivers/kernelsu" ]; then
        rm -rf drivers/kernelsu
        echo "   ✓ Removido drivers/kernelsu/"
    fi
    
    # Remover arquivos SUSFS
    if [ -f "fs/susfs.c" ]; then
        # Restaurar fs/ do git
        git checkout -- fs/ 2>/dev/null || true
        echo "   ✓ Restaurado fs/"
    fi
    
    # Remover configs
    sed -i '/# KernelSU/d' arch/arm64/configs/moonstone_defconfig
    sed -i '/CONFIG_KSU/d' arch/arm64/configs/moonstone_defconfig
    echo "   ✓ Removidas configs KSU"
    
    echo -e "${GREEN}✅ Limpeza completa!${NC}"
    exit 0
fi

# Criar diretório de laboratório
if [ ! -d "$LAB_DIR" ]; then
    echo -e "${BLUE}📁 Criando workspace de laboratório...${NC}"
    mkdir -p "$LAB_DIR"
fi

cd "$KERNEL_DIR"

echo -e "${BLUE}🔧 Kernel encontrado em: $KERNEL_DIR${NC}"
echo ""

# =============================================================================
# MÉTODO 1: AUTOMÁTICO (via script oficial)
# =============================================================================
if [ "$METHOD" == "auto" ]; then
    echo -e "${YELLOW}🚀 Usando método AUTOMÁTICO...${NC}"
    echo "   Baixando script oficial do KernelSU-Next..."
    
    # Tentar script oficial
    if curl -LSs "https://raw.githubusercontent.com/KernelSU-Next/KernelSU-Next/refs/heads/next/kernel/setup.sh" | bash -s next; then
        echo -e "${GREEN}✅ Script automático executado com sucesso!${NC}"
    else
        echo -e "${RED}❌ Script automático falhou (esperado para kernel 5.4)${NC}"
        echo "   Mudando para método manual..."
        METHOD="manual"
    fi
fi

# =============================================================================
# MÉTODO 2: MANUAL (recomendado para 5.4)
# =============================================================================
if [ "$METHOD" == "manual" ]; then
    echo -e "${YELLOW}🔨 Usando método MANUAL (recomendado para 5.4)...${NC}"
    echo ""
    
    # ---- Passo 1: Clonar KernelSU-Next ----
    echo -e "${BLUE}📦 Passo 1: Clonando KernelSU-Next...${NC}"
    
    if [ -d "KernelSU" ]; then
        echo -e "${YELLOW}   ⚠️  KernelSU já existe. Atualizando...${NC}"
        cd KernelSU
        git fetch origin
        git checkout next || git checkout main
        cd ..
    else
        git clone -b next --depth=1 https://github.com/KernelSU-Next/KernelSU-Next.git KernelSU
    fi
    
    if [ ! -d "KernelSU/kernel" ]; then
        echo -e "${RED}❌ Erro: Estrutura do KernelSU incorreta${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}   ✅ KernelSU-Next clonado${NC}"
    
    # ---- Passo 2: Criar link simbólico em drivers/ ----
    echo -e "${BLUE}🔗 Passo 2: Configurando drivers/kernelsu...${NC}"
    
    if [ -d "drivers/kernelsu" ]; then
        rm -f drivers/kernelsu
    fi
    
    ln -sf ../KernelSU/kernel drivers/kernelsu
    echo -e "${GREEN}   ✅ Link criado: drivers/kernelsu -> KernelSU/kernel${NC}"
    
    # ---- Passo 3: Modificar Makefile de drivers ----
    echo -e "${BLUE}📝 Passo 3: Modificando drivers/Makefile...${NC}"
    
    if ! grep -q "kernelsu" drivers/Makefile; then
        echo -e "\n# KernelSU\nobj-\$(CONFIG_KSU) += kernelsu/" >> drivers/Makefile
        echo -e "${GREEN}   ✅ drivers/Makefile modificado${NC}"
    else
        echo -e "${YELLOW}   ⚠️  drivers/Makefile já contém kernelsu${NC}"
    fi
    
    # ---- Passo 4: Modificar Makefile principal ----
    echo -e "${BLUE}📝 Passo 4: Configurando Makefile principal...${NC}"
    
    # Adicionar ao Kconfig se necessário
    if [ ! -f "KernelSU/Kconfig" ]; then
        cat > KernelSU/Kconfig << 'EOF'
config KSU
	bool "KernelSU - Kernel-based root solution"
	default y
	help
	  KernelSU is a kernel-based root solution for Android devices.
	  It provides root access management and module support.

config KSU_DEBUG
	bool "KernelSU debug mode"
	default n
	depends on KSU
	help
	  Enable debug output for KernelSU.
EOF
        echo -e "${GREEN}   ✅ KernelSU/Kconfig criado${NC}"
    fi
    
    # ---- Passo 5: Configurar defconfig ----
    echo -e "${BLUE}⚙️  Passo 5: Configurando defconfig...${NC}"
    
    DEFCONFIG="arch/arm64/configs/moonstone_defconfig"
    
    if ! grep -q "CONFIG_KSU=y" "$DEFCONFIG"; then
        cat >> "$DEFCONFIG" << 'EOF'

# KernelSU-Next Support
CONFIG_KSU=y
CONFIG_KSU_DEBUG=n
EOF
        echo -e "${GREEN}   ✅ Configs KSU adicionadas ao defconfig${NC}"
    else
        echo -e "${YELLOW}   ⚠️  Configs KSU já existem${NC}"
    fi
    
    # ---- Passo 6: Backup e preparação de hooks ----
    echo -e "${BLUE}💾 Passo 6: Preparando para hooks manuais...${NC}"
    
    # Criar diretório para backups
    mkdir -p "$LAB_DIR/backups"
    
    # Backup de arquivos que serão modificados
    cp fs/exec.c "$LAB_DIR/backups/fs_exec.c.bak" 2>/dev/null || true
    cp fs/open.c "$LAB_DIR/backups/fs_open.c.bak" 2>/dev/null || true
    cp fs/read_write.c "$LAB_DIR/backups/fs_read_write.c.bak" 2>/dev/null || true
    cp drivers/input/input.c "$LAB_DIR/backups/input.c.bak" 2>/dev/null || true
    
    echo -e "${GREEN}   ✅ Backups criados em $LAB_DIR/backups/${NC}"
    
    echo ""
    echo -e "${YELLOW}⚠️  ATENÇÃO: Hooks de syscall precisam ser aplicados manualmente!${NC}"
    echo "   Execute o próximo script: ./apply-ksu-hooks.sh"
fi

echo ""
echo -e "${GREEN}================================${NC}"
echo -e "${GREEN}✅ Setup KernelSU-Next concluído!${NC}"
echo -e "${GREEN}================================${NC}"
echo ""
echo "Próximos passos:"
echo "  1. ./apply-ksu-hooks.sh     - Aplicar hooks de syscall"
echo "  2. ./setup-susfs.sh         - Adicionar SUSFS (opcional)"
echo "  3. ./build-kernelsu.sh      - Compilar kernel"
echo ""
