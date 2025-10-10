#!/bin/bash

# Script para monitoramento do Redis
# Autor: Gwan Cache Administration

set -e

echo "📊 Monitoramento do Redis - Gwan Cache"
echo "======================================"

# Verificar se o Redis está rodando
if ! docker-compose ps redis | grep -q "Up"; then
    echo "❌ Redis não está rodando. Inicie o ambiente primeiro."
    exit 1
fi

# Função para mostrar informações do Redis
show_redis_info() {
    echo ""
    echo "🔍 Informações Gerais do Redis:"
    echo "-------------------------------"
    docker-compose exec -T redis redis-cli info server | grep -E "(redis_version|os|arch|process_id|uptime_in_seconds)"
    
    echo ""
    echo "💾 Informações de Memória:"
    echo "-------------------------"
    docker-compose exec -T redis redis-cli info memory | grep -E "(used_memory_human|used_memory_peak_human|maxmemory_human|mem_fragmentation_ratio)"
    
    echo ""
    echo "📈 Estatísticas de Conexões:"
    echo "----------------------------"
    docker-compose exec -T redis redis-cli info clients | grep -E "(connected_clients|blocked_clients)"
    
    echo ""
    echo "🗂️  Informações de Keyspace:"
    echo "---------------------------"
    docker-compose exec -T redis redis-cli info keyspace
    
    echo ""
    echo "⚡ Estatísticas de Comandos:"
    echo "---------------------------"
    docker-compose exec -T redis redis-cli info stats | grep -E "(total_commands_processed|instantaneous_ops_per_sec|keyspace_hits|keyspace_misses)"
    
    echo ""
    echo "💿 Informações de Persistência:"
    echo "------------------------------"
    docker-compose exec -T redis redis-cli info persistence | grep -E "(rdb_last_save_time|rdb_changes_since_last_save|aof_enabled|aof_rewrite_in_progress)"
}

# Função para mostrar top keys
show_top_keys() {
    echo ""
    echo "🔑 Top 10 Keys por Tamanho:"
    echo "---------------------------"
    docker-compose exec -T redis redis-cli --scan --pattern "*" | head -10 | while read key; do
        size=$(docker-compose exec -T redis redis-cli memory usage "$key" 2>/dev/null || echo "0")
        echo "$key: ${size} bytes"
    done | sort -k2 -nr | head -10
}

# Função para mostrar configurações importantes
show_config() {
    echo ""
    echo "⚙️  Configurações Importantes:"
    echo "-----------------------------"
    docker-compose exec -T redis redis-cli config get maxmemory
    docker-compose exec -T redis redis-cli config get maxmemory-policy
    docker-compose exec -T redis redis-cli config get save
    docker-compose exec -T redis redis-cli config get appendonly
}

# Função para monitoramento contínuo
continuous_monitor() {
    echo ""
    echo "🔄 Monitoramento Contínuo (Ctrl+C para sair):"
    echo "---------------------------------------------"
    while true; do
        clear
        echo "📊 Monitoramento do Redis - $(date)"
        echo "======================================"
        show_redis_info
        sleep 5
    done
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
    "all")
        show_redis_info
        show_top_keys
        show_config
        ;;
    *)
        echo "Uso: $0 [info|keys|config|monitor|all]"
        echo ""
        echo "Comandos disponíveis:"
        echo "  info    - Mostrar informações gerais (padrão)"
        echo "  keys    - Mostrar top keys por tamanho"
        echo "  config  - Mostrar configurações importantes"
        echo "  monitor - Monitoramento contínuo"
        echo "  all     - Mostrar todas as informações"
        exit 1
        ;;
esac
