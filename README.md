# 🔒 CROM Orquestrador — Painel Multi-VPS

> **⚠️ Repositório PRIVADO — Acesso exclusivo do fundador (MrJ)**
>
> Este repositório contém credenciais, scripts de administração e ferramentas de orquestração de todas as VPS do ecossistema CROM. **Nenhum membro tem acesso a este repositório.** A ferramenta pública que os membros utilizam é o [crom-workspace](https://github.com/MrJc01/crom-workspace).
>
> Para documentação acessível a todos os membros, consulte o [crom-wiki](https://github.com/MrJc01/crom-wiki).

---

## Arquitetura

```
         ┌─────────────────────────────────────────────────────┐
         │           CROM ORQUESTRADOR (este repo)             │
         │   monitor.sh → modules/ → .env (credenciais)        │
         └──────────┬────────────────┬────────────────┬────────┘
                    │                │                │
              ┌─────▼─────┐   ┌─────▼─────┐   ┌─────▼─────┐
              │  VPS 0     │   │  VPS 1     │   │  VPS 2     │
              │ Guardiões  │   │ Pilares    │   │ Forja      │
              │ crom.me    │   │vps1.crom.me│   │vps2.crom.me│
              └────────────┘   └────────────┘   └────────────┘
```

## VPS Registradas

| ID | Nome | Domínio | Status |
|----|------|---------|--------|
| 0 | guardioes | crom.me | ✅ Ativo |
| 1 | pilares | vps1.crom.me | ✅ Ativo |
| 2 | forja | vps2.crom.me | ✅ Ativo |

## Uso Rápido

```bash
# Menu interativo multi-VPS
./monitor.sh

# CLI direto
./monitor.sh status          # Status de todas as VPS
./monitor.sh vps             # Listar VPS
./monitor.sh shell           # SSH na VPS ativa
./monitor.sh deploy          # Deploy landing page
./monitor.sh install-ws      # Instalar crom-workspace na VPS
./monitor.sh listar          # Listar membros da VPS ativa
./monitor.sh help            # Ver todos os comandos
```

## Estrutura

```
crom-membros/                        ← PRIVADO (só MrJ)
├── .env                             # Credenciais das VPS (gitignored)
├── .env.example                     # Template sem senhas
├── monitor.sh                       # Orquestrador principal
│
├── modules/                         # Módulos do orquestrador
│   ├── core.sh                      # Base: .env, select_vps(), SSH
│   ├── vps.sh                       # Gestão de VPS (trocar, status, deploy)
│   ├── members.sh                   # CRUD de membros
│   ├── system.sh                    # Relatórios, serviços, SSL
│   └── cromia.sh                    # Gestão CromIA
│
├── crom-workspace/                  # Ferramenta dos membros (será repo público)
│   ├── cli/
│   │   ├── crom-ws                  # Entry point principal
│   │   ├── crom-publish-helper      # Helper de proxy Nginx (roda como root)
│   │   └── modules/                 # Módulos da CLI
│   │       ├── projects.sh          # init, list, info, delete
│   │       ├── publish.sh           # publish, unpublish, ports
│   │       └── podman.sh            # podman run/stop/start/rm/list/logs
│   ├── monitor/crom-monitor.sh      # Painel admin no VPS
│   ├── docs/                        # Documentação para membros
│   └── install.sh                   # Instalador
│
├── infra/                           # Inventário de infraestrutura
│   ├── vps.conf                     # Registro de VPS
│   ├── dns-map.md                   # Mapeamento DNS
│   └── portas-ativas.md             # Serviços e portas
│
├── sites/                           # Landing pages por VPS
│   ├── _template/
│   ├── guardioes/
│   ├── pilares/
│   └── forja/
│
├── membros/                         # Cadastro e credenciais
├── app-cromia/                      # Credenciais CromIA
├── nginx/                           # Templates Nginx
├── docs/                            # Documentação admin
├── scripts/                         # Scripts auxiliares
└── relatorios/                      # Relatórios gerados
```

## Repositórios do Ecossistema

| Repo | Acesso | Descrição |
|------|--------|-----------|
| **crom-membros** (este) | 🔒 Privado (só MrJ) | Orquestrador, credenciais e administração |
| [crom-workspace](https://github.com/MrJc01/crom-workspace) | 🔓 Público | CLI e ferramentas para membros |
| [crom-wiki](https://github.com/MrJc01/crom-wiki) | 🔓 Membros CROM | Base de conhecimento, documentação, governança |

## Monitoramento de Membros

O sistema registra **3 camadas** de auditoria:

| Camada | O que captura | Onde fica |
|--------|---------------|-----------|
| **Comandos bash** | Cada comando digitado | `/var/log/crom-membros/bash/` |
| **Sessões** | Terminal inteiro gravado | `/var/log/crom-membros/sessions/` |
| **Ações crom-ws** | Criação/deleção de projetos | `/var/log/crom-membros/<user>.log` |

Acesse tudo via `crom-monitor` no VPS ou `./monitor.sh` → opções 7-9 daqui.
