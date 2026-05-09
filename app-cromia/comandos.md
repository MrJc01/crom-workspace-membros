# ⌨️ Comandos CLI do CromIA

O binário `cromia` não é apenas um servidor HTTP, ele também contém toda a lógica administrativa (Dashboard por linha de comando).
Você deve rodar estes comandos logado na VPS, dentro da pasta `/var/www/cromia-api/`.

## 👥 Gestão de Usuários
```bash
# Criar usuário
./cromia users create --username <NOME> --password <SENHA>

# Listar todos os usuários do sistema
./cromia users list

# Adicionar fundos (créditos) para um membro consumir LLM
./cromia users add-credits --user <NOME> --amount 10.50
```

## 🔑 Gestão de Chaves de API
> **⚠️ ATUALIZAÇÃO ARQUITETURAL:** As chaves de acesso agora são gerenciadas **diretamente pelo usuário** no Dashboard Web. O administrador não precisa mais gerar chaves via CLI, o membro tem autonomia para criar e revogar suas próprias chaves (Self-Service CRUD).

Ainda é possível gerar chaves manualmente (para serviços sistêmicos), mas o fluxo padrão é o usuário gerar a própria chave acessando `https://cromia-api.crom.me/login`.
```bash
# Gerar uma nova chave sistêmica (Bypass Dashboard)
./cromia keys generate --user <NOME> --name "Chave Interna"
```

## 🤖 Gestão de Modelos e Preços
Ative ou desative modelos (ex: DeepSeek) e gerencie o multiplicador de lucro.
```bash
# Adicionar/Habilitar um modelo
./cromia models enable --provider deepseek --model deepseek-chat --multiplier 1.5

# Listar os modelos disponíveis
./cromia models list
```

> **Dica:** Não é necessário mexer manualmente no banco de dados SQLite (`data.db`). A CLI cuida de toda a consistência estrutural.
