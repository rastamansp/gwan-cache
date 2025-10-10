#!/bin/bash

# Script para backup do Redis
# Autor: Gwan Cache Administration

set -e

# Configurações
BACKUP_DIR="./backups"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_FILE="redis_backup_${TIMESTAMP}.rdb"

echo "💾 Iniciando backup do Redis..."

# Criar diretório de backup se não existir
mkdir -p "$BACKUP_DIR"

# Verificar se o Redis está rodando
if ! docker-compose ps redis | grep -q "Up"; then
    echo "❌ Redis não está rodando. Inicie o ambiente primeiro."
    exit 1
fi

# Executar backup
echo "📦 Criando backup: $BACKUP_FILE"
docker-compose exec -T redis redis-cli BGSAVE

# Aguardar o backup ser concluído
echo "⏳ Aguardando conclusão do backup..."
while [ "$(docker-compose exec -T redis redis-cli LASTSAVE)" = "$(docker-compose exec -T redis redis-cli LASTSAVE)" ]; do
    sleep 1
done

# Copiar arquivo de backup
docker cp gwan-cache-redis:/data/dump.rdb "$BACKUP_DIR/$BACKUP_FILE"

# Comprimir backup
echo "🗜️  Comprimindo backup..."
gzip "$BACKUP_DIR/$BACKUP_FILE"

echo "✅ Backup concluído: $BACKUP_DIR/${BACKUP_FILE}.gz"

# Limpar backups antigos (manter apenas os 10 mais recentes)
echo "🧹 Limpando backups antigos..."
cd "$BACKUP_DIR"
ls -t redis_backup_*.rdb.gz | tail -n +11 | xargs -r rm
cd ..

echo "📊 Backups disponíveis:"
ls -la "$BACKUP_DIR"/redis_backup_*.rdb.gz 2>/dev/null || echo "Nenhum backup encontrado."
