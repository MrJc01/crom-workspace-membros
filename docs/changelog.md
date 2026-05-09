# 📝 Changelog — Ecossistema CROM

## [2026-05-06] — Reestruturação Multi-VPS v3.0

### Arquitetura
- ✅ Sistema refatorado para suportar múltiplas VPS simultaneamente
- ✅ Credenciais migradas de hardcoded → `.env` (gitignored)
- ✅ `infra/vps.conf` — Registro central de VPS
- ✅ `modules/vps.sh` — Novo módulo de gestão de VPS
- ✅ `modules/core.sh` — Refatorado com `load_env()` e `select_vps()`
- ✅ `monitor.sh` v3.0 — Menu multi-VPS com seção VPS (V/T/D/W)

### crom-workspace (repo público)
- ✅ Transformado em repositório Git público independente
- ✅ Estrutura reorganizada: `cli/`, `monitor/`, `docs/`
- ✅ README.md profissional com badges e documentação completa
- ✅ LICENSE MIT adicionada
- ✅ Remote: `github.com/MrJc01/crom-workspace`

### Landing Pages
- ✅ `sites/_template/` — Template parametrizável para novas VPS
- ✅ `sites/guardioes/` — Site crom.me (migrado de `site/`)
- ✅ `sites/pilares/` — Landing page gerada
- ✅ `sites/forja/` — Landing page gerada

### Organização
- ✅ `infra/dns-map.md` — Mapeamento DNS consolidado
- ✅ `infra/portas-ativas.md` — Serviços e portas (ex `aplicacoes-ativas.md`)
- ✅ `docs/arquitetura.md` — Diagrama da arquitetura multi-VPS
- ✅ `README.md` — Atualizado como orquestrador
- ✅ `.gitignore` — Protege .env, credenciais, logs

### Removidos
- ❌ `crom-manager.sh` — Duplicata obsoleta do monitor modular
- ❌ `crom-manager.log` — Log operacional
- ❌ `instrucoes.md` — Migração DNS concluída
- ❌ `temp0.md` — Conteúdo antigo
- ❌ `infos.md` — Credenciais migradas para .env e infra/
- ❌ `aplicacoes-ativas.md` — Renomeado e movido
- ❌ `site/` — Movido para `sites/guardioes/`

---

## [2026-05-01] — Inicialização

### Servidor
- ✅ VPS provisionada (Hostinger KVM 1 — Debian 13, Campinas-BR)
- ✅ Nginx 1.26.3 instalado e configurado
- ✅ Certbot 4.0.0 instalado (Let's Encrypt)
- ✅ UFW ativo (portas 22, 80, 443)
- ✅ Grupo `crom-membros` preparado

### Domínio crom.me
- ✅ Nameservers migrados de Cloudflare → Hostinger
- ✅ Registro A atualizado para `76.13.165.69`
- ✅ Certificado SSL emitido (expira 2026-07-30)

### Infraestrutura Local
- ✅ Repositório de gerenciamento criado
- ✅ `crom-manager.sh` — gerenciamento completo de membros
- ✅ `check-dns.sh` — verificador de propagação DNS
- ✅ Landing page premium deployada
- ✅ Documentação criada (guia, política, changelog)
- ✅ Sistema de geração de credenciais PDF
