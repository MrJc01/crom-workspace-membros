# 🛡️ Guia do Administrador — CROM Orquestrador

Este guia é destinado aos administradores da infraestrutura CROM. Ele explica como configurar seu ambiente local e utilizar o repositório `crom-workspace-membros` para gerenciar todas as VPSs do ecossistema de forma centralizada.

---

## 🏗️ Pré-requisitos Locais

Para executar o orquestrador na sua máquina de trabalho (Linux/macOS), você precisará instalar o utilitário `sshpass` para gerenciar a automação de senhas SSH:

### Instalação no Ubuntu/Debian:
```bash
sudo apt update && sudo apt install -y sshpass
```

### Instalação no macOS (via Homebrew):
```bash
brew install hudochenkov/sshpass/sshpass
```

---

## 🚀 1. Configurando o Repositório

1. **Clone este repositório** na sua máquina local:
   ```bash
   git clone <URL_DO_REPOSITORIO>
   cd crom-workspace-membros
   ```

2. **Configure as Variáveis de Ambiente**:
   Copie o arquivo de exemplo `.env.example` para `.env`:
   ```bash
   cp .env.example .env
   ```

3. **Edite o arquivo `.env`** e preencha as credenciais e IPs de root das 3 VPSs (solicite estes dados de forma segura ao administrador principal):
   - `VPS0_HOST`, `VPS0_PASS` (Guardiões)
   - `VPS1_HOST`, `VPS1_PASS` (Pilares)
   - `VPS2_HOST`, `VPS2_PASS` (Forja)

---

## 🛠️ 2. O CLI de Orquestração (`monitor.sh`)

O entrypoint principal do orquestrador é o script `./monitor.sh`. Ele pode ser usado tanto de forma **interativa** (menu gráfico no terminal) quanto de forma **CLI direta** (comandos em linha).

### Modo Interativo
Para abrir o painel visual e interativo:
```bash
./monitor.sh
```

### Comandos CLI Diretos (Mais Rápidos)

#### Gerenciamento de VPS:
```bash
# Ver status e saúde de todas as VPSs cadastradas (Ping, RAM e Disco)
./monitor.sh status

# Trocar a VPS ativa para execução de comandos específicos
./monitor.sh switch
```

#### Gerenciamento de Membros (Executado na VPS Ativa):
```bash
# Listar todos os membros cadastrados na VPS ativa
./monitor.sh listar

# Criar um novo membro comum (sem privilégios root)
./monitor.sh criar

# Bloquear/Banir um membro (encerra sessões e revoga login)
./monitor.sh banir

# Restaurar acesso de um membro banido
./monitor.sh restaurar

# Alterar senha de um membro
./monitor.sh senha

# Deletar um membro permanentemente (apaga arquivos e usuário)
./monitor.sh deletar
```

#### Conectividade e Monitoramento:
```bash
# Ver logins recentes no servidor
./monitor.sh acessos

# Ver quem está logado em tempo real
./monitor.sh sessoes

# Desconectar (derrubar) uma sessão ativa de um usuário
./monitor.sh kick

# Abrir um shell SSH direto como root na VPS ativa
./monitor.sh shell
```

---

## 🛡️ 3. Concedendo Acesso Root a Novos Membros

Se você precisar promover um membro existente a administrador ou criar um novo administrador com privilégios `sudo` em **todas as 3 VPSs** simultaneamente, utilize o novo script dedicado:

```bash
./scripts/grant-root.sh
```

O script irá guiar você de forma interativa sobre:
1. O nome de usuário (`username`) a ser criado ou elevado.
2. Definição de chave pública SSH ou geração automática de senha.
3. Configuração automática do sudoers sem senha (`NOPASSWD`).
4. Geração automática do arquivo Markdown de credenciais para entrega ao novo administrador em `membros/credenciais/<username>-acesso-root.md`.

---

## 📊 4. Sistema de Relatórios e Auditoria

O motor de auditoria integrado extrai dados de status do sistema de todas as VPSs simultaneamente:

```bash
# Gera os 15 relatórios em formato Markdown
./monitor.sh report
```

Os relatórios consolidados e detalhados serão criados em `relatorios/<data_hora>/`. O link simbólico `relatorios/ultimo/` sempre apontará para a auditoria mais recente.

---

*CROM Collective — Infraestrutura Soberana e Segura*
