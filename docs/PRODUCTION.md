# Guia de Deploy em Produção - Gwan Cache

Este documento fornece instruções detalhadas para fazer o deploy do sistema de cache Redis em produção usando Traefik como proxy reverso.

## 🚀 Visão Geral

O sistema de produção inclui:
- **Redis Server**: Cache principal com configurações otimizadas
- **Redis Commander**: Interface web para administração
- **Redis Insight**: Ferramenta avançada de análise
- **Dashboard**: Interface principal de acesso
- **Traefik**: Proxy reverso com SSL/TLS automático

## 📋 Pré-requisitos

### Infraestrutura
- Servidor com Docker e Docker Compose instalados
- Rede Docker externa `gwan` configurada
- Traefik configurado e rodando
- Domínio `cache.gwan.com.br` apontando para o servidor
- Certificado SSL (Let's Encrypt via Traefik)

### Software
- Docker 20.10+
- Docker Compose 2.0+
- Traefik 2.0+ com Let's Encrypt
- Bash 4.0+

## ⚙️ Configuração

### 1. Preparar Ambiente

```bash
# Clonar o repositório
git clone <repository-url>
cd gwan-cache

# Copiar configurações de produção
cp env.prod.example .env.prod
```

### 2. Configurar Variáveis de Ambiente

Edite o arquivo `.env.prod` com as configurações de produção:

```env
# Configurações do Redis
REDIS_PASSWORD=your_very_strong_production_password_here

# Configurações do Redis Commander
REDIS_COMMANDER_USER=admin
REDIS_COMMANDER_PASSWORD=your_commander_password_here
REDIS_COMMANDER_AUTH=admin:$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi

# Configurações do Redis Insight
REDIS_INSIGHT_AUTH=admin:$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi

# Configurações do Dashboard
DASHBOARD_AUTH=admin:$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi

# Configurações de ambiente
NODE_ENV=production
```

### 3. Gerar Senhas para Autenticação

Para gerar senhas hasheadas para autenticação básica:

```bash
# Instalar htpasswd (se não estiver instalado)
sudo apt-get install apache2-utils

# Gerar hash para senha
htpasswd -nb admin your_password_here
```

### 4. Configurar Traefik

Certifique-se de que o Traefik está configurado com:

```yaml
# docker-compose.yml do Traefik
version: '3.8'

services:
  traefik:
    image: traefik:v2.10
    command:
      - --api.dashboard=true
      - --providers.docker=true
      - --providers.docker.exposedbydefault=false
      - --entrypoints.web.address=:80
      - --entrypoints.websecure.address=:443
      - --certificatesresolvers.letsencrypt.acme.tlschallenge=true
      - --certificatesresolvers.letsencrypt.acme.email=admin@gwan.com.br
      - --certificatesresolvers.letsencrypt.acme.storage=/letsencrypt/acme.json
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro
      - ./letsencrypt:/letsencrypt
    networks:
      - gwan
```

## 🚀 Deploy

### Deploy Automático

```bash
# Tornar script executável
chmod +x scripts/deploy-prod.sh

# Executar deploy
./scripts/deploy-prod.sh
```

### Deploy Manual

```bash
# 1. Parar containers existentes
docker-compose -f docker-compose.prod.yml --env-file .env.prod down

# 2. Atualizar imagens
docker-compose -f docker-compose.prod.yml --env-file .env.prod pull

# 3. Iniciar containers
docker-compose -f docker-compose.prod.yml --env-file .env.prod up -d

# 4. Verificar status
docker-compose -f docker-compose.prod.yml --env-file .env.prod ps
```

## 🔍 Verificação

### Verificar Saúde do Sistema

```bash
# Executar health check
./scripts/health-check-prod.sh
```

### Verificar Acessibilidade

- **Dashboard**: https://cache.gwan.com.br
- **Redis Commander**: https://cache.gwan.com.br/commander
- **Redis Insight**: https://cache.gwan.com.br/insight

### Verificar Logs

```bash
# Logs de todos os serviços
docker-compose -f docker-compose.prod.yml --env-file .env.prod logs -f

# Logs específicos
docker-compose -f docker-compose.prod.yml --env-file .env.prod logs -f redis
```

## 🔒 Segurança

### Configurações de Segurança Implementadas

1. **Autenticação Básica**: Todas as interfaces protegidas
2. **SSL/TLS**: Certificados Let's Encrypt automáticos
3. **Senha Redis**: Configurada via variável de ambiente
4. **Comandos Perigosos**: Renomeados no Redis
5. **Protected Mode**: Habilitado no Redis
6. **Headers de Segurança**: Configurados no Nginx

### Recomendações Adicionais

1. **Firewall**: Configure regras para permitir apenas portas necessárias
2. **Monitoramento**: Implemente alertas para métricas críticas
3. **Backup**: Configure backups automáticos regulares
4. **Logs**: Configure rotação e retenção de logs
5. **Updates**: Mantenha imagens Docker atualizadas

## 📊 Monitoramento

### Métricas Importantes

- **Uso de Memória**: < 80%
- **Hit Ratio**: > 90%
- **Conexões**: < 80% do limite
- **Latência**: < 10ms
- **Disco**: < 80% de uso

### Alertas Recomendados

```bash
# Script de monitoramento
./scripts/monitor-prod.sh

# Verificação contínua
watch -n 30 './scripts/health-check-prod.sh'
```

## 🔄 Manutenção

### Backup

```bash
# Backup manual
./scripts/backup-prod.sh

# Backup automático (cron)
0 2 * * * /path/to/gwan-cache/scripts/backup-prod.sh
```

### Atualizações

```bash
# Atualizar imagens
docker-compose -f docker-compose.prod.yml --env-file .env.prod pull

# Reiniciar com novas imagens
docker-compose -f docker-compose.prod.yml --env-file .env.prod up -d
```

### Limpeza

```bash
# Limpar imagens não utilizadas
docker image prune -f

# Limpar volumes não utilizados
docker volume prune -f

# Limpeza completa
docker system prune -af
```

## 🚨 Troubleshooting

### Problemas Comuns

**1. Containers não iniciam**
```bash
# Verificar logs
docker-compose -f docker-compose.prod.yml --env-file .env.prod logs

# Verificar configuração
docker-compose -f docker-compose.prod.yml --env-file .env.prod config
```

**2. SSL não funciona**
```bash
# Verificar certificados do Traefik
docker logs traefik

# Verificar DNS
nslookup cache.gwan.com.br
```

**3. Redis não responde**
```bash
# Verificar conectividade
docker-compose -f docker-compose.prod.yml --env-file .env.prod exec redis redis-cli ping

# Verificar configuração
docker-compose -f docker-compose.prod.yml --env-file .env.prod exec redis redis-cli config get "*"
```

**4. Interfaces web não acessíveis**
```bash
# Verificar Traefik
curl -I https://cache.gwan.com.br

# Verificar containers
docker-compose -f docker-compose.prod.yml --env-file .env.prod ps
```

### Logs de Debug

```bash
# Habilitar logs detalhados
export LOG_LEVEL=debug

# Verificar logs do Traefik
docker logs traefik --tail 100

# Verificar logs do Redis
docker-compose -f docker-compose.prod.yml --env-file .env.prod logs redis --tail 100
```

## 📈 Performance

### Otimizações Implementadas

1. **Redis**: Configuração otimizada para produção
2. **Nginx**: Compressão e cache habilitados
3. **Docker**: Recursos limitados e otimizados
4. **Rede**: Rede dedicada para comunicação

### Tuning Adicional

```bash
# Ajustar memória do Redis
docker-compose -f docker-compose.prod.yml --env-file .env.prod exec redis redis-cli config set maxmemory 8gb

# Ajustar política de eviction
docker-compose -f docker-compose.prod.yml --env-file .env.prod exec redis redis-cli config set maxmemory-policy allkeys-lru
```

## 🔄 Rollback

### Procedimento de Rollback

```bash
# 1. Parar containers atuais
docker-compose -f docker-compose.prod.yml --env-file .env.prod down

# 2. Restaurar backup
./scripts/restore-prod.sh

# 3. Iniciar versão anterior
docker-compose -f docker-compose.prod.yml --env-file .env.prod up -d
```

## 📞 Suporte

### Contatos de Emergência

- **Equipe de Infraestrutura**: infra@gwan.com.br
- **On-call**: +55 11 99999-9999
- **Slack**: #infra-emergency

### Documentação Adicional

- [Guia de Administração](ADMINISTRATION.md)
- [Troubleshooting](TROUBLESHOOTING.md)
- [Documentação do Redis](https://redis.io/documentation)
- [Documentação do Traefik](https://doc.traefik.io/traefik/)

---

**Última atualização**: $(date)
**Versão**: 1.0
**Responsável**: Equipe de Infraestrutura
