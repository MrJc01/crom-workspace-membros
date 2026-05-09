# 🔧 Manutenção e Deploy do CromIA API

Como o projeto roda via SystemD em vez de Docker, a manutenção é feita através dos comandos nativos do Linux (Debian 13).

## 📊 Verificar Logs e Status
Para ver se o serviço está saudável ou encontrar a causa de algum erro HTTP 500:

```bash
# Ver o status atual do serviço
systemctl status cromia-api

# Acompanhar os logs em tempo real (como se fosse docker logs -f)
journalctl -u cromia-api -f

# Ver apenas os últimos 50 logs
journalctl -u cromia-api -n 50 --no-pager
```

## 🔄 Como Atualizar a Aplicação (Redeploy)
Quando o código-fonte for alterado no seu repositório local, siga estes passos para colocar a nova versão no ar:

1. **Na sua máquina local** (compile o código para Linux):
   ```bash
   cd /home/j/Documentos/GitHub/cromia-api
   env GOOS=linux GOARCH=amd64 go build -o cromia api/cmd/server/main.go
   sshpass -p 'A_SENHA_DA_VPS' scp -o StrictHostKeyChecking=no cromia root@76.13.165.69:/var/www/cromia-api/
   ```

2. **Na VPS** (reinicie o serviço):
   ```bash
   systemctl restart cromia-api
   ```

## 📝 Editando o .env
Se precisar trocar a Master Key ou a chave da DeepSeek:
```bash
nano /var/www/cromia-api/.env
# Após salvar:
systemctl restart cromia-api
```
