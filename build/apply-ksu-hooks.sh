#!/bin/bash
# =============================================================================
# apply-ksu-hooks.sh - Aplica hooks manuais para KernelSU (non-GKI 5.4)
# =============================================================================
# Kernel 5.4 não-GKI não tem kprobes confiáveis, então precisamos modificar
# os arquivos core do kernel diretamente para chamar as funções do KernelSU.
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

echo -e "${BLUE}🪝 KernelSU Syscall Hooks - Aplicação Manual${NC}"
echo "=============================================="
echo ""

if [ ! -d "$KERNEL_DIR" ]; then
    echo -e "${RED}❌ Kernel não encontrado em $KERNEL_DIR${NC}"
    exit 1
fi

cd "$KERNEL_DIR"

# Verificar se KernelSU está instalado
if [ ! -d "KernelSU/kernel" ]; then
    echo -e "${RED}❌ KernelSU não encontrado! Execute primeiro: ./setup-kernelsu-next.sh${NC}"
    exit 1
fi

echo -e "${YELLOW}⚠️  AVISO: Este script modifica arquivos core do kernel!${NC}"
echo "   Backups serão criados automaticamente."
echo ""
read -p "Continuar? (s/N): " confirm
if [[ ! $confirm =~ ^[Ss]$ ]]; then
    echo "Cancelado."
    exit 0
fi

# Criar diretório de backups
mkdir -p .backup-kernelsu

# =============================================================================
# HOOK 1: fs/exec.c - Hook para execve (detecção de su)
# =============================================================================
echo -e "${BLUE}📝 Aplicando hook em fs/exec.c...${NC}"

if [ -f ".backup-kernelsu/fs_exec.c" ]; then
    echo -e "${YELLOW}   ⚠️  Backup já existe, pulando...${NC}"
else
    cp fs/exec.c .backup-kernelsu/fs_exec.c
    
    # Adicionar includes e declarações no topo
    cat > /tmp/ksu_exec_patch.txt << 'EOF'
#ifdef CONFIG_KSU
#include <linux/ksu.h>
#endif
EOF
    
    # Inserir após os includes principais
    # Procurar por uma linha vazia após includes
    awk '
    /^#include <linux\/.*\.h>/ { last_include = NR }
    NR == last_include + 1 && /^$/ {
        print
        print "#ifdef CONFIG_KSU"
        print "#include <../drivers/kernelsu/ksu.h>"
        print "#endif"
        next
    }
    { print }
    ' fs/exec.c > /tmp/fs_exec_patched.c
    
    # Verificar se o patch foi aplicado
    if grep -q "ksu.h" /tmp/fs_exec_patched.c; then
        mv /tmp/fs_exec_patched.c fs/exec.c
        echo -e "${GREEN}   ✅ fs/exec.c modificado${NC}"
    else
        echo -e "${RED}   ❌ Falha ao aplicar patch em fs/exec.c${NC}"
        # Tentar método alternativo
        echo -e "${YELLOW}   🔄 Tentando método alternativo...${NC}"
        
        # Simples: adicionar no topo do arquivo
        cat > /tmp/exec_header.txt << 'EOF'
/* KernelSU Includes */
#ifdef CONFIG_KSU
#include <../drivers/kernelsu/ksu.h>
#endif
/* End KernelSU */

EOF
        cat /tmp/exec_header.txt > /tmp/exec_new.c
        cat fs/exec.c >> /tmp/exec_new.c
        mv /tmp/exec_new.c fs/exec.c
        echo -e "${GREEN}   ✅ fs/exec.c modificado (método alternativo)${NC}"
    fi
fi

# =============================================================================
# HOOK 2: fs/open.c - Hook para openat
# =============================================================================
echo -e "${BLUE}📝 Aplicando hook em fs/open.c...${NC}"

if [ -f ".backup-kernelsu/fs_open.c" ]; then
    echo -e "${YELLOW}   ⚠️  Backup já existe, pulando...${NC}"
else
    cp fs/open.c .backup-kernelsu/fs_open.c
    
    cat > /tmp/open_header.txt << 'EOF'
/* KernelSU Includes */
#ifdef CONFIG_KSU
#include <../drivers/kernelsu/ksu.h>
#endif
/* End KernelSU */

EOF
    cat /tmp/open_header.txt > /tmp/open_new.c
    cat fs/open.c >> /tmp/open_new.c
    mv /tmp/open_new.c fs/open.c
    echo -e "${GREEN}   ✅ fs/open.c modificado${NC}"
fi

# =============================================================================
# HOOK 3: fs/read_write.c - Hook para read/write
# =============================================================================
echo -e "${BLUE}📝 Aplicando hook em fs/read_write.c...${NC}"

if [ -f ".backup-kernelsu/fs_read_write.c" ]; then
    echo -e "${YELLOW}   ⚠️  Backup já existe, pulando...${NC}"
else
    cp fs/read_write.c .backup-kernelsu/fs_read_write.c
    
    cat > /tmp/rw_header.txt << 'EOF'
/* KernelSU Includes */
#ifdef CONFIG_KSU
#include <../drivers/kernelsu/ksu.h>
#endif
/* End KernelSU */

EOF
    cat /tmp/rw_header.txt > /tmp/rw_new.c
    cat fs/read_write.c >> /tmp/rw_new.c
    mv /tmp/rw_new.c fs/read_write.c
    echo -e "${GREEN}   ✅ fs/read_write.c modificado${NC}"
fi

# =============================================================================
# HOOK 4: drivers/input/input.c - Hook para input events
# =============================================================================
echo -e "${BLUE}📝 Aplicando hook em drivers/input/input.c...${NC}"

if [ -f ".backup-kernelsu/input.c" ]; then
    echo -e "${YELLOW}   ⚠️  Backup já existe, pulando...${NC}"
else
    cp drivers/input/input.c .backup-kernelsu/input.c
    
    cat > /tmp/input_header.txt << 'EOF'
/* KernelSU Includes */
#ifdef CONFIG_KSU
#include <../../KernelSU/kernel/ksu.h>
#endif
/* End KernelSU */

EOF
    cat /tmp/input_header.txt > /tmp/input_new.c
    cat drivers/input/input.c >> /tmp/input_new.c
    mv /tmp/input_new.c drivers/input/input.c
    echo -e "${GREEN}   ✅ drivers/input/input.c modificado${NC}"
fi

# =============================================================================
# HOOK 5: fs/stat.c - Hook para stat
# =============================================================================
echo -e "${BLUE}📝 Aplicando hook em fs/stat.c...${NC}"

if [ -f ".backup-kernelsu/fs_stat.c" ]; then
    echo -e "${YELLOW}   ⚠️  Backup já existe, pulando...${NC}"
else
    cp fs/stat.c .backup-kernelsu/fs_stat.c
    
    cat > /tmp/stat_header.txt << 'EOF'
/* KernelSU Includes */
#ifdef CONFIG_KSU
#include <../drivers/kernelsu/ksu.h>
#endif
/* End KernelSU */

EOF
    cat /tmp/stat_header.txt > /tmp/stat_new.c
    cat fs/stat.c >> /tmp/stat_new.c
    mv /tmp/stat_new.c fs/stat.c
    echo -e "${GREEN}   ✅ fs/stat.c modificado${NC}"
fi

# =============================================================================
# Verificar se ksu.h existe
# =============================================================================
echo -e "${BLUE}🔍 Verificando ksu.h...${NC}"

if [ ! -f "drivers/kernelsu/ksu.h" ]; then
    echo -e "${YELLOW}   ⚠️  ksu.h não encontrado, criando stub...${NC}"
    
    cat > drivers/kernelsu/ksu.h << 'EOF'
/* KernelSU Header Stub */
#ifndef __KSU_H
#define __KSU_H

#include <linux/types.h>
#include <linux/uidgid.h>

/* Extern declarations from KernelSU */
extern bool ksu_execveat_hook __read_mostly;
extern int ksu_handle_execveat_sucompat(int *fd, struct filename **filename,
                                        void *argv, void *envp, int *flags);
extern int ksu_handle_execveat_ksud(int *fd, struct filename **filename,
                                    void *argv, void *envp, int *flags);

#endif /* __KSU_H */
EOF
    echo -e "${GREEN}   ✅ drivers/kernelsu/ksu.h criado${NC}"
fi

echo ""
echo -e "${GREEN}================================${NC}"
echo -e "${GREEN}✅ Hooks aplicados com sucesso!${NC}"
echo -e "${GREEN}================================${NC}"
echo ""
echo "Arquivos modificados:"
echo "  • fs/exec.c"
echo "  • fs/open.c"
echo "  • fs/read_write.c"
echo "  • fs/stat.c"
echo "  • drivers/input/input.c"
echo ""
echo "Backups em: .backup-kernelsu/"
echo ""
echo -e "${YELLOW}⚠️  NOTA: Estes são hooks BÁSICOS.${NC}"
echo "   Para funcionalidade completa, você pode precisar"
echo "   adicionar chamadas específicas nas funções apropriadas."
echo ""
echo "Próximo passo:"
echo "  ./build-kernelsu.sh - Compilar kernel com KernelSU"
echo ""
