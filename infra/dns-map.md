# 🌐 Mapeamento DNS — Ecossistema CROM

Referência centralizada de todos os domínios e subdomínios do ecossistema.
**Gerenciado em:** Hostinger → Domínios → crom.me → DNS / Nameservers

> [!IMPORTANT]
> **Consolidação 2026-07-02:** Todas as VPS foram consolidadas na VPS 0 (Guardiões).
> VPS1 (Pilares) e VPS2 (Forja) da Hostzera foram desativadas.
> Backup completo em `~/backups-vps-2026-07-02/`

## Registros Ativos

| Tipo | Nome | IP / Target | VPS | Status |
|------|------|-------------|-----|--------|
| A | `@` | 76.13.165.69 | guardioes | ✅ Ativo |
| CNAME | `www` | crom.me | guardioes | ✅ Ativo |
| A | `*` | 76.13.165.69 | guardioes | ✅ Ativo (wildcard) |
| A | `cromia-api` | 76.13.165.69 | guardioes | ✅ Ativo |
| A | `dokploy` | 76.13.165.69 | guardioes | ✅ Ativo |

## Registros Removidos (Hostzera desativada)

| Tipo | Nome | IP antigo | Status |
|------|------|-----------|--------|
| A | `vps1` | 206.0.29.199 | ❌ Remover do DNS |
| A | `*.vps1` | 206.0.29.199 | ❌ Remover do DNS |
| A | `vps2` | 206.0.29.202 | ❌ Remover do DNS |
| A | `*.vps2` | 206.0.29.202 | ❌ Remover do DNS |

## Inventário de VPS

| ID | Nome | Domínio | IP | Provedor | Plano | Preço | Status |
|----|------|---------|-----|----------|-------|-------|--------|
| 0 | guardioes | crom.me | 76.13.165.69 | Hostinger | KVM 1 (1 CPU, 8GB, 100GB) | R$52,99 | ✅ Ativa |
| 1 | pilares | vps1.crom.me | 206.0.29.199 | Hostzera | KVM 4GB | R$42,15 | ❌ Desativada |
| 2 | forja | vps2.crom.me | 206.0.29.202 | Hostzera | KVM 4GB | R$42,15 | ❌ Desativada |

**Custo atual:** R$52,99/mês (economia de R$84,30/mês)

## Serviços Migrados (novos subdomínios via wildcard *.crom.me)

| Subdomínio | Serviço | Membro | Porta Interna |
|------------|---------|--------|---------------|
| `nextcloud-ivanpsg.crom.me` | Nextcloud | ivanpsg | 8040 |
| `tasks-ivanpsg.crom.me` | Vikunja (tarefas) | ivanpsg | 3456 |
| `n8n-samuelobt.crom.me` | N8N (automação) | samuelobt | 5678 |
| `phpmyadmin-shuantsu.crom.me` | phpMyAdmin | shuantsu | 8180 |
| `web-shuantsu.crom.me` | WebServer PHP | shuantsu | 8181 |

## Wildcard DNS

O wildcard `*.crom.me` resolve para `76.13.165.69`, permitindo que qualquer subdomínio
funcione automaticamente. O Traefik gerencia o roteamento e SSL via Let's Encrypt.

## Nameservers

```
ns1.dns-parking.com
ns2.dns-parking.com
```

## SSL

Todos os certificados são gerenciados automaticamente pelo Traefik + Let's Encrypt.
Não é mais necessário usar certbot manual.
