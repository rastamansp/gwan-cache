#!/bin/bash

# Script para monitoramento do Redis em produção
# Autor: Gwan Cache Administration

set -e

echo "📊 Monitoramento do Redis - Gwan Cache Produção"
echo "=============================================="

# Verificar se o Redis está rodando
if ! docker-compose -f docker-compose.prod.yml --env-file .env.prod ps redis | grep -q "Up"; then
    echo "❌ Redis não está rodando. Inicie o ambiente primeiro."
    exit 1
fi

# Função para mostrar informações do Redis
show_redis_info() {
    echo ""
    echo "🔍 Informações Gerais do Redis:"
    echo "-------------------------------"
    docker-compose -f docker-compose.prod.yml --env-file .env.prod exec -T redis redis-cli info server | grep -E "(redis_version|os|arch|process_id|uptime_in_seconds)"
    
    echo ""
    echo "💾 Informações de Memória:"
    echo "-------------------------"
    docker-compose -f docker-compose.prod.yml --env-file .env.prod exec -T redis redis-cli info memory | grep -E "(used_memory_human|used_memory_peak_human|maxmemory_human|mem_fragmentation_ratio)"
    
    echo ""
    echo "📈 Estatísticas de Conexões:"
    echo "----------------------------"
    docker-compose -f docker-compose.prod.yml --env-file .env.prod exec -T redis redis-cli info clients | grep -E "(connected_clients|blocked_clients)"
    
    echo ""
    echo "🗂️  Informações de Keyspace:"
    echo "---------------------------"
    docker-compose -f docker-compose.prod.yml --env-file .env.prod exec -T redis redis-cli info keyspace
    
    echo ""
    echo "⚡ Estatísticas de Comandos:"
    echo "---------------------------"
    docker-compose -f docker-compose.prod.yml --env-file .env.prod exec -T redis redis-cli info stats | grep -E "(total_commands_processed|instantaneous_ops_per_sec|keyspace_hits|keyspace_misses)"
    
    echo ""
    echo "💿 Informações de Persistência:"
    echo "------------------------------"
    docker-compose -f docker-compose.prod.yml --env-file .env.prod exec -T redis redis-cli info persistence | grep -E "(rdb_last_save_time|rdb_changes_since_last_save|aof_enabled|aof_rewrite_in_progress)"
}

# Função para mostrar top keys
show_top_keys() {
    echo ""
    echo "🔑 Top 10 Keys por Tamanho:"
    echo "---------------------------"
    docker-compose -f docker-compose.prod.yml --env-file .env.prod exec -T redis redis-cli --scan --pattern "*" | head -10 | while read key; do
        size=$(docker-compose -f docker-compose.prod.yml --env-file .env.prod exec -T redis redis-cli memory usage "$key" 2>/dev/null || echo "0")
        echo "$key: ${size} bytes"
    done | sort -k2 -nr | head -10
}

# Função para mostrar configurações importantes
show_config() {
    echo ""
    echo "⚙️  Configurações Importantes:"
    echo "-----------------------------"
    docker-compose -f docker-compose.prod.yml --env-file .env.prod exec -T redis redis-cli config get maxmemory
    docker-compose -f docker-compose.prod.yml --env-file .env.prod exec -T redis redis-cli config get maxmemory-policy
    docker-compose -f docker-compose.prod.yml --env-file .env.prod exec -T redis redis-cli config get save
    docker-compose -f docker-compose.prod.yml --env-file .env.prod exec -T redis redis-cli config get appendonly
}

# Função para monitoramento contínuo
continuous_monitor() {
    echo ""
    echo "🔄 Monitoramento Contínuo (Ctrl+C para sair):"
    echo "---------------------------------------------"
    while true; do
        clear
        echo "📊 Monitoramento do Redis - Produção - $(date)"
        echo "=============================================="
        show_redis_info
        sleep 5
    done
}

# Função para verificar alertas
check_alerts() {
    echo ""
    echo "🚨 Verificação de Alertas:"
    echo "-------------------------"
    
    # Verificar uso de memória
    MEMORY_INFO=$(docker-compose -f docker-compose.prod.yml --env-file .env.prod exec -T redis redis-cli info memory)
    USED_BYTES=$(echo "$MEMORY_INFO" | grep "used_memory:" | cut -d: -f2 | tr -d '\r')
    MAX_BYTES=$(echo "$MEMORY_INFO" | grep "maxmemory:" | cut -d: -f2 | tr -d '\r')
    
    if [ "$MAX_BYTES" -gt 0 ]; then
        PERCENTAGE=$((USED_BYTES * 100 / MAX_BYTES))
        if [ $PERCENTAGE -gt 90 ]; then
            echo "🔴 ALERTA: Uso de memória crítico: ${PERCENTAGE}%"
        elif [ $PERCENTAGE -gt 80 ]; then
            echo "🟡 AVISO: Uso de memória alto: ${PERCENTAGE}%"
        else
            echo "🟢 OK: Uso de memória normal: ${PERCENTAGE}%"
        fi
    fi
    
    # Verificar hit ratio
    STATS_INFO=$(docker-compose -f docker-compose.prod.yml --env-file .env.prod exec -T redis redis-cli info stats)
    KEYSPACE_HITS=$(echo "$STATS_INFO" | grep "keyspace_hits" | cut -d: -f2 | tr -d '\r')
    KEYSPACE_MISSES=$(echo "$STATS_INFO" | grep "keyspace_misses" | cut -d: -f2 | tr -d '\r')
    
    if [ -n "$KEYSPACE_HITS" ] && [ -n "$KEYSPACE_MISSES" ]; then
        TOTAL_REQUESTS=$((KEYSPACE_HITS + KEYSPACE_MISSES))
        if [ $TOTAL_REQUESTS -gt 0 ]; then
            HIT_RATIO=$((KEYSPACE_HITS * 100 / TOTAL_REQUESTS))
            if [ $HIT_RATIO -lt 80 ]; then
                echo "🔴 ALERTA: Hit ratio baixo: ${HIT_RATIO}%"
            elif [ $HIT_RATIO -lt 90 ]; then
                echo "🟡 AVISO: Hit ratio médio: ${HIT_RATIO}%"
            else
                echo "🟢 OK: Hit ratio bom: ${HIT_RATIO}%"
            fi
        fi
    fi
    
    # Verificar conexões
    CLIENT_INFO=$(docker-compose -f docker-compose.prod.yml --env-file .env.prod exec -T redis redis-cli info clients)
    CONNECTED_CLIENTS=$(echo "$CLIENT_INFO" | grep "connected_clients" | cut -d: -f2 | tr -d '\r')
    MAX_CLIENTS=$(docker-compose -f docker-compose.prod.yml --env-file .env.prod exec -T redis redis-cli config get maxclients | tail -1)
    
    if [ -n "$MAX_CLIENTS" ] && [ "$MAX_CLIENTS" != "0" ]; then
        PERCENTAGE=$((CONNECTED_CLIENTS * 100 / MAX_CLIENTS))
        if [ $PERCENTAGE -gt 90 ]; then
            echo "🔴 ALERTA: Número de conexões crítico: ${PERCENTAGE}%"
        elif [ $PERCENTAGE -gt 80 ]; then
            echo "🟡 AVISO: Número de conexões alto: ${PERCENTAGE}%"
        else
            echo "🟢 OK: Número de conexões normal: ${PERCENTAGE}%"
        fi
    fi
}

# Menu principal
case "${1:-info}" in
    "info")
        show_redis_info
        show_config
        ;;
    "keys")
        show_top_keys
        ;;
    "config")
        show_config
        ;;
    "monitor")
        continuous_monitor
        ;;
    "alerts")
        check_alerts
        ;;
    "all")
        show_redis_info
        show_top_keys
        show_config
        check_alerts
        ;;
    *)
        echo "Uso: $0 [info|keys|config|monitor|alerts|all]"
        echo ""
        echo "Comandos disponíveis:"
        echo "  info    - Mostrar informações gerais (padrão)"
        echo "  keys    - Mostrar top keys por tamanho"
        echo "  config  - Mostrar configurações importantes"
        echo "  monitor - Monitoramento contínuo"
        echo "  alerts  - Verificar alertas de produção"
        echo "  all     - Mostrar todas as informações"
        exit 1
        ;;
esac
