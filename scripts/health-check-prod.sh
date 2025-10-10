#!/bin/bash

# Script de verificação de saúde do Redis em produção
# Autor: Gwan Cache Administration

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
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

# Verificar se Docker está rodando
check_docker() {
    log "Verificando Docker..."
    if ! docker info > /dev/null 2>&1; then
        error "Docker não está rodando"
        return 1
    fi
    log "Docker está rodando ✓"
}

# Verificar se os containers estão rodando
check_containers() {
    log "Verificando containers de produção..."
    
    # Verificar Redis
    if ! docker-compose -f docker-compose.prod.yml --env-file .env.prod ps redis | grep -q "Up"; then
        error "Container Redis não está rodando"
        return 1
    fi
    log "Container Redis está rodando ✓"
    
    # Verificar Redis Commander
    if ! docker-compose -f docker-compose.prod.yml --env-file .env.prod ps redis-commander | grep -q "Up"; then
        warn "Container Redis Commander não está rodando"
    else
        log "Container Redis Commander está rodando ✓"
    fi
    
    # Verificar Redis Insight
    if ! docker-compose -f docker-compose.prod.yml --env-file .env.prod ps redis-insight | grep -q "Up"; then
        warn "Container Redis Insight não está rodando"
    else
        log "Container Redis Insight está rodando ✓"
    fi
    
    # Verificar Dashboard
    if ! docker-compose -f docker-compose.prod.yml --env-file .env.prod ps cache-dashboard | grep -q "Up"; then
        warn "Container Dashboard não está rodando"
    else
        log "Container Dashboard está rodando ✓"
    fi
}

# Verificar conectividade do Redis
check_redis_connectivity() {
    log "Verificando conectividade do Redis..."
    
    if docker-compose -f docker-compose.prod.yml --env-file .env.prod exec -T redis redis-cli ping | grep -q "PONG"; then
        log "Redis está respondendo ✓"
    else
        error "Redis não está respondendo"
        return 1
    fi
}

# Verificar uso de memória
check_memory() {
    log "Verificando uso de memória..."
    
    # Obter informações de memória
    MEMORY_INFO=$(docker-compose -f docker-compose.prod.yml --env-file .env.prod exec -T redis redis-cli info memory)
    USED_MEMORY=$(echo "$MEMORY_INFO" | grep "used_memory_human" | cut -d: -f2 | tr -d '\r')
    MAX_MEMORY=$(echo "$MEMORY_INFO" | grep "maxmemory_human" | cut -d: -f2 | tr -d '\r')
    
    if [ -n "$USED_MEMORY" ]; then
        log "Memória usada: $USED_MEMORY"
    fi
    
    if [ -n "$MAX_MEMORY" ] && [ "$MAX_MEMORY" != "0B" ]; then
        log "Memória máxima: $MAX_MEMORY"
        
        # Calcular porcentagem (aproximada)
        USED_BYTES=$(echo "$MEMORY_INFO" | grep "used_memory:" | cut -d: -f2 | tr -d '\r')
        MAX_BYTES=$(echo "$MEMORY_INFO" | grep "maxmemory:" | cut -d: -f2 | tr -d '\r')
        
        if [ "$MAX_BYTES" -gt 0 ]; then
            PERCENTAGE=$((USED_BYTES * 100 / MAX_BYTES))
            if [ $PERCENTAGE -gt 90 ]; then
                error "Uso de memória crítico: ${PERCENTAGE}%"
                return 1
            elif [ $PERCENTAGE -gt 80 ]; then
                warn "Uso de memória alto: ${PERCENTAGE}%"
            else
                log "Uso de memória normal: ${PERCENTAGE}%"
            fi
        fi
    fi
}

# Verificar persistência
check_persistence() {
    log "Verificando persistência..."
    
    PERSISTENCE_INFO=$(docker-compose -f docker-compose.prod.yml --env-file .env.prod exec -T redis redis-cli info persistence)
    
    # Verificar RDB
    RDB_LAST_SAVE=$(echo "$PERSISTENCE_INFO" | grep "rdb_last_save_time" | cut -d: -f2 | tr -d '\r')
    if [ -n "$RDB_LAST_SAVE" ] && [ "$RDB_LAST_SAVE" != "0" ]; then
        LAST_SAVE_DATE=$(date -d "@$RDB_LAST_SAVE" 2>/dev/null || echo "N/A")
        log "Último save RDB: $LAST_SAVE_DATE"
    fi
    
    # Verificar AOF
    AOF_ENABLED=$(echo "$PERSISTENCE_INFO" | grep "aof_enabled" | cut -d: -f2 | tr -d '\r')
    if [ "$AOF_ENABLED" = "1" ]; then
        log "AOF habilitado ✓"
    else
        warn "AOF não está habilitado"
    fi
}

# Verificar conexões
check_connections() {
    log "Verificando conexões..."
    
    CLIENT_INFO=$(docker-compose -f docker-compose.prod.yml --env-file .env.prod exec -T redis redis-cli info clients)
    CONNECTED_CLIENTS=$(echo "$CLIENT_INFO" | grep "connected_clients" | cut -d: -f2 | tr -d '\r')
    MAX_CLIENTS=$(docker-compose -f docker-compose.prod.yml --env-file .env.prod exec -T redis redis-cli config get maxclients | tail -1)
    
    if [ -n "$CONNECTED_CLIENTS" ]; then
        log "Clientes conectados: $CONNECTED_CLIENTS"
        
        if [ -n "$MAX_CLIENTS" ] && [ "$MAX_CLIENTS" != "0" ]; then
            PERCENTAGE=$((CONNECTED_CLIENTS * 100 / MAX_CLIENTS))
            if [ $PERCENTAGE -gt 90 ]; then
                error "Número de conexões crítico: ${PERCENTAGE}%"
                return 1
            elif [ $PERCENTAGE -gt 80 ]; then
                warn "Número de conexões alto: ${PERCENTAGE}%"
            fi
        fi
    fi
}

# Verificar performance
check_performance() {
    log "Verificando performance..."
    
    STATS_INFO=$(docker-compose -f docker-compose.prod.yml --env-file .env.prod exec -T redis redis-cli info stats)
    OPS_PER_SEC=$(echo "$STATS_INFO" | grep "instantaneous_ops_per_sec" | cut -d: -f2 | tr -d '\r')
    
    if [ -n "$OPS_PER_SEC" ]; then
        log "Operações por segundo: $OPS_PER_SEC"
    fi
    
    # Verificar hit ratio
    KEYSPACE_HITS=$(echo "$STATS_INFO" | grep "keyspace_hits" | cut -d: -f2 | tr -d '\r')
    KEYSPACE_MISSES=$(echo "$STATS_INFO" | grep "keyspace_misses" | cut -d: -f2 | tr -d '\r')
    
    if [ -n "$KEYSPACE_HITS" ] && [ -n "$KEYSPACE_MISSES" ]; then
        TOTAL_REQUESTS=$((KEYSPACE_HITS + KEYSPACE_MISSES))
        if [ $TOTAL_REQUESTS -gt 0 ]; then
            HIT_RATIO=$((KEYSPACE_HITS * 100 / TOTAL_REQUESTS))
            if [ $HIT_RATIO -lt 80 ]; then
                warn "Hit ratio baixo: ${HIT_RATIO}%"
            else
                log "Hit ratio: ${HIT_RATIO}%"
            fi
        fi
    fi
}

# Verificar interfaces web
check_web_interfaces() {
    log "Verificando interfaces web..."
    
    # Verificar Dashboard
    if curl -s -f https://cache.gwan.com.br/health > /dev/null 2>&1; then
        log "Dashboard acessível ✓"
    else
        warn "Dashboard não está acessível"
    fi
    
    # Verificar Redis Commander
    if curl -s -f https://cache.gwan.com.br/commander > /dev/null 2>&1; then
        log "Redis Commander acessível ✓"
    else
        warn "Redis Commander não está acessível"
    fi
    
    # Verificar Redis Insight
    if curl -s -f https://cache.gwan.com.br/insight > /dev/null 2>&1; then
        log "Redis Insight acessível ✓"
    else
        warn "Redis Insight não está acessível"
    fi
}

# Verificar espaço em disco
check_disk_space() {
    log "Verificando espaço em disco..."
    
    # Verificar espaço do host
    DISK_USAGE=$(df -h . | tail -1 | awk '{print $5}' | sed 's/%//')
    if [ $DISK_USAGE -gt 90 ]; then
        error "Espaço em disco crítico: ${DISK_USAGE}%"
        return 1
    elif [ $DISK_USAGE -gt 80 ]; then
        warn "Espaço em disco baixo: ${DISK_USAGE}%"
    else
        log "Espaço em disco: ${DISK_USAGE}%"
    fi
    
    # Verificar espaço do container
    CONTAINER_DISK=$(docker-compose -f docker-compose.prod.yml --env-file .env.prod exec -T redis df -h /data | tail -1 | awk '{print $5}' | sed 's/%//')
    if [ $CONTAINER_DISK -gt 90 ]; then
        error "Espaço em disco do container crítico: ${CONTAINER_DISK}%"
        return 1
    elif [ $CONTAINER_DISK -gt 80 ]; then
        warn "Espaço em disco do container baixo: ${CONTAINER_DISK}%"
    else
        log "Espaço em disco do container: ${CONTAINER_DISK}%"
    fi
}

# Verificar segurança
check_security() {
    log "Verificando configurações de segurança..."
    
    # Verificar se a senha está configurada
    if docker-compose -f docker-compose.prod.yml --env-file .env.prod exec -T redis redis-cli config get requirepass | grep -q '""'; then
        error "Senha do Redis não configurada!"
        return 1
    else
        log "Senha do Redis configurada ✓"
    fi
    
    # Verificar comandos perigosos
    FLUSHDB_CMD=$(docker-compose -f docker-compose.prod.yml --env-file .env.prod exec -T redis redis-cli config get "rename-command" | grep -i flushdb || echo "")
    if [ -n "$FLUSHDB_CMD" ]; then
        log "Comandos perigosos renomeados ✓"
    else
        warn "Comandos perigosos não foram renomeados"
    fi
    
    # Verificar protected mode
    PROTECTED_MODE=$(docker-compose -f docker-compose.prod.yml --env-file .env.prod exec -T redis redis-cli config get protected-mode | tail -1)
    if [ "$PROTECTED_MODE" = "yes" ]; then
        log "Protected mode habilitado ✓"
    else
        warn "Protected mode não está habilitado"
    fi
}

# Função principal
main() {
    echo "🏥 Verificação de Saúde do Gwan Cache - Produção"
    echo "================================================"
    echo ""
    
    local exit_code=0
    
    # Executar todas as verificações
    check_docker || exit_code=1
    check_containers || exit_code=1
    check_redis_connectivity || exit_code=1
    check_memory || exit_code=1
    check_persistence
    check_connections || exit_code=1
    check_performance
    check_web_interfaces
    check_disk_space || exit_code=1
    check_security || exit_code=1
    
    echo ""
    if [ $exit_code -eq 0 ]; then
        log "✅ Todas as verificações passaram! Sistema saudável."
    else
        error "❌ Algumas verificações falharam. Verifique os problemas acima."
    fi
    
    echo ""
    echo "📊 Informações adicionais:"
    echo "   • Dashboard: https://cache.gwan.com.br"
    echo "   • Redis Commander: https://cache.gwan.com.br/commander"
    echo "   • Redis Insight: https://cache.gwan.com.br/insight"
    echo "   • Monitoramento: ./scripts/monitor-prod.sh"
    echo ""
    
    exit $exit_code
}

# Executar função principal
main "$@"
