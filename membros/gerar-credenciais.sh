#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════╗
# ║  CROM — Gerador de Credenciais de Membros                   ║
# ║  Gera HTML/PDF individual para cada membro do CSV            ║
# ╚══════════════════════════════════════════════════════════════╝

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CSV_FILE="${SCRIPT_DIR}/lista-membros.csv"
TEMPLATE_FILE="${SCRIPT_DIR}/template/credencial.html"
OUTPUT_DIR="${SCRIPT_DIR}/credenciais"
REPORT_FILE="${SCRIPT_DIR}/../relatorios/relatorio-membros-$(date +%Y%m%d-%H%M%S).md"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
PURPLE='\033[0;35m'
BOLD='\033[1m'
NC='\033[0m'

info()    { echo -e "  ${CYAN}ℹ${NC}  $*"; }
success() { echo -e "  ${GREEN}✓${NC}  $*"; }
warn()    { echo -e "  ${YELLOW}⚠${NC}  $*"; }
error()   { echo -e "  ${RED}✗${NC}  $*"; exit 1; }

# Gerar senha aleatória segura
gerar_senha() {
    local length="${1:-12}"
    # Mix de letras, números e símbolos seguros
    LC_ALL=C tr -dc 'A-HJ-NP-Za-hj-np-z2-9@#$%&' < /dev/urandom | head -c "$length"
}

# Menu interativo para adicionar membro
adicionar_membro() {
    echo -e "\n  ${PURPLE}${BOLD}📦 ADICIONAR MEMBRO AO CADASTRO${NC}\n"
    
    read -rp "  Username (sem espaços): " username
    [[ -z "$username" ]] && error "Username obrigatório"
    
    # Verificar duplicata
    if grep -q "^${username}," "$CSV_FILE" 2>/dev/null; then
        error "Username '${username}' já existe no cadastro!"
    fi

    read -rp "  Nome completo: " nome
    [[ -z "$nome" ]] && error "Nome obrigatório"
    
    read -rp "  E-mail: " email
    read -rp "  Cargo (ex: Membro, Dev, Admin): " cargo
    cargo="${cargo:-Membro}"
    
    local data_criacao
    data_criacao=$(date +%Y-%m-%d)
    
    echo
    read -rp "  Gerar senha automática? (S/n): " auto_senha
    local senha
    if [[ "${auto_senha,,}" == "n" ]]; then
        read -rsp "  Digite a senha (min 8 chars): " senha
        echo
        [[ ${#senha} -lt 8 ]] && error "Senha deve ter no mínimo 8 caracteres"
    else
        senha=$(gerar_senha 14)
        info "Senha gerada: ${GREEN}${senha}${NC}"
    fi

    # Salvar no CSV
    echo "${username},${nome},${email},${cargo},${data_criacao},ativo,${senha}" >> "$CSV_FILE"
    
    success "Membro '${username}' adicionado ao cadastro!"
    info "Arquivo: ${CSV_FILE}"
    echo
    read -rp "  Gerar credencial PDF/HTML agora? (S/n): " gerar
    if [[ "${gerar,,}" != "n" ]]; then
        gerar_credencial_individual "$username"
    fi
}

# Gerar credencial para um membro específico
gerar_credencial_individual() {
    local target_user="$1"
    
    if [[ ! -f "$TEMPLATE_FILE" ]]; then
        error "Template não encontrado: ${TEMPLATE_FILE}"
    fi

    local line
    line=$(grep "^${target_user}," "$CSV_FILE" | head -1)
    
    if [[ -z "$line" ]]; then
        error "Membro '${target_user}' não encontrado no CSV"
    fi

    IFS=',' read -r username nome email cargo data_criacao status senha <<< "$line"

    local output_html="${OUTPUT_DIR}/${username}-credencial.html"
    local data_atual
    data_atual=$(date '+%d/%m/%Y às %H:%M')
    
    mkdir -p "$OUTPUT_DIR"

    # Substituir placeholders no template
    sed \
        -e "s|{{NOME}}|${nome}|g" \
        -e "s|{{USERNAME}}|${username}|g" \
        -e "s|{{EMAIL}}|${email}|g" \
        -e "s|{{CARGO}}|${cargo}|g" \
        -e "s|{{DATA_CRIACAO}}|${data_criacao}|g" \
        -e "s|{{SENHA}}|${senha}|g" \
        -e "s|{{DATA}}|${data_atual}|g" \
        "$TEMPLATE_FILE" > "$output_html"

    success "HTML gerado: ${output_html}"

    # Tentar converter para PDF se wkhtmltopdf estiver disponível
    if command -v wkhtmltopdf &>/dev/null; then
        local output_pdf="${OUTPUT_DIR}/${username}-credencial.pdf"
        wkhtmltopdf --quiet \
            --page-size A4 \
            --margin-top 10 \
            --margin-bottom 10 \
            --margin-left 10 \
            --margin-right 10 \
            --enable-local-file-access \
            "$output_html" "$output_pdf" 2>/dev/null
        success "PDF gerado: ${output_pdf}"
    elif command -v google-chrome &>/dev/null || command -v chromium-browser &>/dev/null || command -v chromium &>/dev/null; then
        local output_pdf="${OUTPUT_DIR}/${username}-credencial.pdf"
        local chrome_bin
        chrome_bin=$(which google-chrome 2>/dev/null || which chromium-browser 2>/dev/null || which chromium 2>/dev/null)
        "$chrome_bin" --headless --disable-gpu --print-to-pdf="$output_pdf" --no-pdf-header-footer "$output_html" 2>/dev/null
        success "PDF gerado via Chrome: ${output_pdf}"
    else
        warn "wkhtmltopdf e Chrome não encontrados — HTML gerado (abra no browser e imprima como PDF)"
        info "Instale com: sudo apt install wkhtmltopdf"
    fi
}

# Gerar credenciais para TODOS os membros
gerar_todos() {
    echo -e "\n  ${PURPLE}${BOLD}📄 GERANDO CREDENCIAIS PARA TODOS OS MEMBROS${NC}\n"

    local count=0
    local total
    total=$(tail -n +2 "$CSV_FILE" | grep -c '.' 2>/dev/null || echo 0)

    if [[ "$total" -eq 0 ]]; then
        warn "Nenhum membro no cadastro. Use: $0 adicionar"
        return
    fi

    info "Processando ${total} membro(s)..."
    echo

    tail -n +2 "$CSV_FILE" | while IFS=',' read -r username nome email cargo data_criacao status senha; do
        [[ -z "$username" ]] && continue
        gerar_credencial_individual "$username"
        ((count++)) || true
    done

    echo
    success "Todas as credenciais foram geradas em: ${OUTPUT_DIR}/"
}

# Gerar relatório consolidado de membros
gerar_relatorio() {
    echo -e "\n  ${PURPLE}${BOLD}📊 GERANDO RELATÓRIO DE MEMBROS${NC}\n"

    mkdir -p "$(dirname "$REPORT_FILE")"

    {
        echo "# 📊 Relatório de Membros CROM"
        echo ""
        echo "**Data**: $(date '+%d/%m/%Y às %H:%M:%S')"
        echo "**Servidor**: 76.13.165.69 (VPS Membros)"
        echo ""
        echo "---"
        echo ""
        echo "## Membros Cadastrados"
        echo ""
        echo "| # | Username | Nome | E-mail | Cargo | Data | Status |"
        echo "|---|----------|------|--------|-------|------|--------|"

        local i=1
        tail -n +2 "$CSV_FILE" | while IFS=',' read -r username nome email cargo data_criacao status senha; do
            [[ -z "$username" ]] && continue
            local status_icon
            case "$status" in
                ativo)  status_icon="✅ Ativo" ;;
                banido) status_icon="⛔ Banido" ;;
                *)      status_icon="❓ $status" ;;
            esac
            echo "| $i | \`${username}\` | ${nome} | ${email} | ${cargo} | ${data_criacao} | ${status_icon} |"
            ((i++)) || true
        done

        echo ""
        echo "---"
        echo ""
        echo "## Resumo"
        echo ""
        local total ativos banidos
        total=$(tail -n +2 "$CSV_FILE" | grep -c '.' 2>/dev/null || echo 0)
        ativos=$(tail -n +2 "$CSV_FILE" | grep -c ',ativo,' 2>/dev/null || echo 0)
        banidos=$(tail -n +2 "$CSV_FILE" | grep -c ',banido,' 2>/dev/null || echo 0)
        echo "- **Total**: ${total} membro(s)"
        echo "- **Ativos**: ${ativos}"
        echo "- **Banidos**: ${banidos}"
        echo ""
        echo "---"
        echo ""
        echo "*Gerado automaticamente por crom-membros/membros/gerar-credenciais.sh*"
    } > "$REPORT_FILE"

    success "Relatório salvo em: ${REPORT_FILE}"
}

# Listar membros do CSV
listar() {
    echo -e "\n  ${PURPLE}${BOLD}👥 MEMBROS CADASTRADOS${NC}\n"
    
    local total
    total=$(tail -n +2 "$CSV_FILE" | grep -c '.' 2>/dev/null || echo 0)

    if [[ "$total" -eq 0 ]]; then
        warn "Nenhum membro cadastrado. Use: $0 adicionar"
        return
    fi

    printf "  ${BOLD}%-4s %-16s %-25s %-25s %-12s %-10s${NC}\n" "#" "USERNAME" "NOME" "EMAIL" "CARGO" "STATUS"
    echo "  ──────────────────────────────────────────────────────────────────────────────────────────"

    local i=1
    tail -n +2 "$CSV_FILE" | while IFS=',' read -r username nome email cargo data_criacao status senha; do
        [[ -z "$username" ]] && continue
        local st
        case "$status" in
            ativo)  st="${GREEN}✅ Ativo${NC}" ;;
            banido) st="${RED}⛔ Ban${NC}" ;;
            *)      st="$status" ;;
        esac
        printf "  %-4s %-16s %-25s %-25s %-12s " "$i" "$username" "$nome" "$email" "$cargo"
        echo -e "$st"
        ((i++)) || true
    done
    echo
}

# Menu
show_menu() {
    echo -e "\n  ${PURPLE}${BOLD}╔═══════════════════════════════════════════╗${NC}"
    echo -e "  ${PURPLE}${BOLD}║   CROM — Gerador de Credenciais           ║${NC}"
    echo -e "  ${PURPLE}${BOLD}╚═══════════════════════════════════════════╝${NC}\n"
    echo -e "    ${CYAN}1${NC}  Adicionar membro"
    echo -e "    ${CYAN}2${NC}  Listar membros"
    echo -e "    ${CYAN}3${NC}  Gerar credencial individual"
    echo -e "    ${CYAN}4${NC}  Gerar todas as credenciais"
    echo -e "    ${CYAN}5${NC}  Gerar relatório"
    echo -e "    ${CYAN}0${NC}  Sair\n"
}

main_menu() {
    while true; do
        show_menu
        read -rp "  Opção: " opt
        case $opt in
            1) adicionar_membro ;;
            2) listar ;;
            3) read -rp "  Username: " u; gerar_credencial_individual "$u" ;;
            4) gerar_todos ;;
            5) gerar_relatorio ;;
            0) exit 0 ;;
            *) warn "Opção inválida" ;;
        esac
        echo
        read -rp "  ${BOLD}Pressione Enter...${NC}"
    done
}

# CLI direto
if [[ $# -gt 0 ]]; then
    case "$1" in
        adicionar) adicionar_membro ;;
        listar)    listar ;;
        gerar)     [[ -n "${2:-}" ]] && gerar_credencial_individual "$2" || gerar_todos ;;
        relatorio) gerar_relatorio ;;
        todos)     gerar_todos ;;
        help|--help|-h)
            echo "Uso: $0 [adicionar|listar|gerar [username]|todos|relatorio]"
            ;;
        *) echo "Comando desconhecido: $1" ;;
    esac
    exit 0
fi

main_menu
