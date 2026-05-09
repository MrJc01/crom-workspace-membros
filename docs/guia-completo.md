# 📘 Guia Completo — Sistema CROM Membros

> Documento de referência para entender, operar e manter toda a infraestrutura.
> Última atualização: 01/05/2026

---

## 1. Visão Geral — O que construímos

Criamos um **sistema completo de gerenciamento de membros** para a CROM, composto por:

```
┌─────────────────────────────────────────────────────┐
│                SUA MÁQUINA LOCAL                     │
│                                                     │
│  crom-membros/        (repositório privado)         │
│  ├── crom-manager.sh  → gerencia o VPS remotamente  │
│  ├── membros/         → cadastro + PDFs             │
│  └── site/            → código do site crom.me      │
│                    │                                 │
│                    │ SSH (sshpass)                    │
│                    ▼                                 │
│  ┌─────────────────────────────────────────────┐    │
│  │          VPS DE MEMBROS (76.13.165.69)       │    │
│  │                                             │    │
│  │  Nginx ──► https://crom.me (landing page)   │    │
│  │  crom-ws ──► ferramenta para membros        │    │
│  │  crom-monitor ──► painel admin (root)       │    │
│  │  auditoria ──► loga tudo dos membros        │    │
│  │                                             │    │
│  │  Membros fazem SSH para cá:                 │    │
│  │  ssh pedrodev@crom.me                       │    │
│  └─────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────┘
```

### Domínios

| Domínio | Onde está | O que faz |
|---------|-----------|-----------|
| **crom.run** | VPS Principal (148.230.79.173) | Site principal, comunidade, lab, blog |
| **crom.me** | VPS Membros (76.13.165.69) | Landing page + servidor SSH para membros |
| **me.crom.me** | Ainda não criado | Futuro: serviço de túneis (antigo crom.me) |

---

## 2. Arquivos — O que cada um faz

### Na sua máquina (repositório privado)

```
crom-membros/
│
├── crom-manager.sh          ★ SCRIPT PRINCIPAL
│   Gerencia tudo remotamente. Roda na sua máquina,
│   conecta no VPS via SSH automático (sshpass).
│   Uso: ./crom-manager.sh
│
├── infos.md                 ★ INFORMAÇÕES CENTRAIS
│   IPs, senhas, DNS, SSL, containers Docker.
│   Consulte sempre que precisar de um dado.
│
├── README.md                Visão geral da pasta
├── instrucoes.md            Passo a passo da migração (histórico)
│
├── crom-workspace/          FERRAMENTAS DO VPS
│   ├── crom-ws              CLI que membros usam (já instalado no VPS)
│   ├── crom-monitor.sh      Painel admin (já instalado no VPS)
│   └── install.sh           Reinstalador (caso precise)
│
├── docs/                    DOCUMENTAÇÃO
│   ├── guia-completo.md     Este arquivo
│   ├── guia-membros.md      Guia que você envia aos membros
│   ├── politica-acesso.md   Regras de uso do servidor
│   └── changelog.md         Histórico de mudanças
│
├── membros/                 GESTÃO DE MEMBROS
│   ├── lista-membros.csv    Cadastro (username,nome,email,cargo,data,status,senha)
│   ├── gerar-credenciais.sh Gera HTML + PDF com credenciais
│   ├── credenciais/         PDFs gerados (1 por membro)
│   └── template/
│       └── credencial.html  Template visual da credencial
│
├── site/                    SITE PÚBLICO
│   └── index.html           Landing page do crom.me
│
├── nginx/                   CONFIGURAÇÃO DO SERVIDOR
│   └── crom-me.conf         Virtual host do Nginx
│
├── scripts/                 SCRIPTS AUXILIARES
│   └── check-dns.sh         Verifica propagação DNS
│
└── relatorios/              RELATÓRIOS GERADOS
```

### No VPS (já instalado)

| Caminho | O que é |
|---------|---------|
| `/usr/local/bin/crom-ws` | CLI para membros |
| `/usr/local/bin/crom-monitor` | Painel admin |
| `/etc/profile.d/crom-audit.sh` | Script que loga comandos automaticamente |
| `/var/www/crom-me/index.html` | Site público |
| `/etc/nginx/sites-enabled/crom-me` | Config Nginx |
| `/etc/letsencrypt/live/crom.me/` | Certificado SSL |
| `/var/log/crom-membros/` | Todos os logs de auditoria |
| `/var/log/crom-membros/bash/` | Comandos bash de cada membro |
| `/var/log/crom-membros/sessions/` | Gravações de sessão completas |
| `/var/log/crom-membros/registry/` | Projetos registrados por membro |

---

## 3. Como fazer — Tarefas do dia a dia

### 3.1 Criar um novo membro

**Passo 1** — Criar o usuário Linux no VPS:
```bash
./crom-manager.sh criar
# Ou direto: ./crom-manager.sh
# Depois escolha opção 1
```
Preencha: username, nome, senha, permitir SSH (s).

**Passo 2** — Registrar no CSV e gerar credencial:
```bash
./membros/gerar-credenciais.sh
# Escolha opção 1 (Adicionar membro)
# Use a MESMA senha que criou no passo 1
```
Isso gera o PDF em `membros/credenciais/<user>-credencial.pdf`.

**Passo 3** — Envie o PDF ao membro em privado.

---

### 3.2 Banir um membro

```bash
./crom-manager.sh banir
# Ou opção 3 no menu
```
O que acontece:
- Conta é bloqueada (não consegue logar)
- Shell muda para `/usr/sbin/nologin`
- Todas as sessões ativas são encerradas
- Arquivos ficam preservados

Para restaurar depois: opção 4 no menu.

---

### 3.3 Monitorar o que membros fazem

**Opção A — Do seu computador** (via crom-manager.sh):
```bash
./crom-manager.sh
# Opção 7: Ver log de acessos
# Opção 8: Sessões ativas agora
# Opção 10: Relatório completo
```

**Opção B — Direto no VPS** (mais detalhado):
```bash
ssh root@crom.me
crom-monitor
# Opção 1: Atividade recente (todos)
# Opção 3: Monitor ao VIVO (real-time)
# Opção 6: Comandos bash de um membro
# Opção 7: Gravações de sessão
```

**Opção C — Verificar manualmente** (no VPS):
```bash
# Ver todos os comandos que pedrodev digitou:
cat /var/log/crom-membros/bash/pedrodev_commands.log

# Ver ações do crom-ws:
cat /var/log/crom-membros/pedrodev.log

# Ver últimos logins:
last -n 20

# Ver quem está logado agora:
who

# Ver processos de um membro:
lastcomm --user pedrodev
```

---

### 3.4 Atualizar o site crom.me

Edite `site/index.html` localmente, depois:
```bash
./crom-manager.sh deploy
# Ou opção 12 no menu
```
Ele copia os arquivos da pasta `site/` para o VPS e recarrega o Nginx.

---

### 3.5 Gerar relatório

```bash
./crom-manager.sh relatorio
# Mostra: CPU, RAM, disco, membros, conexões, segurança, nginx, SSL
# Pode salvar em arquivo
```

---

### 3.6 Alterar senha de membro

```bash
./crom-manager.sh senha
# Opção 5 no menu
```

Depois atualize manualmente o CSV em `membros/lista-membros.csv` e regenere o PDF se necessário.

---

## 4. Segurança — O que está protegido

### Firewall (UFW)
Apenas 3 portas abertas:
- **22** — SSH
- **80** — HTTP (redireciona para HTTPS)
- **443** — HTTPS

### SSL
- Certificado Let's Encrypt emitido automaticamente
- Renovação automática via `certbot.timer`
- Expira em 2026-07-30 (renova sozinho antes)

### Isolamento de membros
- Cada membro só acessa seu `/home/<user>/`
- Sem acesso root
- Sem acesso aos diretórios de outros membros
- Shell pode ser desabilitado (ban)

### Auditoria (3 camadas)

| Camada | Como funciona | Onde fica |
|--------|--------------|-----------|
| **crom-ws log** | Cada comando `crom-ws` registra no log central | `/var/log/crom-membros/<user>.log` |
| **Bash log** | `PROMPT_COMMAND` captura cada comando digitado | `/var/log/crom-membros/bash/<user>_commands.log` |
| **Sessão** | `script` grava o terminal inteiro (tudo que aparece na tela) | `/var/log/crom-membros/sessions/` |
| **Process acct** | `acct` registra cada processo executado | Via `lastcomm` |

---

## 5. DNS — Como funciona

```
Usuário digita crom.me
        │
        ▼
Hostinger DNS (ns1.dns-parking.com)
        │
        ▼
Registro A: crom.me → 76.13.165.69
        │
        ▼
VPS Membros → Nginx → index.html
```

### Se precisar alterar DNS:
1. Acesse Hostinger → Domínios → crom.me → DNS / Nameservers
2. Edite o registro A

### Se precisar renovar SSL manualmente:
```bash
ssh root@crom.me
certbot renew
```

---

## 6. Mapa de senhas e acessos

| Recurso | Acesso | Onde está |
|---------|--------|-----------|
| VPS Membros (root) | `ssh root@76.13.165.69` / senha no `infos.md` | infos.md |
| VPS Principal (root) | `ssh root@crom.run` / senha não armazenada | Memória |
| Hostinger painel | Login web | Hostinger.com |
| Cloudflare (antigo) | Já migrado, pode ignorar | - |
| Membros individuais | No CSV `membros/lista-membros.csv` | CSV local |

---

## 7. O que o membro vê

Quando um membro recebe o PDF e faz login:

```bash
$ ssh pedrodev@crom.me
# Digita a senha do PDF

$ crom-ws help
  crom-ws init [nome]     Criar projeto
  crom-ws list            Listar projetos
  crom-ws info [projeto]  Detalhes
  crom-ws delete [nome]   Deletar
  crom-ws status          Status geral

$ crom-ws init meu-site
  Nome do projeto: meu-site
  Descrição: Site pessoal
  Stack: web
  ✓ Projeto 'meu-site' criado em /home/pedrodev/projetos/meu-site

$ crom-ws list
  PROJETO            STACK      DESCRIÇÃO
  meu-site           web        Site pessoal
```

Enquanto ele usa, **tudo é logado** para você ver em `crom-monitor`.

---

## 8. Checklist de manutenção

### Semanal
- [ ] Verificar sessões ativas: `./crom-manager.sh` → opção 8
- [ ] Verificar disk/RAM: `./crom-manager.sh` → opção 10

### Mensal
- [ ] Gerar relatório: `./crom-manager.sh relatorio`
- [ ] Revisar logs de auditoria
- [ ] Verificar SSL: `./crom-manager.sh` → opção 11

### Quando adicionar membro
- [ ] Criar no VPS: `./crom-manager.sh criar`
- [ ] Registrar + gerar PDF: `./membros/gerar-credenciais.sh`
- [ ] Enviar PDF no privado
- [ ] Atualizar changelog

---

## 9. Troubleshooting

### "Não consigo conectar no VPS"
```bash
# Testar conectividade
ping 76.13.165.69
ssh root@crom.me
# Se falhar, verifique se a VPS está ligada no painel Hostinger
```

### "SSL expirou"
```bash
ssh root@crom.me
certbot renew
systemctl reload nginx
```

### "Membro não consegue logar"
```bash
# Verificar se está banido
./crom-manager.sh listar
# Se status = BAN, restaure com opção 4
# Se status = ATIVO, verifique a senha com opção 5
```

### "Site não atualiza"
```bash
# Redeployar
./crom-manager.sh deploy
# Verificar nginx
ssh root@crom.me
nginx -t && systemctl reload nginx
```

### "Reinstalar ferramentas do workspace"
```bash
cd crom-workspace
sshpass -p 'SENHA' scp crom-ws crom-monitor.sh install.sh root@crom.me:/tmp/
sshpass -p 'SENHA' ssh root@crom.me "cd /tmp && bash install.sh"
```
