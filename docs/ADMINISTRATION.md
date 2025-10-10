# Guia de Administração - Gwan Cache

## 📖 Visão Geral

Este documento fornece um guia detalhado para administradores do sistema de cache Redis da aplicação Gwan. Aqui você encontrará informações sobre configuração, monitoramento, manutenção e troubleshooting.

## 🏗️ Arquitetura

### Componentes do Sistema

1. **Redis Server**: Servidor de cache principal
2. **Redis Commander**: Interface web para administração
3. **Redis Insight**: Ferramenta avançada de análise
4. **Scripts de Administração**: Automação de tarefas

### Fluxo de Dados

```
Aplicação → Redis Server → Persistência (RDB/AOF)
                ↓
        Redis Commander/Insight (Monitoramento)
```

## ⚙️ Configuração Detalhada

### Configurações de Memória

```conf
# config/redis.conf
maxmemory 2gb
maxmemory-policy allkeys-lru
maxmemory-samples 5
```

**Políticas de Eviction:**
- `allkeys-lru`: Remove keys menos usadas recentemente
- `allkeys-lfu`: Remove keys menos usadas frequentemente
- `volatile-lru`: Remove apenas keys com TTL
- `noeviction`: Não remove keys (pode causar OOM)

### Configurações de Persistência

```conf
# RDB (Snapshot)
save 900 1      # Salva se 1+ keys mudaram em 15min
save 300 10     # Salva se 10+ keys mudaram em 5min
save 60 10000   # Salva se 10000+ keys mudaram em 1min

# AOF (Append Only File)
appendonly yes
appendfsync everysec
auto-aof-rewrite-percentage 100
auto-aof-rewrite-min-size 64mb
```

### Configurações de Segurança

```conf
# Senha
requirepass your_strong_password_here

# Comandos perigosos
rename-command FLUSHDB ""
rename-command FLUSHALL ""
rename-command CONFIG ""
rename-command DEBUG ""
```

## 📊 Monitoramento

### Métricas Essenciais

#### Memória
```bash
# Uso atual de memória
redis-cli info memory | grep used_memory_human

# Pico de uso
redis-cli info memory | grep used_memory_peak_human

# Fragmentação
redis-cli info memory | grep mem_fragmentation_ratio
```

#### Performance
```bash
# Comandos por segundo
redis-cli info stats | grep instantaneous_ops_per_sec

# Hit ratio
redis-cli info stats | grep -E "(keyspace_hits|keyspace_misses)"

# Latência
redis-cli --latency-history -i 1
```

#### Conexões
```bash
# Clientes conectados
redis-cli info clients | grep connected_clients

# Clientes bloqueados
redis-cli info clients | grep blocked_clients
```

### Alertas Recomendados

1. **Uso de memória > 80%**
2. **Hit ratio < 90%**
3. **Conexões > 8000**
4. **Latência > 10ms**
5. **Falhas de persistência**

## 🔧 Manutenção

### Tarefas Diárias

```bash
# Verificar saúde do sistema
./scripts/monitor.sh info

# Backup automático
./scripts/backup.sh

# Verificar logs de erro
docker-compose logs redis | grep ERROR
```

### Tarefas Semanais

```bash
# Análise de performance
./scripts/monitor.sh all

# Limpeza de logs antigos
docker system prune -f

# Verificação de integridade
docker-compose exec redis redis-cli --rdb /tmp/dump.rdb
```

### Tarefas Mensais

```bash
# Análise de crescimento de dados
redis-cli info keyspace

# Otimização de configurações
# Revisar métricas de performance
# Atualizar documentação
```

## 🚨 Troubleshooting

### Problemas de Memória

**Sintomas:**
- Erro "OOM command not allowed"
- Alto uso de memória
- Performance degradada

**Soluções:**
```bash
# Verificar uso atual
redis-cli info memory

# Aumentar memória (se possível)
# Editar docker-compose.yml
# maxmemory 4gb

# Ou otimizar dados
redis-cli --bigkeys
redis-cli --scan --pattern "*" | head -1000 | xargs redis-cli del
```

### Problemas de Performance

**Sintomas:**
- Alta latência
- Baixo throughput
- Timeouts

**Diagnóstico:**
```bash
# Monitorar comandos lentos
redis-cli slowlog get 10

# Verificar latência
redis-cli --latency

# Analisar comandos em tempo real
redis-cli monitor
```

**Soluções:**
- Otimizar queries da aplicação
- Usar pipelines para operações em lote
- Implementar connection pooling
- Considerar sharding para grandes datasets

### Problemas de Persistência

**Sintomas:**
- Dados perdidos após restart
- Falhas de backup
- AOF corrompido

**Diagnóstico:**
```bash
# Verificar status de persistência
redis-cli info persistence

# Verificar último save
redis-cli info persistence | grep rdb_last_save_time

# Verificar AOF
redis-cli config get appendonly
```

**Soluções:**
```bash
# Forçar save manual
redis-cli bgsave

# Reparar AOF
redis-cli --rdb /tmp/backup.rdb
redis-server --appendonly yes --appendfilename appendonly.aof
```

## 🔄 Backup e Recovery

### Estratégia de Backup

1. **Backup RDB**: Diário, automático
2. **Backup AOF**: Contínuo, incremental
3. **Backup Manual**: Antes de mudanças importantes
4. **Teste de Restore**: Mensal

### Procedimento de Backup

```bash
# Backup automático
./scripts/backup.sh

# Backup manual com timestamp
redis-cli bgsave
docker cp gwan-cache-redis:/data/dump.rdb ./backups/manual_$(date +%Y%m%d_%H%M%S).rdb
```

### Procedimento de Recovery

```bash
# Listar backups disponíveis
ls -la backups/

# Restaurar backup
./scripts/restore.sh

# Verificar integridade
redis-cli info keyspace
redis-cli ping
```

## 🔒 Segurança

### Hardening do Redis

1. **Autenticação**
   ```conf
   requirepass complex_password_here
   ```

2. **ACL (Redis 6+)**
   ```bash
   redis-cli acl setuser appuser on >apppassword ~app:* &* +@read +@write +@keyspace
   ```

3. **Network Security**
   ```conf
   bind 127.0.0.1
   protected-mode yes
   ```

4. **Command Renaming**
   ```conf
   rename-command FLUSHDB ""
   rename-command FLUSHALL ""
   rename-command CONFIG ""
   ```

### Auditoria

```bash
# Log de comandos perigosos
redis-cli config set notify-keyspace-events Ex

# Monitoramento de acesso
redis-cli monitor | grep -E "(FLUSH|CONFIG|DEBUG)"
```

## 📈 Otimização

### Performance Tuning

1. **Memory Optimization**
   ```conf
   hash-max-ziplist-entries 512
   hash-max-ziplist-value 64
   list-max-ziplist-size -2
   set-max-intset-entries 512
   ```

2. **Network Optimization**
   ```conf
   tcp-keepalive 300
   timeout 0
   ```

3. **Persistence Optimization**
   ```conf
   save ""  # Desabilitar saves automáticos se não necessário
   appendfsync no  # Para melhor performance (mais risco)
   ```

### Scaling

1. **Vertical Scaling**
   - Aumentar memória
   - Usar SSD para persistência
   - Otimizar configurações

2. **Horizontal Scaling**
   - Redis Cluster
   - Redis Sentinel
   - Sharding manual

## 📋 Checklist de Manutenção

### Diário
- [ ] Verificar saúde dos serviços
- [ ] Executar backup
- [ ] Verificar logs de erro
- [ ] Monitorar métricas básicas

### Semanal
- [ ] Análise completa de performance
- [ ] Limpeza de logs antigos
- [ ] Verificação de espaço em disco
- [ ] Teste de conectividade

### Mensal
- [ ] Análise de crescimento de dados
- [ ] Revisão de configurações
- [ ] Teste de restore
- [ ] Atualização de documentação
- [ ] Revisão de segurança

### Trimestral
- [ ] Auditoria de segurança
- [ ] Análise de capacidade
- [ ] Planejamento de upgrades
- [ ] Revisão de SLA

## 🆘 Procedimentos de Emergência

### Redis Indisponível

1. **Diagnóstico Rápido**
   ```bash
   docker-compose ps
   docker-compose logs redis
   ```

2. **Restart de Emergência**
   ```bash
   docker-compose restart redis
   ```

3. **Recovery de Dados**
   ```bash
   ./scripts/restore.sh
   ```

### Perda de Dados

1. **Parar Aplicação**
2. **Identificar Último Backup Válido**
3. **Restaurar Backup**
4. **Verificar Integridade**
5. **Reiniciar Aplicação**

### Performance Crítica

1. **Identificar Causa**
   ```bash
   redis-cli slowlog get 10
   redis-cli monitor
   ```

2. **Ações Imediatas**
   - Limpar cache se necessário
   - Restart do Redis
   - Escalar recursos

3. **Análise Pós-Incidente**
   - Root cause analysis
   - Implementar melhorias
   - Atualizar procedimentos

---

**Última atualização**: $(date)
**Versão**: 1.0
**Responsável**: Equipe de Infraestrutura
