#!/bin/bash

# Script para parar o ambiente de cache Redis
# Autor: Gwan Cache Administration

set -e

echo "🛑 Parando ambiente de cache Redis..."

# Parar containers
docker-compose down

echo "✅ Ambiente de cache Redis parado com sucesso!"
echo ""
echo "💡 Para remover também os volumes (dados):"
echo "   docker-compose down -v"
echo ""
echo "💡 Para remover imagens também:"
echo "   docker-compose down --rmi all"
echo ""
