#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════╗
# ║  CROM — Conceder Acesso Root Multi-VPS                      ║
# ║  Cria/Atualiza membro e dá privilégios sudo em todas as VPS  ║
# ╚══════════════════════════════════════════════════════════════╝

set -euo pipefail

# Descobrir diretório base do projeto
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="${SCRIPT_DIR}/.env"
VPS_CONF="${SCRIPT_DIR}/infra/vps.conf"
CSV_FILE="${SCRIPT_DIR}/membros/lista-membros.csv"
CRED_DIR="${SCRIPT_DIR}/membros/credenciais"

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

info()    { echo -e "  ${CYAN}ℹ${NC}  $*"; }
success() { echo -e "  ${GREEN}✓${NC}  $*"; }
warn()    { echo -e "  ${YELLOW}⚠${NC}  $*"; }
error()   { echo -e "  ${RED}✗${NC}  $*"; exit 1; }
header()  { echo -e "\n  ${PURPLE}${BOLD}$*${NC}\n"; }

# Carregar arquivo .env
if [[ ! -f "$ENV_FILE" ]]; then
    error ".env não encontrado em ${ENV_FILE}. Por favor, configure as credenciais das VPS."
fi
set -a
source "$ENV_FILE"
set +a

# Verificar dependências
if ! command -v sshpass &>/dev/null; then
    error "sshpass não está instalado. Instale usando: sudo apt install sshpass"
fi

header "🛠️ CONFIGURADOR DE ACESSO ROOT MULTI-VPS"

# 1. Obter informações do usuário
read -rp "  Username do membro (sem espaços): " username
username="${username// /}" # Remover espaços
[[ -z "$username" ]] && error "Username é obrigatório."
[[ "$username" == "root" ]] && error "Não é permitido usar 'root' como nome de membro."

read -rp "  Nome completo: " nome
[[ -z "$nome" ]] && nome="$username"

read -rp "  E-mail: " email
[[ -z "$email" ]] && email="N/A"

# 2. Definir método de autenticação
echo
info "Escolha o método de autenticação SSH para o administrador:"
echo -e "    ${CYAN}1${NC}  Usar Chave Pública SSH (Altamente recomendado para Root)"
echo -e "    ${CYAN}2${NC}  Gerar senha aleatória segura"
echo -e "    ${CYAN}3${NC}  Digitar uma senha manualmente"
read -rp "  Opção (1-3): " auth_opt

ssh_pub_key=""
senha=""

if [[ "$auth_opt" == "1" ]]; then
    echo
    read -rp "  Cole a chave pública SSH (ex: ssh-rsa/ssh-ed25519 ...): " ssh_pub_key
    [[ -z "$ssh_pub_key" ]] && error "Chave pública SSH não pode ser vazia."
elif [[ "$auth_opt" == "2" ]]; then
    # Gerar senha aleatória
    set +o pipefail
    senha=$(LC_ALL=C tr -dc 'A-HJ-NP-Za-hj-np-z2-9@#$%&' < /dev/urandom | head -c 16)
    set -o pipefail
    info "Senha gerada com sucesso: ${GREEN}${senha}${NC}"
else
    echo
    read -rsp "  Digite a senha (min 8 caracteres): " senha
    echo
    read -rsp "  Confirme a senha: " senha_conf
    echo
    [[ "$senha" != "$senha_conf" ]] && error "As senhas não coincidem."
    [[ ${#senha} -lt 8 ]] && error "A senha deve ter no mínimo 8 caracteres."
fi

# Confirmar sudo sem senha
echo
read -rp "  Permitir sudo sem senha (passwordless sudo)? (S/n): " sudo_nopass
sudo_nopass="${sudo_nopass:-s}"

# Confirmar execução
echo
warn "Este script irá configurar o usuário '${username}' com acesso ROOT (sudo) nas VPSs cadastradas."
read -rp "  Deseja continuar? (s/N): " confirm
[[ "${confirm,,}" != "s" ]] && error "Operação cancelada."

# 3. Aplicar nas VPSs
if [[ ! -f "$VPS_CONF" ]]; then
    error "Arquivo de configuração de VPS não encontrado: ${VPS_CONF}"
fi

declare -a vps_success=()
declare -a vps_failed=()

while IFS='|' read -r id nome_vps dominio status_vps; do
    [[ "$id" =~ ^# ]] && continue
    [[ -z "$id" ]] && continue
    
    host_var="VPS${id}_HOST"
    user_var="VPS${id}_USER"
    pass_var="VPS${id}_PASS"
    
    host="${!host_var:-}"
    user="${!user_var:-}"
    pass="${!pass_var:-}"
    
    if [[ -z "$host" || -z "$user" || -z "$pass" ]]; then
        warn "VPS ${id} (${nome_vps}) não configurada completamente no .env. Ignorando..."
        vps_failed+=("${nome_vps} (Sem IP/.env)")
        continue
    fi
    
    echo
    info "Conectando à VPS ${id}: ${nome_vps} (${host})..."
    
    # Testar conexão
    if ! sshpass -p "$pass" ssh -n -o StrictHostKeyChecking=no -o ConnectTimeout=8 "${user}@${host}" "echo connection_ok" &>/dev/null; then
        warn "Falha ao conectar na VPS ${nome_vps} (${host})."
        vps_failed+=("${nome_vps} (${host})")
        continue
    fi
    
    success "Conexão estabelecida com sucesso."
    info "Configurando privilégios root e usuário..."
    
    # Script que rodará remoto na VPS
    remote_script=$(cat <<EOF
set -e
# Garantir grupo crom-membros
getent group crom-membros >/dev/null || groupadd crom-membros

# Criar usuário se não existir
if ! id -u "${username}" &>/dev/null; then
    useradd -m -g crom-membros -s /bin/bash -c "${nome}" "${username}"
    echo "Usuário ${username} criado."
else
    # Se já existir, garante que o shell é bash e comentário está atualizado
    usermod -s /bin/bash -c "${nome}" "${username}"
    echo "Usuário ${username} já existe. Dados atualizados."
fi

# Habilitar Linger
loginctl enable-linger "${username}" 2>/dev/null || true

# Configurar senha se fornecida
if [ -n "${senha}" ]; then
    echo "${username}:${senha}" | chpasswd
    echo "Senha atualizada."
fi

# Configurar chave SSH pública se fornecida
if [ -n "${ssh_pub_key}" ]; then
    mkdir -p "/home/${username}/.ssh"
    echo "${ssh_pub_key}" > "/home/${username}/.ssh/authorized_keys"
    chmod 700 "/home/${username}/.ssh"
    chmod 600 "/home/${username}/.ssh/authorized_keys"
    chown -R "${username}:crom-membros" "/home/${username}/.ssh"
    echo "Chave pública SSH configurada."
fi

# Conceder privilégios sudo (adiciona ao grupo sudo)
usermod -aG sudo "${username}"

# Criar arquivo de sudoers personalizado
sudoers_file="/etc/sudoers.d/${username}"
if [ "${sudo_nopass,,}" == "s" ]; then
    echo "${username} ALL=(ALL:ALL) NOPASSWD:ALL" > "\$sudoers_file"
    echo "Privilégio sudo sem senha configurado."
else
    echo "${username} ALL=(ALL:ALL) ALL" > "\$sudoers_file"
    echo "Privilégio sudo com senha configurado."
fi
chmod 0440 "\$sudoers_file"

# Garantir que o grupo sudo está ativo e não precisa de senha se configurado
echo "Configuração finalizada na VPS."
EOF
)

    # Executar script remoto
    if sshpass -p "$pass" ssh -n -o StrictHostKeyChecking=no -o ConnectTimeout=15 "${user}@${host}" "bash -c '$(echo "$remote_script" | sed "s/'/'\\\\''/g")'" ; then
        success "VPS ${nome_vps} configurada com sucesso!"
        vps_success+=("${nome_vps} (${host})")
    else
        warn "Erro ao aplicar configurações na VPS ${nome_vps}."
        vps_failed+=("${nome_vps} (Erro de Execução)")
    fi
    
done < "$VPS_CONF"

# 4. Atualizar registros locais
header "💾 ATUALIZANDO REGISTROS LOCAIS"

# Atualizar lista-membros.csv
mkdir -p "$(dirname "$CSV_FILE")"
if [[ ! -f "$CSV_FILE" ]]; then
    # Criar cabeçalho do CSV
    echo "username,nome,email,cargo,data_criacao,status,senha" > "$CSV_FILE"
fi

# Se já existe, remover linha antiga para evitar duplicata
if grep -q "^${username}," "$CSV_FILE"; then
    grep -v "^${username}," "$CSV_FILE" > "${CSV_FILE}.tmp"
    mv "${CSV_FILE}.tmp" "$CSV_FILE"
fi

# Registrar no CSV
echo "${username},${nome},${email},Admin-Root,$(date +%Y-%m-%d),ativo,***" >> "$CSV_FILE"
success "Membro registrado no banco local: ${CSV_FILE}"

# 5. Gerar Relatório de Acesso Markdown
mkdir -p "$CRED_DIR"
cred_file="${CRED_DIR}/${username}-acesso-root.md"
data_hoje=$(date '+%d/%m/%Y às %H:%M')

metodo_auth="Senha definida"
[[ -n "$ssh_pub_key" ]] && metodo_auth="Chave Pública SSH configurada"

cat > "$cred_file" <<EOF
# 🔐 Credenciais de Acesso Administrativo (Root/Sudo) — CROM

**Membro:** ${nome}
**Username:** \`${username}\`
**E-mail:** ${email}
**Cargo:** Administrador (Root / Sudo)
**Data de Emissão:** ${data_hoje}

---

## 🖥️ Servidores Disponíveis e IPs

Você possui privilégios de administrador em todas as 3 VPSs da infraestrutura CROM:

| VPS | Nome | IP / Domínio | Porta SSH | Método de Autenticação |
|---|---|---|---|---|
| **VPS 0** | Guardiões | \`crom.me\` (\`76.13.165.69\`) | 22 | ${metodo_auth} |
| **VPS 1** | Pilares | \`vps1.crom.me\` (\`206.0.29.199\`) | 22 | ${metodo_auth} |
| **VPS 2** | Forja | \`vps2.crom.me\` (\`206.0.29.202\`) | 22 | ${metodo_auth} |

---

## 🚀 Como Acessar

Conecte via terminal utilizando seu usuário:

### Para conectar à VPS 0 (Guardiões):
\`\`\`bash
ssh ${username}@crom.me
\`\`\`

### Para conectar à VPS 1 (Pilares):
\`\`\`bash
ssh ${username}@vps1.crom.me
\`\`\`

### Para conectar à VPS 2 (Forja):
\`\`\`bash
ssh ${username}@vps2.crom.me
\`\`\`

$(if [[ -n "$senha" ]]; then
cat <<SENHAEOF
Quando for solicitada a senha, utilize a senha gerada abaixo:
\`\`\`
${senha}
\`\`\`
⚠️ **Altere sua senha no primeiro acesso** executando o comando \`passwd\` em cada servidor.
SENHAEOF
else
cat <<KEYEOF
> ℹ️ **Autenticação por chave ativa:** Certifique-se de carregar sua chave privada local correspondente (\`ssh-add ~/.ssh/id_rsa\` ou similar) para realizar a conexão automática sem senha.
KEYEOF
fi)

---

## 🛡️ Elevação de Privilégios (Root)

Você foi adicionado ao grupo \`sudo\` e possui privilégios totais de root através do comando \`sudo\`.

$(if [[ "${sudo_nopass,,}" == "s" ]]; then
    echo "> ⚡ **Sudo sem senha configurado:** Você não precisará digitar a sua senha para rodar comandos privilegiados."
else
    echo "> 🔑 **Sudo com senha configurado:** Para rodar comandos privilégios, você deverá digitar a sua senha de usuário."
fi)

Exemplos de uso:
\`\`\`bash
# Atualizar pacotes do sistema
sudo apt update && sudo apt upgrade -y

# Visualizar status de serviços globais
sudo systemctl status nginx

# Acessar shell completo de root (se necessário)
sudo -i
\`\`\`

> ⚠️ **ATENÇÃO:** O acesso root concede poder total sobre o sistema operacional. Ações incorretas podem indisponibilizar serviços de outros membros da comunidade. Use com responsabilidade.

---

*Documento confidencial gerado em ${data_hoje} — CROM Collective*
EOF

success "Relatório de credenciais gerado: ${cred_file}"

# Resumo Final
header "🏁 RESUMO DA OPERAÇÃO"
echo -e "  Usuário processado: ${BOLD}${username}${NC}"
echo -e "  VPS configuradas com sucesso (${#vps_success[@]}):"
for vps in "${vps_success[@]:-}"; do
    [[ -n "$vps" ]] && echo -e "    - ${GREEN}${vps}${NC}"
done
if [[ ${#vps_failed[@]} -gt 0 ]]; then
    echo -e "  VPS que falharam ou foram ignoradas (${#vps_failed[@]}):"
    for vps in "${vps_failed[@]}"; do
        echo -e "    - ${RED}${vps}${NC}"
    done
fi

echo -e "\n  ${BOLD}Relatório pronto para envio:${NC} ${cred_file}\n"
