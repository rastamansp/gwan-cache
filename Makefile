# Makefile para Gwan Cache Administration
# Autor: Gwan Cache Administration

.PHONY: help start stop restart status logs backup restore monitor health clean install

# Variáveis
COMPOSE_FILE = docker-compose.yml
ENV_FILE = .env

# Cores para output
GREEN = \033[0;32m
YELLOW = \033[1;33m
RED = \033[0;31m
NC = \033[0m

# Ajuda padrão
help: ## Mostrar esta mensagem de ajuda
	@echo "$(GREEN)Gwan Cache Administration - Comandos Disponíveis$(NC)"
	@echo "=================================================="
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  $(YELLOW)%-15s$(NC) %s\n", $$1, $$2}' $(MAKEFILE_LIST)

# Comandos de gerenciamento
install: ## Instalar e configurar o ambiente
	@echo "$(GREEN)🚀 Instalando Gwan Cache...$(NC)"
	@if [ ! -f $(ENV_FILE) ]; then \
		cp env.example $(ENV_FILE); \
		echo "$(YELLOW)⚠️  Arquivo .env criado. Configure as variáveis antes de continuar.$(NC)"; \
	fi
	@echo "$(GREEN)✅ Instalação concluída!$(NC)"

start: ## Iniciar o ambiente de cache
	@echo "$(GREEN)🚀 Iniciando ambiente de cache...$(NC)"
	@./scripts/start.sh

stop: ## Parar o ambiente de cache
	@echo "$(GREEN)🛑 Parando ambiente de cache...$(NC)"
	@./scripts/stop.sh

restart: ## Reiniciar o ambiente de cache
	@echo "$(GREEN)🔄 Reiniciando ambiente de cache...$(NC)"
	@make stop
	@make start

status: ## Verificar status dos containers
	@echo "$(GREEN)📊 Status dos containers:$(NC)"
	@docker-compose ps

logs: ## Mostrar logs dos containers
	@echo "$(GREEN)📋 Logs dos containers:$(NC)"
	@docker-compose logs -f

# Comandos de backup e restore
backup: ## Fazer backup do Redis
	@echo "$(GREEN)💾 Iniciando backup...$(NC)"
	@./scripts/backup.sh

restore: ## Restaurar backup do Redis
	@echo "$(GREEN)🔄 Iniciando restore...$(NC)"
	@./scripts/restore.sh

# Comandos de monitoramento
monitor: ## Monitorar o Redis
	@echo "$(GREEN)📊 Iniciando monitoramento...$(NC)"
	@./scripts/monitor.sh

health: ## Verificar saúde do sistema
	@echo "$(GREEN)🏥 Verificando saúde do sistema...$(NC)"
	@./scripts/health-check.sh

# Comandos de manutenção
clean: ## Limpar containers e volumes
	@echo "$(GREEN)🧹 Limpando ambiente...$(NC)"
	@echo "$(YELLOW)⚠️  Esta operação irá remover todos os dados!$(NC)"
	@read -p "Tem certeza? (s/N): " confirm && [ "$$confirm" = "s" ] || exit 1
	@docker-compose down -v
	@docker system prune -f
	@echo "$(GREEN)✅ Limpeza concluída!$(NC)"

clean-images: ## Remover imagens não utilizadas
	@echo "$(GREEN)🧹 Removendo imagens não utilizadas...$(NC)"
	@docker image prune -f

clean-all: ## Limpeza completa (containers, volumes, imagens)
	@echo "$(GREEN)🧹 Limpeza completa...$(NC)"
	@echo "$(YELLOW)⚠️  Esta operação irá remover TUDO!$(NC)"
	@read -p "Tem certeza? (s/N): " confirm && [ "$$confirm" = "s" ] || exit 1
	@docker-compose down -v --rmi all
	@docker system prune -af
	@echo "$(GREEN)✅ Limpeza completa concluída!$(NC)"

# Comandos de desenvolvimento
dev: ## Iniciar ambiente de desenvolvimento
	@echo "$(GREEN)🛠️  Iniciando ambiente de desenvolvimento...$(NC)"
	@make start
	@echo "$(GREEN)✅ Ambiente de desenvolvimento pronto!$(NC)"
	@echo "$(GREEN)📋 Serviços disponíveis:$(NC)"
	@echo "   • Redis: localhost:6379"
	@echo "   • Redis Commander: http://localhost:8081"
	@echo "   • Redis Insight: http://localhost:8001"

# Comandos de produção
prod-deploy: ## Deploy em produção
	@echo "$(GREEN)🚀 Iniciando deploy em produção...$(NC)"
	@./scripts/deploy-prod.sh

prod-stop: ## Parar ambiente de produção
	@echo "$(GREEN)🛑 Parando ambiente de produção...$(NC)"
	@docker-compose -f docker-compose.prod.yml --env-file .env.prod down

prod-logs: ## Mostrar logs de produção
	@echo "$(GREEN)📋 Logs de produção:$(NC)"
	@docker-compose -f docker-compose.prod.yml --env-file .env.prod logs -f

prod-status: ## Status do ambiente de produção
	@echo "$(GREEN)📊 Status de produção:$(NC)"
	@docker-compose -f docker-compose.prod.yml --env-file .env.prod ps

prod-health: ## Verificar saúde de produção
	@echo "$(GREEN)🏥 Verificando saúde de produção...$(NC)"
	@./scripts/health-check-prod.sh

prod-backup: ## Backup de produção
	@echo "$(GREEN)💾 Backup de produção...$(NC)"
	@./scripts/backup-prod.sh

prod-restart: ## Reiniciar ambiente de produção
	@echo "$(GREEN)🔄 Reiniciando ambiente de produção...$(NC)"
	@docker-compose -f docker-compose.prod.yml --env-file .env.prod restart

prod-update: ## Atualizar imagens de produção
	@echo "$(GREEN)🔄 Atualizando imagens de produção...$(NC)"
	@docker-compose -f docker-compose.prod.yml --env-file .env.prod pull
	@docker-compose -f docker-compose.prod.yml --env-file .env.prod up -d

generate-passwords: ## Gerar senhas para produção
	@echo "$(GREEN)🔐 Gerando senhas para produção...$(NC)"
	@./scripts/generate-passwords.sh

prod: ## Iniciar ambiente de produção
	@echo "$(GREEN)🏭 Iniciando ambiente de produção...$(NC)"
	@echo "$(YELLOW)⚠️  Certifique-se de configurar as variáveis de produção!$(NC)"
	@make start
	@echo "$(GREEN)✅ Ambiente de produção iniciado!$(NC)"

# Comandos de teste
test: ## Executar testes do sistema
	@echo "$(GREEN)🧪 Executando testes...$(NC)"
	@make health
	@echo "$(GREEN)✅ Testes concluídos!$(NC)"

test-connectivity: ## Testar conectividade do Redis
	@echo "$(GREEN)🔌 Testando conectividade...$(NC)"
	@docker-compose exec -T redis redis-cli ping
	@echo "$(GREEN)✅ Conectividade OK!$(NC)"

test-performance: ## Testar performance do Redis
	@echo "$(GREEN)⚡ Testando performance...$(NC)"
	@docker-compose exec -T redis redis-cli --latency
	@echo "$(GREEN)✅ Teste de performance concluído!$(NC)"

# Comandos de configuração
config: ## Mostrar configuração atual
	@echo "$(GREEN)⚙️  Configuração atual:$(NC)"
	@echo "Docker Compose:"
	@docker-compose config
	@echo ""
	@echo "Variáveis de ambiente:"
	@if [ -f $(ENV_FILE) ]; then \
		cat $(ENV_FILE); \
	else \
		echo "$(YELLOW)Arquivo .env não encontrado$(NC)"; \
	fi

config-redis: ## Mostrar configuração do Redis
	@echo "$(GREEN)⚙️  Configuração do Redis:$(NC)"
	@docker-compose exec -T redis redis-cli config get "*"

# Comandos de informações
info: ## Mostrar informações do sistema
	@echo "$(GREEN)📊 Informações do Sistema:$(NC)"
	@echo "================================"
	@make status
	@echo ""
	@echo "$(GREEN)📈 Estatísticas do Redis:$(NC)"
	@docker-compose exec -T redis redis-cli info server | head -10
	@echo ""
	@echo "$(GREEN)💾 Uso de Memória:$(NC)"
	@docker-compose exec -T redis redis-cli info memory | grep -E "(used_memory_human|maxmemory_human)"

version: ## Mostrar versões dos componentes
	@echo "$(GREEN)📋 Versões dos Componentes:$(NC)"
	@echo "Docker: $$(docker --version)"
	@echo "Docker Compose: $$(docker-compose --version)"
	@echo "Redis: $$(docker-compose exec -T redis redis-cli --version)"

# Comandos de segurança
security-check: ## Verificar configurações de segurança
	@echo "$(GREEN)🔒 Verificando segurança...$(NC)"
	@echo "Verificando senha do Redis..."
	@if docker-compose exec -T redis redis-cli config get requirepass | grep -q '""'; then \
		echo "$(RED)❌ Senha do Redis não configurada!$(NC)"; \
	else \
		echo "$(GREEN)✅ Senha do Redis configurada$(NC)"; \
	fi
	@echo "Verificando bind address..."
	@docker-compose exec -T redis redis-cli config get bind
	@echo "$(GREEN)✅ Verificação de segurança concluída!$(NC)"

# Comandos de atualização
update: ## Atualizar imagens Docker
	@echo "$(GREEN)🔄 Atualizando imagens...$(NC)"
	@docker-compose pull
	@echo "$(GREEN)✅ Imagens atualizadas!$(NC)"

update-and-restart: ## Atualizar e reiniciar
	@echo "$(GREEN)🔄 Atualizando e reiniciando...$(NC)"
	@make update
	@make restart
	@echo "$(GREEN)✅ Atualização e reinício concluídos!$(NC)"

# Comandos de documentação
docs: ## Abrir documentação
	@echo "$(GREEN)📚 Abrindo documentação...$(NC)"
	@echo "Documentação disponível em:"
	@echo "   • README.md - Guia principal"
	@echo "   • docs/ADMINISTRATION.md - Guia de administração"
	@echo "   • docs/TROUBLESHOOTING.md - Guia de troubleshooting"

# Comando padrão
.DEFAULT_GOAL := help
