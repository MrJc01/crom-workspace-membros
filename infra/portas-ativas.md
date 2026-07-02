# 🚀 Aplicações e Portas Ativas no Ecossistema CROM

Este documento atua como o registro oficial de alocação de portas, domínios e caminhos físicos das aplicações em execução nas nossas VPSs, evitando conflitos de deploy.

> **Consolidação 2026-07-02:** Todos os serviços agora rodam na VPS 0 (Guardiões).

## 🟢 VPS Guardiões (76.13.165.69) — VPS ÚNICA

### Infraestrutura Core

| Serviço / Aplicação | Domínio | Porta Interna | Stack / Tipo |
| :--- | :--- | :--- | :--- |
| **Traefik** | `*.crom.me` | `80`, `443` | Traefik (Dokploy) |
| **Dokploy Painel** | `dokploy.crom.me` | `3000` | Node.js (Docker Swarm) |
| **Dokploy Postgres** | — | `5432` (interno) | PostgreSQL |
| **Dokploy Redis** | — | `6379` (interno) | Redis |
| **CromIA API** | `cromia-api.crom.me` | `8080` | Go + SQLite (Systemd) |

### Projetos de Membros (Dokploy/Swarm)

| Serviço / Aplicação | Domínio | Porta Interna | Membro |
| :--- | :--- | :--- | :--- |
| **Portal CROM** | `crom.me` | N/A | — |
| **CROM API** | — | `8000` | — |
| **ScratchPaint** | `scratchpaint.com.br` | `80` | — |
| **Silenceia IA** | `silence.ia.br` | `80` | — |
| **TrendHunter** | — | `3001` | samuelobt |
| **AppShop** | `*.appshop.crom.me` | `8086` | — |
| **ivanpsg Portfolio** | — | `20128`, `32768` | ivanpsg |

### Serviços Migrados (Docker Compose — ex-Hostzera)

| Serviço / Aplicação | Domínio | Porta Interna | Membro | Origem |
| :--- | :--- | :--- | :--- | :--- |
| **Nextcloud** | `nextcloud-ivanpsg.crom.me` | `8040` | ivanpsg | ex-VPS1 |
| **Vikunja** | `tasks-ivanpsg.crom.me` | `3456` | ivanpsg | ex-VPS2 |
| **N8N** | `n8n-samuelobt.crom.me` | `5678` | samuelobt | ex-VPS2 |
| **MariaDB** | — (interno) | `3306` (Docker) | shuantsu | ex-VPS1 |
| **phpMyAdmin** | `phpmyadmin-shuantsu.crom.me` | `8180` | shuantsu | ex-VPS1 |
| **WebServer PHP** | `web-shuantsu.crom.me` | `8181` | shuantsu | ex-VPS1 |

> **Atenção (Admin):** Antes de subir um novo projeto, reserve a porta adicionando uma nova linha nesta tabela.
