#!/bin/bash

# Script para deploy em produção do Gwan Cache
# Autor: Gwan Cache Administration

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Função para logging
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

warn() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] WARNING: $1${NC}"
}

error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $1${NC}"
}

info() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')] INFO: $1${NC}"
}

# Verificar se estamos no ambiente correto
check_environment() {
    log "Verificando ambiente de produção..."
    
    if [ "$NODE_ENV" != "production" ]; then
        warn "NODE_ENV não está definido como 'production'"
        read -p "Continuar mesmo assim? (s/N): " confirm
        if [[ ! "$confirm" =~ ^[Ss]$ ]]; then
            error "Deploy cancelado"
            exit 1
        fi
    fi
    
    # Verificar se o arquivo .env.prod existe
    if [ ! -f .env.prod ]; then
        error "Arquivo .env.prod não encontrado!"
        info "Copie env.prod.example para .env.prod e configure as variáveis"
        exit 1
    fi
    
    log "Ambiente de produção verificado ✓"
}

# Verificar dependências
check_dependencies() {
    log "Verificando dependências..."
    
    # Verificar Docker
    if ! command -v docker &> /dev/null; then
        error "Docker não está instalado"
        exit 1
    fi
    
    # Verificar Docker Compose
    if ! command -v docker-compose &> /dev/null; then
        error "Docker Compose não está instalado"
        exit 1
    fi
    
    # Verificar se Docker está rodando
    if ! docker info > /dev/null 2>&1; then
        error "Docker não está rodando"
        exit 1
    fi
    
    # Verificar se a rede gwan existe
    if ! docker network ls | grep -q "gwan"; then
        error "Rede 'gwan' não encontrada"
        info "Crie a rede com: docker network create gwan"
        exit 1
    fi
    
    log "Dependências verificadas ✓"
}

# Fazer backup antes do deploy
backup_before_deploy() {
    log "Fazendo backup antes do deploy..."
    
    # Verificar se há containers rodando
    if docker-compose -f docker-compose.prod.yml ps | grep -q "Up"; then
        info "Containers de produção encontrados, fazendo backup..."
        
        # Criar diretório de backup se não existir
        mkdir -p backups/prod
        
        # Backup do Redis
        if docker-compose -f docker-compose.prod.yml exec -T redis redis-cli ping > /dev/null 2>&1; then
            TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
            docker-compose -f docker-compose.prod.yml exec -T redis redis-cli bgsave
            sleep 5
            docker cp gwan-cache-redis-prod:/data/dump.rdb "backups/prod/redis_backup_${TIMESTAMP}.rdb"
            gzip "backups/prod/redis_backup_${TIMESTAMP}.rdb"
            log "Backup do Redis criado: backups/prod/redis_backup_${TIMESTAMP}.rdb.gz"
        else
            warn "Redis não está respondendo, pulando backup"
        fi
    else
        info "Nenhum container de produção rodando, pulando backup"
    fi
}

# Deploy dos containers
deploy_containers() {
    log "Iniciando deploy dos containers..."
    
    # Parar containers existentes
    info "Parando containers existentes..."
    docker-compose -f docker-compose.prod.yml --env-file .env.prod down
    
    # Pull das imagens mais recentes
    info "Atualizando imagens..."
    docker-compose -f docker-compose.prod.yml --env-file .env.prod pull
    
    # Iniciar containers
    info "Iniciando containers de produção..."
    docker-compose -f docker-compose.prod.yml --env-file .env.prod up -d
    
    log "Containers deployados ✓"
}

# Verificar saúde dos serviços
check_health() {
    log "Verificando saúde dos serviços..."
    
    # Aguardar containers ficarem prontos
    sleep 10
    
    # Verificar Redis
    if docker-compose -f docker-compose.prod.yml --env-file .env.prod exec -T redis redis-cli ping | grep -q "PONG"; then
        log "Redis está funcionando ✓"
    else
        error "Redis não está respondendo"
        return 1
    fi
    
    # Verificar Redis Commander
    if curl -s -f http://localhost:8081 > /dev/null 2>&1; then
        log "Redis Commander está acessível ✓"
    else
        warn "Redis Commander não está acessível localmente"
    fi
    
    # Verificar Redis Insight
    if curl -s -f http://localhost:8001 > /dev/null 2>&1; then
        log "Redis Insight está acessível ✓"
    else
        warn "Redis Insight não está acessível localmente"
    fi
    
    log "Verificação de saúde concluída ✓"
}

# Mostrar informações do deploy
show_deploy_info() {
    log "Deploy concluído com sucesso!"
    echo ""
    echo "📋 Informações do Deploy:"
    echo "========================="
    echo "🌐 Domínio: https://cache.gwan.com.br"
    echo "📊 Redis Commander: https://cache.gwan.com.br/commander"
    echo "🔍 Redis Insight: https://cache.gwan.com.br/insight"
    echo "📈 Dashboard: https://cache.gwan.com.br"
    echo ""
    echo "🔧 Comandos úteis:"
    echo "   • Status: docker-compose -f docker-compose.prod.yml ps"
    echo "   • Logs: docker-compose -f docker-compose.prod.yml logs -f"
    echo "   • Parar: docker-compose -f docker-compose.prod.yml down"
    echo "   • Reiniciar: docker-compose -f docker-compose.prod.yml restart"
    echo ""
    echo "📊 Monitoramento:"
    echo "   • Health Check: ./scripts/health-check-prod.sh"
    echo "   • Backup: ./scripts/backup-prod.sh"
    echo "   • Monitor: ./scripts/monitor-prod.sh"
    echo ""
}

# Função principal
main() {
    echo "🚀 Deploy do Gwan Cache - Produção"
    echo "=================================="
    echo ""
    
    check_environment
    check_dependencies
    backup_before_deploy
    deploy_containers
    check_health
    show_deploy_info
    
    log "Deploy concluído com sucesso! 🎉"
}

# Executar função principal
main "$@"
