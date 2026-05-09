# 🛡️ Política de Acesso — VPS de Membros CROM

**Data**: 2026-05-01
**Versão**: 1.0

---

## 1. Elegibilidade

- Membros ativos da comunidade CROM
- Aprovação pelo administrador
- Aceitar os termos de uso

## 2. Tipos de Acesso

| Nível | Shell | Descrição |
|-------|-------|-----------|
| **Membro** | `/bin/bash` | Acesso SSH completo à área pessoal |
| **Restrito** | `/usr/sbin/nologin` | Sem acesso SSH (apenas serviços) |
| **Banido** | Conta bloqueada | Acesso revogado |

## 3. Recursos por Membro

- **Diretório home** pessoal em `/home/username/`
- **Permissões** restritas ao próprio diretório
- **Sem acesso root** — operações privilegiadas via admin apenas

## 4. Proibições

- Mineração de criptomoedas
- Hospedagem de conteúdo ilegal
- Port scanning ou ataques a terceiros
- Tentativa de escalar privilégios
- Uso excessivo de recursos (CPU/RAM/Disco) sem autorização

## 5. Penalidades

| Infração | Ação |
|----------|------|
| 1ª Ocorrência leve | Aviso formal |
| 2ª Ocorrência leve | Suspensão temporária (ban reversível) |
| Ocorrência grave | Ban permanente + deleção da conta |

## 6. Monitoramento

- Acessos SSH são logados e auditáveis
- Relatórios periódicos são gerados via `crom-manager.sh`
- O administrador pode verificar sessões ativas a qualquer momento

## 7. Alterações

Esta política pode ser atualizada a qualquer momento. Membros serão notificados de mudanças significativas.
