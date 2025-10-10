#!/bin/bash

# Script para backup do Redis em produção
# Autor: Gwan Cache Administration

set -e

# Configurações
BACKUP_DIR="./backups/prod"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_FILE="redis_backup_prod_${TIMESTAMP}.rdb"

echo "💾 Iniciando backup do Redis - Produção..."

# Criar diretório de backup se não existir
mkdir -p "$BACKUP_DIR"

# Verificar se o Redis está rodando
if ! docker-compose -f docker-compose.prod.yml --env-file .env.prod ps redis | grep -q "Up"; then
    echo "❌ Redis não está rodando. Inicie o ambiente primeiro."
    exit 1
fi

# Executar backup
echo "📦 Criando backup: $BACKUP_FILE"
docker-compose -f docker-compose.prod.yml --env-file .env.prod exec -T redis redis-cli BGSAVE

# Aguardar o backup ser concluído
echo "⏳ Aguardando conclusão do backup..."
while [ "$(docker-compose -f docker-compose.prod.yml --env-file .env.prod exec -T redis redis-cli LASTSAVE)" = "$(docker-compose -f docker-compose.prod.yml --env-file .env.prod exec -T redis redis-cli LASTSAVE)" ]; do
    sleep 1
done

# Copiar arquivo de backup
docker cp gwan-cache-redis-prod:/data/dump.rdb "$BACKUP_DIR/$BACKUP_FILE"

# Comprimir backup
echo "🗜️  Comprimindo backup..."
gzip "$BACKUP_DIR/$BACKUP_FILE"

echo "✅ Backup concluído: $BACKUP_DIR/${BACKUP_FILE}.gz"

# Limpar backups antigos (manter apenas os 30 mais recentes)
echo "🧹 Limpando backups antigos..."
cd "$BACKUP_DIR"
ls -t redis_backup_prod_*.rdb.gz | tail -n +31 | xargs -r rm
cd ..

echo "📊 Backups disponíveis:"
ls -la "$BACKUP_DIR"/redis_backup_prod_*.rdb.gz 2>/dev/null || echo "Nenhum backup encontrado."

# Enviar notificação (opcional)
if [ -n "$BACKUP_WEBHOOK" ]; then
    echo "📢 Enviando notificação..."
    curl -X POST -H 'Content-type: application/json' \
        --data "{\"text\":\"✅ Backup do Redis concluído: ${BACKUP_FILE}.gz\"}" \
        "$BACKUP_WEBHOOK"
fi
