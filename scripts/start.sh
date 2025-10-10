#!/bin/bash

# Script para iniciar o ambiente de cache Redis
# Autor: Gwan Cache Administration
# Data: $(date)

set -e

echo "🚀 Iniciando ambiente de cache Redis..."

# Verificar se o Docker está rodando
if ! docker info > /dev/null 2>&1; then
    echo "❌ Docker não está rodando. Por favor, inicie o Docker primeiro."
    exit 1
fi

# Verificar se o arquivo .env existe
if [ ! -f .env ]; then
    echo "⚠️  Arquivo .env não encontrado. Copiando de env.example..."
    cp env.example .env
    echo "📝 Por favor, edite o arquivo .env com suas configurações antes de continuar."
    echo "   Especialmente a senha do Redis (REDIS_PASSWORD)"
    read -p "Pressione Enter para continuar após editar o .env..."
fi

# Construir e iniciar os containers
echo "🔨 Construindo e iniciando containers..."
docker-compose up -d

# Aguardar os serviços ficarem prontos
echo "⏳ Aguardando serviços ficarem prontos..."
sleep 10

# Verificar status dos containers
echo "📊 Status dos containers:"
docker-compose ps

# Verificar saúde do Redis
echo "🏥 Verificando saúde do Redis..."
if docker-compose exec -T redis redis-cli ping | grep -q "PONG"; then
    echo "✅ Redis está funcionando corretamente!"
else
    echo "❌ Redis não está respondendo corretamente."
    exit 1
fi

echo ""
echo "🎉 Ambiente de cache Redis iniciado com sucesso!"
echo ""
echo "📋 Serviços disponíveis:"
echo "   • Redis: localhost:6379"
echo "   • Redis Commander: http://localhost:8081"
echo "   • Redis Insight: http://localhost:8001"
echo ""
echo "🔧 Comandos úteis:"
echo "   • Ver logs: docker-compose logs -f"
echo "   • Parar serviços: docker-compose down"
echo "   • Reiniciar: docker-compose restart"
echo "   • Status: docker-compose ps"
echo ""
