# 🚀 Deploy no Portainer - Gwan Cache

## ✅ Configuração Completa para Portainer

Este guia mostra como fazer o deploy do **Gwan Cache** usando o **Portainer** com Git e variáveis de ambiente.

## 📋 Pré-requisitos

- Portainer instalado e configurado
- Rede Docker `gwan` criada
- Traefik configurado e rodando
- Domínio `cache.gwan.com.br` apontando para o servidor
- Repositório Git com o código

## 🔧 Configuração no Portainer

### 1. Acessar o Portainer
- Abra o Portainer no navegador
- Faça login com suas credenciais
- Vá para **Stacks** → **Add stack**

### 2. Configurar o Git
```
Stack name: gwan-cache-prod
Repository URL: https://github.com/rastamansp/gwan-cache.git
Compose file path: docker-compose.portainer.yml
```

**Nota**: Use `docker-compose.portainer.yml` que é a versão mais simples e compatível com o Portainer.

### 3. Configurar Variáveis de Ambiente

#### Opção A: Importar arquivo
- Clique em **Environment variables**
- **Import from file** → Selecione o arquivo `env.prod`
- Clique em **Import**

#### Opção B: Adicionar manualmente
Adicione as seguintes variáveis:

```
REDIS_PASSWORD=pazdeDeus
REDIS_COMMANDER_USER=admin
REDIS_COMMANDER_PASSWORD=pazdeDeus
REDIS_COMMANDER_AUTH=admin:$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi
REDIS_INSIGHT_AUTH=admin:$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi
DASHBOARD_AUTH=admin:$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi
NODE_ENV=production
```

### 4. Deploy
- Clique em **Deploy the stack**
- Aguarde o deploy ser concluído

## 🔍 Verificação do Deploy

### 1. Verificar Containers
- Vá para **Containers**
- Verifique se os containers estão rodando:
  - `gwan-cache-redis-prod`
  - `gwan-cache-commander-prod`
  - `gwan-cache-insight-prod`
  - `gwan-cache-dashboard-prod`

### 2. Verificar Logs
- Clique em cada container
- Vá para **Logs**
- Verifique se não há erros

### 3. Testar Acessibilidade
- **Dashboard**: https://cache.gwan.com.br
- **Redis Commander**: https://cache.gwan.com.br/commander
- **Redis Insight**: https://cache.gwan.com.br/insight

## 🔧 Configurações Avançadas

### Rede Docker
Certifique-se de que a rede `gwan` existe:
```bash
docker network create gwan
```

### Traefik
O Traefik deve estar configurado com:
- Let's Encrypt habilitado
- Rede `gwan` configurada
- Entrypoints `websecure` na porta 443

### Volumes
Os volumes serão criados automaticamente:
- `gwan-cache_redis_data_prod`
- `gwan-cache_redis_insight_data_prod`

## 🚨 Troubleshooting

### Problema: Containers não iniciam
**Solução:**
1. Verifique os logs no Portainer
2. Verifique se a rede `gwan` existe
3. Verifique se as variáveis de ambiente estão corretas

### Problema: "undefined network gwan"
**Solução:**
1. Use o arquivo `docker-compose.prod-portainer.yml` que cria a rede automaticamente
2. Ou crie a rede manualmente:
   ```bash
   docker network create gwan
   ```

### Problema: "error mounting config files"
**Solução:**
1. Use o arquivo `docker-compose.portainer.yml` que não depende de arquivos externos
2. Este arquivo tem todas as configurações embutidas no próprio docker-compose
3. Não há dashboard para evitar problemas de montagem
4. Acesse diretamente o Redis Commander e Redis Insight

### Problema: SSL não funciona
**Solução:**
1. Verifique se o Traefik está rodando
2. Verifique se o domínio aponta para o servidor
3. Verifique os logs do Traefik

### Problema: Interfaces não acessíveis
**Solução:**
1. Verifique se os containers estão rodando
2. Verifique as labels do Traefik
3. Verifique se a autenticação está configurada

## 📊 Monitoramento

### Logs no Portainer
- Acesse **Containers** → Selecione o container → **Logs**
- Use **Follow logs** para logs em tempo real

### Métricas
- Acesse **Containers** → Selecione o container → **Stats**
- Monitore CPU, memória e rede

### Health Checks
- Os containers têm health checks configurados
- Verifique o status em **Containers**

## 🔄 Atualizações

### Atualizar via Git
1. Faça commit das mudanças no Git
2. No Portainer, vá para **Stacks** → `gwan-cache-prod`
3. Clique em **Editor**
4. Clique em **Update the stack**

### Atualizar variáveis
1. Vá para **Stacks** → `gwan-cache-prod`
2. Clique em **Editor**
3. Modifique as variáveis de ambiente
4. Clique em **Update the stack`

## 🔒 Segurança

### Variáveis Sensíveis
- Use **Secrets** do Portainer para senhas
- Não commite senhas no Git
- Use variáveis de ambiente para configurações

### Autenticação
- Todas as interfaces têm autenticação básica
- Senhas são hasheadas com bcrypt
- SSL/TLS obrigatório via Traefik

## 📈 Escalabilidade

### Adicionar Mais Instâncias
1. Modifique o `docker-compose.prod.yml`
2. Adicione mais serviços
3. Atualize no Portainer

### Load Balancing
- Use o Traefik para load balancing
- Configure múltiplas instâncias
- Use health checks

## 🆘 Suporte

### Logs Importantes
```bash
# Logs do Redis
docker logs gwan-cache-redis-prod

# Logs do Traefik
docker logs traefik

# Logs do Portainer
docker logs portainer
```

### Comandos Úteis
```bash
# Verificar rede
docker network ls | grep gwan

# Verificar volumes
docker volume ls | grep gwan-cache

# Verificar containers
docker ps | grep gwan-cache
```

## ✅ Checklist de Deploy

- [ ] Rede `gwan` criada
- [ ] Traefik configurado e rodando
- [ ] Domínio `cache.gwan.com.br` apontando para o servidor
- [ ] Repositório Git configurado
- [ ] Variáveis de ambiente configuradas
- [ ] Stack deployada no Portainer
- [ ] Containers rodando
- [ ] Logs sem erros
- [ ] Interfaces acessíveis
- [ ] SSL funcionando
- [ ] Autenticação funcionando

## 🎉 Deploy Concluído!

Após seguir este guia, você terá:
- ✅ Redis rodando em produção
- ✅ Interfaces web acessíveis
- ✅ SSL/TLS automático
- ✅ Autenticação segura
- ✅ Monitoramento via Portainer
- ✅ Deploy automatizado via Git

---

**Gwan Cache Administration** - Deploy via Portainer
