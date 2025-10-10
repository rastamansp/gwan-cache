#!/bin/bash

# Script para restore do Redis
# Autor: Gwan Cache Administration

set -e

BACKUP_DIR="./backups"

echo "🔄 Iniciando restore do Redis..."

# Verificar se o diretório de backup existe
if [ ! -d "$BACKUP_DIR" ]; then
    echo "❌ Diretório de backup não encontrado: $BACKUP_DIR"
    exit 1
fi

# Listar backups disponíveis
echo "📋 Backups disponíveis:"
ls -la "$BACKUP_DIR"/redis_backup_*.rdb.gz 2>/dev/null || {
    echo "❌ Nenhum backup encontrado."
    exit 1
}

# Solicitar qual backup restaurar
echo ""
read -p "Digite o nome do arquivo de backup para restaurar: " BACKUP_FILE

# Verificar se o arquivo existe
if [ ! -f "$BACKUP_DIR/$BACKUP_FILE" ]; then
    echo "❌ Arquivo de backup não encontrado: $BACKUP_DIR/$BACKUP_FILE"
    exit 1
fi

# Confirmar operação
echo ""
echo "⚠️  ATENÇÃO: Esta operação irá substituir todos os dados atuais do Redis!"
echo "Arquivo selecionado: $BACKUP_FILE"
read -p "Tem certeza que deseja continuar? (s/N): " CONFIRM

if [[ ! "$CONFIRM" =~ ^[Ss]$ ]]; then
    echo "❌ Operação cancelada."
    exit 0
fi

# Parar Redis
echo "🛑 Parando Redis..."
docker-compose stop redis

# Descomprimir backup se necessário
if [[ "$BACKUP_FILE" == *.gz ]]; then
    echo "📦 Descomprimindo backup..."
    gunzip -c "$BACKUP_DIR/$BACKUP_FILE" > "$BACKUP_DIR/temp_restore.rdb"
    RESTORE_FILE="temp_restore.rdb"
else
    RESTORE_FILE="$BACKUP_FILE"
fi

# Copiar arquivo para o container
echo "📋 Copiando arquivo de backup..."
docker cp "$BACKUP_DIR/$RESTORE_FILE" gwan-cache-redis:/data/dump.rdb

# Limpar arquivo temporário se foi criado
if [[ "$RESTORE_FILE" == "temp_restore.rdb" ]]; then
    rm "$BACKUP_DIR/temp_restore.rdb"
fi

# Iniciar Redis
echo "🚀 Iniciando Redis..."
docker-compose start redis

# Aguardar Redis ficar pronto
echo "⏳ Aguardando Redis ficar pronto..."
sleep 5

# Verificar se o restore foi bem-sucedido
if docker-compose exec -T redis redis-cli ping | grep -q "PONG"; then
    echo "✅ Restore concluído com sucesso!"
    
    # Mostrar informações do banco
    echo "📊 Informações do banco restaurado:"
    docker-compose exec -T redis redis-cli info keyspace
else
    echo "❌ Erro durante o restore. Verifique os logs:"
    docker-compose logs redis
    exit 1
fi
