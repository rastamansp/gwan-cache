#!/bin/bash

# Script para gerar senhas hasheadas para autenticação básica
# Autor: Gwan Cache Administration

set -e

# Cores para output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo "🔐 Gerador de Senhas para Gwan Cache"
echo "===================================="
echo ""

# Verificar se htpasswd está instalado
if ! command -v htpasswd &> /dev/null; then
    echo -e "${YELLOW}htpasswd não encontrado. Instalando...${NC}"
    
    # Detectar sistema operacional
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if command -v apt-get &> /dev/null; then
            sudo apt-get update && sudo apt-get install -y apache2-utils
        elif command -v yum &> /dev/null; then
            sudo yum install -y httpd-tools
        elif command -v dnf &> /dev/null; then
            sudo dnf install -y httpd-tools
        else
            echo -e "${YELLOW}Por favor, instale apache2-utils manualmente${NC}"
            exit 1
        fi
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        if command -v brew &> /dev/null; then
            brew install httpd
        else
            echo -e "${YELLOW}Por favor, instale Homebrew e httpd manualmente${NC}"
            exit 1
        fi
    else
        echo -e "${YELLOW}Sistema operacional não suportado. Instale apache2-utils manualmente${NC}"
        exit 1
    fi
fi

echo -e "${GREEN}htpasswd encontrado!${NC}"
echo ""

# Função para gerar hash
generate_hash() {
    local service=$1
    local username=$2
    
    echo -e "${BLUE}Configurando $service:${NC}"
    read -p "Digite a senha para $username: " -s password
    echo ""
    
    if [ -n "$password" ]; then
        hash=$(htpasswd -nb "$username" "$password")
        echo -e "${GREEN}Hash gerado:${NC} $hash"
        echo ""
        return 0
    else
        echo -e "${YELLOW}Senha vazia, pulando...${NC}"
        echo ""
        return 1
    fi
}

# Gerar hashes para cada serviço
echo "Gerando hashes para autenticação básica:"
echo ""

# Redis Commander
if generate_hash "Redis Commander" "admin"; then
    REDIS_COMMANDER_AUTH=$hash
fi

# Redis Insight
if generate_hash "Redis Insight" "admin"; then
    REDIS_INSIGHT_AUTH=$hash
fi

# Dashboard
if generate_hash "Dashboard" "admin"; then
    DASHBOARD_AUTH=$hash
fi

# Gerar arquivo de configuração
echo -e "${GREEN}Gerando arquivo de configuração...${NC}"

cat > .env.prod.generated << EOF
# Configurações geradas automaticamente
# Data: $(date)

# Configurações do Redis Commander
REDIS_COMMANDER_AUTH=${REDIS_COMMANDER_AUTH:-admin:\$2y\$10\$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi}

# Configurações do Redis Insight
REDIS_INSIGHT_AUTH=${REDIS_INSIGHT_AUTH:-admin:\$2y\$10\$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi}

# Configurações do Dashboard
DASHBOARD_AUTH=${DASHBOARD_AUTH:-admin:\$2y\$10\$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi}
EOF

echo ""
echo -e "${GREEN}✅ Arquivo .env.prod.generated criado com sucesso!${NC}"
echo ""
echo "📋 Próximos passos:"
echo "1. Copie as configurações do arquivo .env.prod.generated"
echo "2. Cole no arquivo .env.prod"
echo "3. Configure as outras variáveis necessárias"
echo "4. Execute o deploy: ./scripts/deploy-prod.sh"
echo ""
echo "🔒 Importante: Mantenha as senhas seguras e não as compartilhe!"
echo ""
