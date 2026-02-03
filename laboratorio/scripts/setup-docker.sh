#!/bin/bash
# 🐳 setup-docker.sh - Setup Automático do Docker
# DevSan AGI - Configura ambiente Docker para build do kernel moonstone

set -e

LAB_DIR="/home/deivi/Projetos/Android16-Kernel/laboratorio"
KERNEL_SOURCE="/home/deivi/Projetos/Android16-Kernel/kernel-moonstone-devs"

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}╔══════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  🐳 DevSan Docker Setup - Moonstone Kernel Build       ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════════════╝${NC}"
echo ""

# Função de log
log() {
    echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1"
}

# Função de sucesso
success() {
    echo -e "${GREEN}✅ $1${NC}"
}

# Função de aviso
warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

# Função de erro
error() {
    echo -e "${RED}❌ $1${NC}"
}

# 1. Verificar Docker instalado
log "1️⃣ Verificando Docker..."
if ! command -v docker &> /dev/null; then
    error "Docker não instalado!"
    log "📦 Instalando Docker..."
    sudo pacman -S docker docker-compose
    sudo systemctl enable --now docker
    sudo usermod -aG docker $USER
    warning "Desconecte e reconecte para aplicar permissões de Docker!"
    exit 1
else
    success "Docker instalado: $(docker --version)"
fi

# 2. Verificar Docker rodando
log "2️⃣ Verificando se Docker está rodando..."
if ! docker info &> /dev/null; then
    log "🚀 Iniciando Docker..."
    sudo systemctl start docker
    success "Docker iniciado"
else
    success "Docker já está rodando"
fi

# 3. Verificar kernel source
log "3️⃣ Verificando kernel source..."
if [ ! -d "$KERNEL_SOURCE" ]; then
    error "Kernel source não encontrado: $KERNEL_SOURCE"
    exit 1
else
    success "Kernel source encontrado"
    log "   $KERNEL_SOURCE"
fi

# 4. Verificar laboratório
log "4️⃣ Verificando estrutura do laboratório..."
mkdir -p "$LAB_DIR"/{out,logs,scripts,cache}
success "Laboratório criado"

# 5. Criar scripts auxiliares
log "5️⃣ Criando scripts auxiliares..."

# Criar diretório de scripts
mkdir -p "$LAB_DIR/scripts"

# Verificar scripts existentes
if [ ! -x "$LAB_DIR/scripts/validate-build.sh" ]; then
    error "Script validate-build.sh não encontrado!"
    exit 1
fi

if [ ! -x "$LAB_DIR/scripts/apply-fixes.sh" ]; then
    error "Script apply-fixes.sh não encontrado!"
    exit 1
fi

success "Scripts auxiliares prontos"

# 6. Verificar docker-compose
log "6️⃣ Verificando docker-compose..."
if [ ! -f "$LAB_DIR/docker-compose.yml" ]; then
    error "docker-compose.yml não encontrado!"
    exit 1
else
    success "docker-compose.yml encontrado"
fi

# 7. Verificar Dockerfile
log "7️⃣ Verificando Dockerfile..."
if [ ! -f "$LAB_DIR/Dockerfile" ]; then
    error "Dockerfile não encontrado!"
    exit 1
else
    success "Dockerfile encontrado"
fi

# 8. Criar ccache
log "8️⃣ Configurando ccache..."
mkdir -p "$HOME/.ccache"
cat > "$HOME/.ccache/ccache.conf" << EOF
max_size = 50G
compression = true
umask = 002
stats_log = true
EOF
success "ccache configurado"

# 9. Verificar espaço em disco
log "9️⃣ Verificando espaço em disco..."
SPACE_AVAILABLE=$(df -BG "$LAB_DIR/out" | tail -1 | awk '{print $4}')
if [ "$SPACE_AVAILABLE" -lt 50 ]; then
    error "Espaço insuficiente (${SPACE_AVAILABLE}GB < 50GB)"
    exit 1
else
    success "Espaço OK (${SPACE_AVAILABLE}GB disponíveis)"
fi

# 10. Resumo
log ""
log "📊 Setup completo! Resumo:"
log "   ✅ Docker instalado e rodando"
log "   ✅ Kernel source: $KERNEL_SOURCE"
log "   ✅ Laboratório: $LAB_DIR"
log "   ✅ Scripts auxiliares prontos"
log "   ✅ ccache configurado"
log "   ✅ Espaço: ${SPACE_AVAILABLE}GB"
log ""
success "🎉 SETUP CONCLUÍDO! 🎉"
log ""
log "🚀 Próximos passos:"
log "   1. cd $LAB_DIR"
log "   2. ./build-moonstone-docker.sh"
log ""
log "💡 Ou para entrar no container manualmente:"
log "   cd $LAB_DIR"
log "   docker-compose up -d"
log "   docker-compose exec kernel-build bash"
log ""
exit 0
