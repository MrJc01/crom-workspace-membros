# 🧠 CromIA API — Informações do Servidor

Este documento detalha onde e como a **CromIA API** está hospedada para o ecossistema CROM.

## 🟢 VPS de Membros (Hospedagem)
- **Domínio Base:** `cromia-api.crom.me`
- **IP:** `76.13.165.69`
- **Porta Interna:** `8080` (Oculta atrás do Nginx)

## 📁 Estrutura de Arquivos na VPS
O projeto não roda via Docker, e sim como um binário nativo ultra-rápido do Go. Todos os arquivos ficam isolados em:

```text
/var/www/cromia-api/
├── cromia        (Executável compilado)
├── .env          (Chaves e configurações)
└── data.db       (Banco de dados SQLite)
```

## ⚙️ Infraestrutura e Permissões
- **Serviço de Background:** Gerenciado nativamente pelo Linux SystemD (`cromia-api.service`).
- **Proxy e SSL:** Nginx com proxy reverso gerenciando o tráfego da porta 443 (HTTPS) para a 8080.
- **Isolamento:** Os membros da VPS (`grupo crom-membros`) não possuem acesso de leitura ou escrita ao `.env` ou `data.db`. Todo o consumo é feito de forma audível pela API HTTP.
