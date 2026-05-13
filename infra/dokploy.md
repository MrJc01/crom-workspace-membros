# 🐳 Dokploy — Infraestrutura de Containers CROM

> Plataforma de deploy de containers para parceiros e projetos internos da CROM.

---

## Status

| Item | Valor |
|------|-------|
| **Painel** | [https://dokploy.crom.me](https://dokploy.crom.me) |
| **VPS** | Guardiões (`srv1180403`) |
| **IP** | `76.13.165.69` |
| **Porta do Painel** | `3000` |
| **Proxy** | Traefik (integrado ao Dokploy) |
| **SSL** | Automático via Let's Encrypt (Traefik) |

---

## Arquitetura

```
Internet
  │
  ▼
Traefik (80/443) ── SSL automático ── Let's Encrypt
  │
  ├── crom.me          → Container Nginx (estático)
  ├── cromia-api.crom.me → Serviço externo (Go, porta 8085)
  ├── dokploy.crom.me  → Painel Dokploy (porta 3000)
  └── *.crom.me        → Containers de parceiros (dinâmico)
```

---

## Portas Utilizadas

| Porta | Serviço | Tipo |
|-------|---------|------|
| 80 | Traefik HTTP | Público |
| 443 | Traefik HTTPS | Público |
| 3000 | Dokploy Painel | Restrito (UFW) |
| 5432 | Postgres Dokploy | Interno Docker |
| 8085 | CromIA API | Interno (Systemd) |

---

## Fluxo de Deploy para Parceiros

1. O parceiro envia o código para o repositório vinculado (GitHub/Gitea)
2. O Dokploy detecta o push via Webhook
3. O container é buildado automaticamente
4. O Traefik gera SSL e serve via subdomínio (ex: `parceiro.crom.me`)

### Subindo um Projeto Novo

1. Acesse [dokploy.crom.me](https://dokploy.crom.me) com sua conta
2. Crie um **Projeto** → **Application**
3. Vincule o repositório Git ou imagem Docker
4. Na aba **Domains**, adicione o subdomínio desejado
5. Clique em **Deploy** — o Traefik configura SSL automaticamente

---

## Backup

| Item | Frequência | Retenção | Local |
|------|-----------|----------|-------|
| Postgres Dokploy | Diário (03:00) | 14 dias | `/var/backups/dokploy/` |
| Logs | Contínuo | — | `/var/log/dokploy/` |

### Restaurar Backup

```bash
# Listar backups disponíveis
ls -lah /var/backups/dokploy/

# Restaurar
gunzip -c /var/backups/dokploy/dokploy-db-YYYY-MM-DD-HHMM.sql.gz | \
  docker exec -i <postgres-container> psql -U postgres
```

---

## Segurança

- **Isolamento**: Cada container roda em Docker Network isolada
- **Firewall**: Porta 3000 restrita por IP via UFW
- **SSL**: Automático via Traefik + Let's Encrypt
- **API**: Acesso via `x-api-key` (gerada no painel)
- **Logs**: Centralizados em `/var/log/dokploy/`

---

## Integração CromIA

| Componente | Endpoint |
|-----------|----------|
| API Dokploy | `https://dokploy.crom.me/api/` |
| Swagger | `https://dokploy.crom.me/swagger` |
| Auth Header | `x-api-key: <token>` |

---

## Scripts

| Script | Propósito |
|--------|-----------|
| `scripts/dokploy/01-backup-pre-install.sh` | Backup antes da instalação |
| `scripts/dokploy/02-install-dokploy.sh` | Instalação e migração |
| `scripts/dokploy/03-setup-backup.sh` | Configura cron de backup |
| `scripts/dokploy/04-rollback.sh` | Reverte para Nginx original |
| `scripts/dokploy/05-verify.sh` | Verificação pós-deploy |

---

*Documento mantido pelos Guardiões da CROM.*
