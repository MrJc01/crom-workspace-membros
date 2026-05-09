# 📖 Guia do Membro CROM

## Bem-vindo ao Servidor de Membros

Você recebeu acesso ao servidor VPS da comunidade CROM. Este documento explica como acessar e usar seus recursos.

---

## 🔐 Acesso SSH

### Conectar ao servidor
```bash
ssh SEU_USUARIO@crom.me
```

Ao conectar pela primeira vez, o sistema pedirá que você confirme a fingerprint do servidor. Digite `yes`.

### Alterar sua senha (recomendado no primeiro acesso)
```bash
passwd
```

### Chave SSH (recomendado)
Para conectar sem digitar senha:
```bash
# Na sua máquina local
ssh-keygen -t ed25519 -C "seu@email.com"
ssh-copy-id SEU_USUARIO@crom.me
```

---

## 📁 Sua área pessoal

Seu diretório home é: `/home/SEU_USUARIO/`

Você tem permissão total dentro da sua pasta. Use como desejar:
- Projetos pessoais
- Scripts e automações
- Arquivos de configuração

---

## ⚠️ Regras de Uso

1. **Não tente acessar diretórios de outros membros**
2. **Não instale serviços que escutem em portas públicas** sem autorização
3. **Não use o servidor para atividades ilegais**
4. **Reporte qualquer problema** ao administrador
5. **Mantenha sua senha segura** — não compartilhe

---

## 🌐 Ecossistema CROM

| Recurso | URL |
|---------|-----|
| Portal Principal | [crom.run](https://crom.run) |
| Comunidade | [crom.run/comunidade](https://crom.run/comunidade) |
| GitHub | [github.com/MrJc01](https://github.com/MrJc01) |
| Discord | [discord.gg/4b5wqdxreZ](https://discord.gg/4b5wqdxreZ) |

---

## 🆘 Suporte

Problemas com acesso? Entre em contato pelo Discord ou WhatsApp da comunidade.
