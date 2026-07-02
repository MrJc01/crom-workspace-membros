#!/usr/bin/env bash

# ╔══════════════════════════════════════════════════════════════╗
# ║  CROM Core — Base do Orquestrador Multi-VPS                 ║
# ║  Carrega credenciais do .env e permite trocar de VPS        ║
# ╚══════════════════════════════════════════════════════════════╝

# ===== DIRETÓRIO BASE =====
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
if [[ -f "${SCRIPT_DIR}/sshpass_bin" && ! -f "${SCRIPT_DIR}/sshpass" ]]; then
    ln -sf "${SCRIPT_DIR}/sshpass_bin" "${SCRIPT_DIR}/sshpass" 2>/dev/null || true
fi
export PATH="${SCRIPT_DIR}:${PATH}"

# ===== CARREGAR .ENV =====
load_env() {
    local envfile="${SCRIPT_DIR}/.env"
    if [[ ! -f "$envfile" ]]; then
        echo -e "\033[0;31m  ✗ .env não encontrado em ${envfile}\033[0m"
        echo "  Copie .env.example para .env e preencha as credenciais."
        exit 1
    fi
    set -a
    source "$envfile"
    set +a
}

# Carregar imediatamente
load_env

# ===== SELEÇÃO DE VPS =====
CURRENT_VPS_ID="${DEFAULT_VPS:-0}"
CURRENT_VPS_NAME=""
VPS_HOST=""
VPS_USER=""
VPS_PASS=""

select_vps() {
    local id="$1"
    local host_var="VPS${id}_HOST"
    local user_var="VPS${id}_USER"
    local pass_var="VPS${id}_PASS"
    local name_var="VPS${id}_NAME"

    VPS_HOST="${!host_var}"
    VPS_USER="${!user_var}"
    VPS_PASS="${!pass_var}"
    CURRENT_VPS_NAME="${!name_var}"
    CURRENT_VPS_ID="$id"

    if [[ -z "$VPS_HOST" ]]; then
        error "VPS ${id} (${CURRENT_VPS_NAME:-desconhecida}) não tem IP configurado no .env"
        return 1
    fi
    return 0
}

# Inicializar com a VPS padrão
select_vps "${DEFAULT_VPS:-0}" 2>/dev/null || true

# ===== CONFIGURAÇÃO GERAL =====
SSH_OPTS="-o StrictHostKeyChecking=no -o ConnectTimeout=10"
MEMBERS_GROUP="crom-membros"
MEMBERS_HOME_BASE="/home"
LOG_FILE="${SCRIPT_DIR}/crom-manager.log"

# ===== CORES =====
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

# ===== UTILIDADES =====
log() {
    local msg="[$(date '+%Y-%m-%d %H:%M:%S')] [vps:${CURRENT_VPS_NAME}] $*"
    echo "$msg" >> "$LOG_FILE"
}

info()    { echo -e "  ${CYAN}ℹ${NC}  $*"; }
success() { echo -e "  ${GREEN}✓${NC}  $*"; }
warn()    { echo -e "  ${YELLOW}⚠${NC}  $*"; }
error()   { echo -e "  ${RED}✗${NC}  $*"; }
header()  { echo -e "\n  ${PURPLE}${BOLD}$*${NC}\n"; }

separator() {
    echo -e "  ${DIM}──────────────────────────────────────────────${NC}"
}

# ===== SSH BASE =====
remote() {
    sshpass -p "$VPS_PASS" ssh $SSH_OPTS "${VPS_USER}@${VPS_HOST}" "$@"
}

remote_quiet() {
    sshpass -p "$VPS_PASS" ssh $SSH_OPTS "${VPS_USER}@${VPS_HOST}" "$@" 2>/dev/null
}

check_deps() {
    if ! command -v sshpass &>/dev/null; then
        error "sshpass não encontrado. Instale com: sudo apt install sshpass"
        exit 1
    fi
}

check_connection() {
    if ! remote "echo ok" &>/dev/null; then
        error "Não foi possível conectar ao VPS ${CURRENT_VPS_NAME} (${VPS_HOST})"
        exit 1
    fi
}
