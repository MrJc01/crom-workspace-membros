# 🌐 Mapeamento DNS — Ecossistema CROM

Referência centralizada de todos os domínios e subdomínios do ecossistema.
**Gerenciado em:** Hostinger → Domínios → crom.me → DNS / Nameservers

## Registros Ativos

| Tipo | Nome | IP / Target | VPS | Status |
|------|------|-------------|-----|--------|
| A | `@` | 76.13.165.69 | guardioes | ✅ Ativo |
| CNAME | `www` | crom.me | guardioes | ✅ Ativo |
| A | `*` | 76.13.165.69 | guardioes | ✅ Ativo |
| A | `cromia-api` | 76.13.165.69 | guardioes | ✅ Ativo |
| A | `dokploy` | 76.13.165.69 | guardioes | ✅ Ativo |
| A | `vps1` | 206.0.29.199 | pilares | ✅ Ativo |
| A | `*.vps1` | 206.0.29.199 | pilares | ✅ Ativo |
| A | `vps2` | 206.0.29.202 | forja | ✅ Ativo |
| A | `*.vps2` | 206.0.29.202 | forja | ✅ Ativo |

## Inventário de VPS

| ID | Nome | Domínio | IP | Provedor | Plano | Preço |
|----|------|---------|-----|----------|-------|-------|
| 0 | guardioes | crom.me | 76.13.165.69 | Hostinger | KVM 1 (1 CPU, 4GB, 50GB) | R$52.99 |
| 1 | pilares | vps1.crom.me | 206.0.29.199 | Hostzera | KVM 4GB (2 CPU, 4GB, 50GB NVMe) | R$42.15 |
| 2 | forja | vps2.crom.me | 206.0.29.202 | Hostzera | KVM 4GB (2 CPU, 4GB, 50GB NVMe) | R$42.15 |

**Custo total:** R$137.29/mês

## Wildcard DNS

O wildcard `*.vps1.crom.me` permite que membros publiquem projetos automaticamente:
- `meu-projeto-pedrodev.vps1.crom.me` → resolve para VPS 1

O Nginx na VPS captura o subdomínio e faz proxy reverso para a porta do projeto.

## Nameservers

```
ns1.dns-parking.com
ns2.dns-parking.com
```

## SSL

Cada VPS deve emitir seus próprios certificados via certbot:

```bash
# Domínio principal da VPS
certbot --nginx -d vps1.crom.me --non-interactive --agree-tos -m <email> --redirect

# Wildcard (requer DNS challenge, não HTTP)
# Para wildcard, usar certbot com plugin DNS ou gerar manualmente
```
