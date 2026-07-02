# 🌐 CROM Orquestrador — Painel Multi-VPS

> **Bem-vindo ao repositório público do motor CROM!**
>
> Este repositório contém a infraestrutura, scripts de administração e ferramentas de orquestração de todas as VPS do ecossistema CROM. Todo o código é aberto e está licenciado sob a **Sustainable Use License** (veja [LICENSE.md](./LICENSE.md)).
>
> Nenhuma credencial sensível está versionada aqui. Este é um ambiente seguro ("Fair-Code").
>
> Para a ferramenta pública que os membros utilizam dentro dos servidores, consulte o [crom-workspace](https://github.com/MrJc01/crom-workspace). Para a documentação, consulte o [crom-wiki](https://github.com/MrJc01/crom-wiki).

---

## 🏗️ Arquitetura

> **Consolidação (2026-07-02):** Todas as VPS foram consolidadas em uma única VPS Hostinger.
> As duas VPS da Hostzera (Pilares e Forja) foram desativadas. Economia: R$84,30/mês.

```
         ┌─────────────────────────────────────────────────────┐
         │       CROM ORQUESTRADOR (crom-workspace-membros)    │
         │   monitor.sh → modules/ → .env (local, gitignored)  │
         └──────────────────────┬───────────────────────────────┘
                                │
                    ┌───────────▼───────────┐
                    │  VPS 0 — Guardiões    │
                    │  Hostinger (crom.me)  │
                    │  76.13.165.69         │
                    │                       │
                    │  Dokploy + Traefik    │
                    │  9 membros            │
                    │  12+ containers       │
                    └───────────────────────┘
```

## 🛠️ O Motor de Relatórios Automáticos

A novidade da **v3.0** é o motor de auditoria local (sem necessidade de agentes complexos). Com um único comando, o sistema entra em todas as VPSs cadastradas simultaneamente e extrai um raio-X completo em arquivos Markdown (`.md`):

```bash
# Executa todos os 15 relatórios em todas as VPS
./monitor.sh report
```

Os 15 relatórios integrados incluem:
1. **Infraestrutura:** Projetos no Ar (HTTP Health), Uso de Recursos, Portas/Rede, Uso de Disco, Performance (top, vmstat).
2. **Segurança:** Expiração de SSL, Auditoria de Segurança (UFW, falhas SSH), Atualizações Pendentes.
3. **Gestão:** Status dos Membros, Containers Rodando, Inventário de Projetos, Nginx, Systemd, Cron Jobs e DNS.

## 🚀 Uso Rápido

### 1. Configuração Local
Copie o template do ambiente e insira os dados do seu cluster de VPS:
```bash
cp .env.example .env
```

### 2. O CLI (`monitor.sh`)

```bash
# Menu interativo multi-VPS
./monitor.sh

# CLI direto
./monitor.sh status          # Status e saúde de todas as VPS
./monitor.sh vps             # Trocar a VPS ativa
./monitor.sh shell           # Abrir SSH na VPS ativa
./monitor.sh deploy          # Deploy da landing page
./monitor.sh install-ws      # Instalar o crom-workspace nos clientes
./monitor.sh relatorio       # Gerar relatórios automatizados (novo!)
./monitor.sh help            # Ver todos os comandos
```

## 📂 Estrutura do Projeto

```
crom-workspace-membros/
├── .env.example                     # Template limpo de credenciais
├── LICENSE.md                       # Sustainable Use License (Estilo n8n)
├── monitor.sh                       # Orquestrador principal / Entry point
│
├── modules/                         # Módulos do orquestrador
│   ├── core.sh                      # Base: configs e helpers SSH
│   ├── vps.sh                       # Gestão de VPS (status, deploy, etc.)
│   ├── members.sh                   # CRUD de contas de membros nas VPS
│   ├── system.sh                    # Sistema base
│   ├── cromia.sh                    # Gestão da API CromIA
│   └── reports/                     # Motor de relatórios (.md)
│
├── crom-workspace/                  # Submodule: Ferramenta CLI dos membros
├── infra/                           # Mapeamento estático de infra (DNS, Portas)
├── sites/                           # Landing pages modulares das VPS
├── membros/                         # Scripts de credenciais seguras (off-git)
└── docs/                            # Manuais e changelogs
```

## 🛡️ Segurança de Membros

Para gerir as credenciais das VPS sem vazar senhas, a CLI nunca salva as senhas localmente. Elas são gravadas diretamente num arquivo Markdown (`*-acesso.md`) pessoal do usuário recém-criado, dentro da pasta `credenciais/` (bloqueada pelo `.gitignore`).

---

*CROM — "Soberania não se pede, constrói-se."*
