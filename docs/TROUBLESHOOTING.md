# Guia de Troubleshooting - Gwan Cache

## 🚨 Problemas Comuns e Soluções

Este documento contém soluções para os problemas mais frequentes encontrados na administração do sistema de cache Redis.

## 📋 Índice de Problemas

1. [Problemas de Inicialização](#problemas-de-inicialização)
2. [Problemas de Memória](#problemas-de-memória)
3. [Problemas de Performance](#problemas-de-performance)
4. [Problemas de Conectividade](#problemas-de-conectividade)
5. [Problemas de Persistência](#problemas-de-persistência)
6. [Problemas de Segurança](#problemas-de-segurança)
7. [Problemas de Backup/Restore](#problemas-de-backuprestore)

## 🚀 Problemas de Inicialização

### Redis não inicia

**Sintomas:**
- Container não sobe
- Erro de configuração
- Porta já em uso

**Diagnóstico:**
```bash
# Verificar logs do container
docker-compose logs redis

# Verificar se a porta está em uso
netstat -tulpn | grep :6379
# ou no Windows
netstat -an | findstr :6379

# Verificar configuração
docker-compose config
```

**Soluções:**

1. **Porta em uso:**
   ```bash
   # Encontrar processo usando a porta
   lsof -i :6379
   # ou no Windows
   netstat -ano | findstr :6379
   
   # Matar processo ou alterar porta no docker-compose.yml
   ```

2. **Erro de configuração:**
   ```bash
   # Verificar sintaxe do redis.conf
   docker-compose exec redis redis-server --test-config /usr/local/etc/redis/redis.conf
   
   # Verificar permissões do arquivo
   ls -la config/redis.conf
   ```

3. **Problemas de volume:**
   ```bash
   # Recriar volumes
   docker-compose down -v
   docker-compose up -d
   ```

### Redis Commander não acessível

**Sintomas:**
- Interface web não carrega
- Erro de autenticação
- Timeout de conexão

**Diagnóstico:**
```bash
# Verificar se o container está rodando
docker-compose ps redis-commander

# Verificar logs
docker-compose logs redis-commander

# Testar conectividade
curl http://localhost:8081
```

**Soluções:**

1. **Problema de conectividade:**
   ```bash
   # Verificar se Redis está acessível
   docker-compose exec redis-commander ping redis
   
   # Reiniciar commander
   docker-compose restart redis-commander
   ```

2. **Problema de autenticação:**
   ```bash
   # Verificar variáveis de ambiente
   docker-compose exec redis-commander env | grep REDIS
   
   # Recriar container com novas credenciais
   docker-compose down redis-commander
   docker-compose up -d redis-commander
   ```

## 💾 Problemas de Memória

### Out of Memory (OOM)

**Sintomas:**
- Erro "OOM command not allowed"
- Redis rejeita comandos
- Performance degradada

**Diagnóstico:**
```bash
# Verificar uso de memória
redis-cli info memory

# Verificar configuração de memória
redis-cli config get maxmemory

# Verificar política de eviction
redis-cli config get maxmemory-policy
```

**Soluções:**

1. **Aumentar memória:**
   ```bash
   # Editar docker-compose.yml
   # Adicionar: - maxmemory=4gb
   
   # Ou via comando
   redis-cli config set maxmemory 4gb
   ```

2. **Otimizar dados:**
   ```bash
   # Encontrar keys grandes
   redis-cli --bigkeys
   
   # Limpar keys desnecessárias
   redis-cli --scan --pattern "temp:*" | xargs redis-cli del
   ```

3. **Ajustar política de eviction:**
   ```bash
   # Para dados que podem ser recriados
   redis-cli config set maxmemory-policy allkeys-lru
   
   # Para dados críticos
   redis-cli config set maxmemory-policy volatile-lru
   ```

### Fragmentação de Memória

**Sintomas:**
- Alto uso de memória sem dados correspondentes
- `mem_fragmentation_ratio` > 1.5

**Diagnóstico:**
```bash
# Verificar fragmentação
redis-cli info memory | grep mem_fragmentation_ratio

# Verificar uso real vs alocado
redis-cli info memory | grep -E "(used_memory_human|used_memory_rss_human)"
```

**Soluções:**

1. **Restart do Redis:**
   ```bash
   # Fazer backup primeiro
   ./scripts/backup.sh
   
   # Restart
   docker-compose restart redis
   ```

2. **Limpeza manual:**
   ```bash
   # Forçar limpeza de memória
   redis-cli memory purge
   ```

## ⚡ Problemas de Performance

### Alta Latência

**Sintomas:**
- Comandos lentos
- Timeouts na aplicação
- Usuários reclamando de lentidão

**Diagnóstico:**
```bash
# Verificar latência
redis-cli --latency

# Verificar comandos lentos
redis-cli slowlog get 10

# Monitorar comandos em tempo real
redis-cli monitor
```

**Soluções:**

1. **Otimizar comandos:**
   ```bash
   # Evitar KEYS *, usar SCAN
   redis-cli --scan --pattern "user:*"
   
   # Usar pipelines para operações em lote
   # Evitar operações bloqueantes
   ```

2. **Otimizar configuração:**
   ```bash
   # Aumentar timeout
   redis-cli config set timeout 300
   
   # Otimizar TCP
   redis-cli config set tcp-keepalive 60
   ```

3. **Escalar recursos:**
   ```bash
   # Aumentar CPU/memória no docker-compose.yml
   # Considerar Redis Cluster
   ```

### Baixo Throughput

**Sintomas:**
- Poucos comandos por segundo
- Aplicação lenta
- CPU alta

**Diagnóstico:**
```bash
# Verificar ops por segundo
redis-cli info stats | grep instantaneous_ops_per_sec

# Verificar uso de CPU
docker stats gwan-cache-redis

# Verificar conexões
redis-cli info clients
```

**Soluções:**

1. **Otimizar aplicação:**
   - Usar connection pooling
   - Implementar pipelines
   - Evitar operações síncronas desnecessárias

2. **Otimizar Redis:**
   ```bash
   # Aumentar limite de conexões
   redis-cli config set maxclients 10000
   
   # Otimizar persistência
   redis-cli config set save ""
   ```

## 🌐 Problemas de Conectividade

### Aplicação não consegue conectar

**Sintomas:**
- Erro de conexão na aplicação
- Timeout de conexão
- "Connection refused"

**Diagnóstico:**
```bash
# Verificar se Redis está rodando
docker-compose ps redis

# Testar conectividade
telnet localhost 6379
# ou
nc -zv localhost 6379

# Verificar logs do Redis
docker-compose logs redis | grep -i error
```

**Soluções:**

1. **Problema de rede:**
   ```bash
   # Verificar firewall
   sudo ufw status
   # ou no Windows
   netsh advfirewall show allprofiles
   
   # Verificar bind address
   redis-cli config get bind
   ```

2. **Problema de autenticação:**
   ```bash
   # Verificar senha
   redis-cli -a your_password ping
   
   # Resetar senha se necessário
   redis-cli config set requirepass new_password
   ```

### Muitas conexões

**Sintomas:**
- Erro "max number of clients reached"
- Aplicação lenta
- Conexões não fechadas

**Diagnóstico:**
```bash
# Verificar conexões ativas
redis-cli info clients

# Verificar limite
redis-cli config get maxclients

# Listar conexões
redis-cli client list
```

**Soluções:**

1. **Aumentar limite:**
   ```bash
   redis-cli config set maxclients 10000
   ```

2. **Otimizar aplicação:**
   - Implementar connection pooling
   - Fechar conexões adequadamente
   - Usar conexões persistentes

3. **Limpar conexões órfãs:**
   ```bash
   # Matar conexões idle
   redis-cli client list | grep idle= | awk '{print $2}' | cut -d= -f2 | xargs -I {} redis-cli client kill id {}
   ```

## 💿 Problemas de Persistência

### Dados perdidos após restart

**Sintomas:**
- Cache vazio após reinicialização
- Dados não persistem
- Backup vazio

**Diagnóstico:**
```bash
# Verificar configuração de persistência
redis-cli config get save
redis-cli config get appendonly

# Verificar último save
redis-cli info persistence | grep rdb_last_save_time

# Verificar arquivos de persistência
docker-compose exec redis ls -la /data/
```

**Soluções:**

1. **Habilitar persistência:**
   ```bash
   # RDB
   redis-cli config set save "900 1 300 10 60 10000"
   
   # AOF
   redis-cli config set appendonly yes
   ```

2. **Forçar save:**
   ```bash
   # Save síncrono (bloqueia)
   redis-cli save
   
   # Save assíncrono (não bloqueia)
   redis-cli bgsave
   ```

3. **Verificar permissões:**
   ```bash
   # Verificar permissões do diretório
   docker-compose exec redis ls -la /data/
   
   # Corrigir permissões se necessário
   docker-compose exec redis chmod 755 /data
   ```

### AOF corrompido

**Sintomas:**
- Redis não inicia
- Erro de AOF
- Dados inconsistentes

**Diagnóstico:**
```bash
# Verificar logs de erro
docker-compose logs redis | grep -i aof

# Verificar integridade do AOF
redis-cli --rdb /tmp/test.rdb
```

**Soluções:**

1. **Reparar AOF:**
   ```bash
   # Fazer backup do AOF corrompido
   docker cp gwan-cache-redis:/data/appendonly.aof ./backups/
   
   # Tentar reparar
   redis-check-aof --fix /data/appendonly.aof
   ```

2. **Usar RDB como fallback:**
   ```bash
   # Desabilitar AOF temporariamente
   redis-cli config set appendonly no
   
   # Usar apenas RDB
   redis-cli config set save "60 1000"
   ```

## 🔒 Problemas de Segurança

### Acesso não autorizado

**Sintomas:**
- Dados acessados sem autenticação
- Comandos executados por usuários não autorizados
- Logs de acesso suspeitos

**Diagnóstico:**
```bash
# Verificar configuração de senha
redis-cli config get requirepass

# Verificar comandos renomeados
redis-cli config get rename-command

# Verificar logs de acesso
docker-compose logs redis | grep -i auth
```

**Soluções:**

1. **Configurar autenticação:**
   ```bash
   # Definir senha forte
   redis-cli config set requirepass "strong_password_here"
   
   # Reiniciar para aplicar
   docker-compose restart redis
   ```

2. **Renomear comandos perigosos:**
   ```bash
   # Editar redis.conf
   # rename-command FLUSHDB ""
   # rename-command FLUSHALL ""
   # rename-command CONFIG ""
   ```

3. **Configurar ACL (Redis 6+):**
   ```bash
   # Criar usuário com permissões limitadas
   redis-cli acl setuser appuser on >apppassword ~app:* &* +@read +@write
   ```

### Vazamento de dados

**Sintomas:**
- Dados sensíveis expostos
- Logs contêm informações confidenciais
- Acesso não auditado

**Soluções:**

1. **Auditar acesso:**
   ```bash
   # Habilitar logs de comandos
   redis-cli config set notify-keyspace-events Ex
   
   # Monitorar comandos perigosos
   redis-cli monitor | grep -E "(FLUSH|CONFIG|DEBUG)"
   ```

2. **Criptografar dados sensíveis:**
   - Implementar criptografia na aplicação
   - Usar TLS para conexões
   - Não armazenar dados sensíveis em texto plano

## 💾 Problemas de Backup/Restore

### Backup falha

**Sintomas:**
- Script de backup retorna erro
- Arquivo de backup vazio
- Falta de espaço em disco

**Diagnóstico:**
```bash
# Verificar espaço em disco
df -h

# Verificar permissões
ls -la backups/

# Verificar logs do backup
./scripts/backup.sh 2>&1 | tee backup.log
```

**Soluções:**

1. **Liberar espaço:**
   ```bash
   # Limpar backups antigos
   find backups/ -name "*.gz" -mtime +30 -delete
   
   # Limpar logs do Docker
   docker system prune -f
   ```

2. **Corrigir permissões:**
   ```bash
   # Criar diretório se não existir
   mkdir -p backups/
   
   # Corrigir permissões
   chmod 755 backups/
   ```

3. **Backup manual:**
   ```bash
   # Backup direto
   docker-compose exec redis redis-cli bgsave
   docker cp gwan-cache-redis:/data/dump.rdb ./backups/manual_$(date +%Y%m%d_%H%M%S).rdb
   ```

### Restore falha

**Sintomas:**
- Dados não restaurados
- Redis não inicia após restore
- Inconsistência de dados

**Diagnóstico:**
```bash
# Verificar integridade do backup
file backups/redis_backup_*.rdb.gz

# Verificar logs do restore
./scripts/restore.sh 2>&1 | tee restore.log
```

**Soluções:**

1. **Verificar backup:**
   ```bash
   # Descomprimir e verificar
   gunzip -t backups/redis_backup_*.rdb.gz
   
   # Verificar tamanho
   ls -la backups/
   ```

2. **Restore manual:**
   ```bash
   # Parar Redis
   docker-compose stop redis
   
   # Copiar backup
   docker cp backups/redis_backup_*.rdb gwan-cache-redis:/data/dump.rdb
   
   # Iniciar Redis
   docker-compose start redis
   ```

3. **Verificar integridade:**
   ```bash
   # Verificar se Redis está funcionando
   redis-cli ping
   
   # Verificar dados
   redis-cli info keyspace
   ```

## 🆘 Procedimentos de Emergência

### Redis Completamente Indisponível

1. **Diagnóstico Rápido (2 minutos):**
   ```bash
   docker-compose ps
   docker-compose logs redis --tail 50
   docker stats gwan-cache-redis
   ```

2. **Restart de Emergência (5 minutos):**
   ```bash
   docker-compose restart redis
   sleep 10
   redis-cli ping
   ```

3. **Recovery Completo (15 minutos):**
   ```bash
   ./scripts/restore.sh
   # Selecionar último backup válido
   ```

### Perda Total de Dados

1. **Parar Aplicação Imediatamente**
2. **Identificar Último Backup Válido**
3. **Restaurar Backup**
4. **Verificar Integridade**
5. **Reiniciar Aplicação Gradualmente**

### Ataque de Segurança

1. **Isolar Sistema:**
   ```bash
   # Parar todos os serviços
   docker-compose down
   
   # Bloquear acesso de rede
   # (configurar firewall)
   ```

2. **Preservar Evidências:**
   ```bash
   # Fazer backup dos logs
   docker-compose logs > security_incident_$(date +%Y%m%d_%H%M%S).log
   
   # Fazer backup dos dados
   ./scripts/backup.sh
   ```

3. **Análise e Correção:**
   - Analisar logs
   - Identificar vulnerabilidade
   - Aplicar correções
   - Testar sistema

## 📞 Contatos de Emergência

- **Equipe de Infraestrutura**: infra@gwan.com
- **On-call**: +55 11 99999-9999
- **Slack**: #infra-emergency

## 📚 Recursos Adicionais

- [Documentação oficial do Redis](https://redis.io/documentation)
- [Redis Troubleshooting Guide](https://redis.io/topics/troubleshooting)
- [Redis Performance Optimization](https://redis.io/topics/benchmarks)

---

**Última atualização**: $(date)
**Versão**: 1.0
**Responsável**: Equipe de Infraestrutura
