# 🚀 Aplicações e Portas Ativas no Ecossistema CROM

Este documento atua como o registro oficial de alocação de portas, domínios e caminhos físicos das aplicações em execução nas nossas VPSs, evitando conflitos de deploy.

## 🟢 VPS de Membros (76.13.165.69)
Servidor focado no isolamento e hospedagem de projetos da comunidade e APIs de backend leve.

| Serviço / Aplicação | Domínio | Porta Interna | Caminho Físico | Stack / Tipo |
| :--- | :--- | :--- | :--- | :--- |
| **Portal de Membros** | `crom.me` | N/A (Container Nginx) | `/var/www/crom-me/` | Docker + Traefik |
| **CromIA API** | `cromia-api.crom.me` | `8080` | `/var/www/cromia-api/` | Go + SQLite (Systemd) |
| **Dokploy Painel** | `dokploy.crom.me` | `3000` | Docker | Node.js (Docker) |
| **Traefik** | `*.crom.me` | `80`, `443` | Docker | Traefik (Dokploy) |
| **Dokploy Postgres** | — | `5432` (interno) | Docker | PostgreSQL |



> **Atenção (Admin):** Antes de subir um novo projeto na VPS de Membros, reserve a porta adicionando uma nova linha nesta tabela.
