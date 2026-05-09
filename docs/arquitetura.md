# 🏗️ Arquitetura Multi-VPS — Ecossistema CROM

## Visão Geral

O ecossistema CROM opera com múltiplas VPS gerenciadas de forma centralizada pelo **orquestrador** (`crom-membros`). Cada VPS é um servidor independente que pode hospedar membros e serviços.

```mermaid
graph TB
    subgraph Orquestrador["🔒 crom-membros (local)"]
        MON[monitor.sh]
        ENV[.env credenciais]
        VPS_SH[modules/vps.sh]
        MEM_SH[modules/members.sh]
    end

    subgraph VPS0["VPS 0 — Guardiões (crom.me)"]
        SITE0[Landing Page]
        WS0[crom-workspace]
        CROMIA[CromIA API :8085]
        NGINX0[Nginx + SSL]
    end

    subgraph VPS1["VPS 1 — Pilares (vps1.crom.me)"]
        SITE1[Landing Page]
        WS1[crom-workspace]
        NGINX1[Nginx + SSL]
    end

    subgraph VPS2["VPS 2 — Forja (vps2.crom.me)"]
        SITE2[Landing Page]
        WS2[crom-workspace]
        NGINX2[Nginx + SSL]
    end

    MON --> |SSH| VPS0
    MON --> |SSH| VPS1
    MON --> |SSH| VPS2
    MON --- ENV
    MON --- VPS_SH
    MON --- MEM_SH
```

## Fluxo de Operações

### Adicionar Nova VPS

```mermaid
sequenceDiagram
    participant Admin
    participant .env
    participant vps.conf
    participant DNS
    participant VPS

    Admin->>DNS: Criar registro A (vpsN.crom.me → IP)
    Admin->>.env: Adicionar VPS<N>_HOST/USER/PASS
    Admin->>vps.conf: Adicionar linha N|nome|dominio|ativo
    Admin->>VPS: ./monitor.sh → W (instalar workspace)
    Admin->>VPS: ./monitor.sh → D (deploy landing)
    Admin->>VPS: ./monitor.sh → 12 (SSL)
```

### Adicionar Membro

```mermaid
sequenceDiagram
    participant Admin
    participant Monitor as monitor.sh
    participant VPS

    Admin->>Monitor: Escolher VPS ativa (V)
    Admin->>Monitor: Criar membro (1)
    Monitor->>VPS: useradd + chpasswd via SSH
    Monitor->>Monitor: Salvar credenciais em membros/
    Note over Admin: Membro faz SSH e usa crom-ws
```

## Componentes

| Componente | Localização | Função |
|-----------|-------------|--------|
| `monitor.sh` | Local (orquestrador) | Menu interativo multi-VPS |
| `modules/core.sh` | Local | SSH, .env, select_vps() |
| `modules/vps.sh` | Local | Gestão de VPS |
| `modules/members.sh` | Local | CRUD de membros |
| `modules/system.sh` | Local | Relatórios, serviços |
| `modules/cromia.sh` | Local | Gestão CromIA |
| `crom-workspace/` | Local + VPS | CLI para membros |
| `infra/vps.conf` | Local | Registro de VPS |
| `.env` | Local (gitignored) | Credenciais |

## Rede

| Domínio | IP | Função |
|---------|----|---------| 
| crom.me | 76.13.165.69 | Portal principal |
| cromia-api.crom.me | 76.13.165.69 | API de IA |
| vps1.crom.me | (TBD) | Servidor Pilares |
| vps2.crom.me | (TBD) | Servidor Forja |
| crom.run | 148.230.79.173 | Site comunidade |
