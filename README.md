# Gwan Cache - Documentação de Administração

Este projeto fornece uma solução completa para administração de cache Redis usando Docker, incluindo ferramentas de monitoramento, backup e interface web para gerenciamento.

## 🚀 Início Rápido

### Pré-requisitos

- Docker e Docker Compose instalados
- Git (opcional)

### Instalação - Desenvolvimento

1. **Clone o repositório:**
   ```bash
   git clone <url-do-repositorio>
   cd gwan-cache
   ```

2. **Configure as variáveis de ambiente:**
   ```bash
   cp env.example .env
   # Edite o arquivo .env com suas configurações
   ```

3. **Inicie o ambiente:**
   ```bash
   # No Windows (PowerShell)
   .\scripts\start.sh
   
   # No Linux/Mac
   ./scripts/start.sh
   ```

### Instalação - Produção

1. **Configure o ambiente de produção:**
   ```bash
   cp env.prod.example .env.prod
   # Edite o arquivo .env.prod com suas configurações
   ```

2. **Execute o deploy:**
   ```bash
   ./scripts/deploy-prod.sh
   ```

3. **Acesse os serviços:**
   - Dashboard: https://cache.gwan.com.br
   - Redis Commander: https://cache.gwan.com.br/commander
   - Redis Insight: https://cache.gwan.com.br/insight

### Serviços Disponíveis

Após a inicialização, os seguintes serviços estarão disponíveis:

- **Redis**: `localhost:6379`
- **Redis Commander** (Interface Web): `http://localhost:8081`
- **Redis Insight** (Interface Avançada): `http://localhost:8001`

**Nota**: Os containers utilizam a rede externa `gwan` para comunicação entre serviços.

## 📋 Estrutura do Projeto

```
gwan-cache/
├── config/
│   └── redis.conf          # Configuração do Redis
├── scripts/
│   ├── start.sh            # Script para iniciar o ambiente
│   ├── stop.sh             # Script para parar o ambiente
│   ├── backup.sh           # Script para backup
│   ├── restore.sh          # Script para restore
│   └── monitor.sh          # Script para monitoramento
├── backups/                # Diretório para backups (criado automaticamente)
├── docker-compose.yml      # Configuração do Docker Compose
├── env.example             # Exemplo de variáveis de ambiente
└── README.md               # Esta documentação
```

## 🔧 Configuração

### Variáveis de Ambiente

Edite o arquivo `.env` com as seguintes configurações:

```env
# Configurações do Redis
REDIS_PASSWORD=your_strong_password_here

# Configurações do Redis Commander
REDIS_COMMANDER_USER=admin
REDIS_COMMANDER_PASSWORD=admin123

# Configurações de ambiente
NODE_ENV=development
```

### Configuração do Redis

O arquivo `config/redis.conf` contém as configurações do Redis. Principais configurações:

- **Memória**: 2GB máximo com política LRU
- **Persistência**: RDB + AOF habilitados
- **Segurança**: Senha configurável
- **Performance**: Otimizado para produção

## 🛠️ Scripts de Administração

### Iniciar Ambiente
```bash
./scripts/start.sh
```
- Verifica dependências
- Inicia todos os containers
- Verifica saúde dos serviços
- Exibe informações de acesso

### Parar Ambiente
```bash
./scripts/stop.sh
```
- Para todos os containers
- Mantém dados persistentes

### Backup
```bash
./scripts/backup.sh
```
- Cria backup completo do Redis
- Comprime automaticamente
- Mantém apenas os 10 backups mais recentes
- Salva em `./backups/`

### Restore
```bash
./scripts/restore.sh
```
- Lista backups disponíveis
- Permite seleção interativa
- Restaura dados com confirmação
- Verifica integridade após restore

### Monitoramento
```bash
./scripts/monitor.sh [comando]
```

Comandos disponíveis:
- `info` - Informações gerais (padrão)
- `keys` - Top keys por tamanho
- `config` - Configurações importantes
- `monitor` - Monitoramento contínuo
- `all` - Todas as informações

## 📊 Monitoramento e Administração

### Redis Commander

Interface web simples para administração:
- URL: `http://localhost:8081`
- Usuário: `admin` (configurável)
- Senha: `admin123` (configurável)

Funcionalidades:
- Visualização de keys
- Execução de comandos
- Monitoramento em tempo real
- Gerenciamento de conexões

### Redis Insight

Interface avançada para análise:
- URL: `http://localhost:8001`
- Análise de performance
- Visualização de dados
- Relatórios detalhados
- Profiling de comandos

### Comandos Redis Úteis

```bash
# Conectar ao Redis
docker-compose exec redis redis-cli

# Com senha
docker-compose exec redis redis-cli -a your_password

# Informações do servidor
docker-compose exec redis redis-cli info

# Listar todas as keys
docker-compose exec redis redis-cli keys "*"

# Limpar banco
docker-compose exec redis redis-cli flushdb

# Limpar todos os bancos
docker-compose exec redis redis-cli flushall

# Monitorar comandos em tempo real
docker-compose exec redis redis-cli monitor
```

## 🔒 Segurança

### Configurações de Segurança

1. **Altere a senha padrão** no arquivo `.env`
2. **Configure firewall** para proteger as portas
3. **Use TLS** em produção (configuração adicional necessária)
4. **Limite acesso** às interfaces web

### Comandos de Segurança

```bash
# Renomear comandos perigosos (descomente no redis.conf)
# rename-command FLUSHDB ""
# rename-command FLUSHALL ""
# rename-command CONFIG ""

# Configurar ACL (Redis 6+)
docker-compose exec redis redis-cli acl setuser myuser on >mypassword ~* &* +@all
```

## 🚨 Troubleshooting

### Problemas Comuns

**Redis não inicia:**
```bash
# Verificar logs
docker-compose logs redis

# Verificar configuração
docker-compose exec redis redis-cli config get "*"
```

**Porta já em uso:**
```bash
# Verificar processos usando a porta
netstat -tulpn | grep :6379

# Alterar porta no docker-compose.yml
```

**Problemas de memória:**
```bash
# Verificar uso de memória
docker-compose exec redis redis-cli info memory

# Ajustar maxmemory no redis.conf
```

**Backup falha:**
```bash
# Verificar espaço em disco
df -h

# Verificar permissões
ls -la backups/
```

### Logs e Debugging

```bash
# Logs em tempo real
docker-compose logs -f redis

# Logs específicos
docker-compose logs redis | grep ERROR

# Entrar no container
docker-compose exec redis sh
```

## 📈 Performance

### Otimizações Recomendadas

1. **Memória**: Ajuste `maxmemory` conforme necessário
2. **Persistência**: Configure `save` para seu caso de uso
3. **Rede**: Use `tcp-keepalive` para conexões estáveis
4. **Monitoramento**: Configure alertas para métricas críticas

### Métricas Importantes

- **Uso de memória**: `used_memory_human`
- **Hit ratio**: `keyspace_hits / (keyspace_hits + keyspace_misses)`
- **Conexões**: `connected_clients`
- **Comandos por segundo**: `instantaneous_ops_per_sec`

## 🔄 Manutenção

### Tarefas Regulares

1. **Backup diário**: Configure cron job
2. **Limpeza de logs**: Rotacione logs antigos
3. **Monitoramento**: Verifique métricas regularmente
4. **Atualizações**: Mantenha imagens Docker atualizadas

### Exemplo de Cron Job

```bash
# Backup diário às 2:00 AM
0 2 * * * /path/to/gwan-cache/scripts/backup.sh

# Limpeza semanal de logs
0 3 * * 0 docker system prune -f
```

## 📚 Recursos Adicionais

- [Documentação oficial do Redis](https://redis.io/documentation)
- [Redis Commander](https://github.com/joeferner/redis-commander)
- [Redis Insight](https://redislabs.com/redis-enterprise/redis-insight/)
- [Docker Compose](https://docs.docker.com/compose/)
- [Guia de Produção](docs/PRODUCTION.md)
- [Guia de Administração](docs/ADMINISTRATION.md)
- [Troubleshooting](docs/TROUBLESHOOTING.md)

## 🤝 Contribuição

1. Fork o projeto
2. Crie uma branch para sua feature
3. Commit suas mudanças
4. Push para a branch
5. Abra um Pull Request

## 📄 Licença

Este projeto está sob a licença MIT. Veja o arquivo `LICENSE` para mais detalhes.

## 📞 Suporte

Para suporte e dúvidas:
- Abra uma issue no repositório
- Consulte a documentação oficial do Redis
- Verifique os logs para troubleshooting

---

**Gwan Cache Administration** - Solução completa para administração de cache Redis
