#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════╗
# ║  CROM Orquestrador — Painel Multi-VPS                       ║
# ║  Versão: 3.0.0                                              ║
# ╚══════════════════════════════════════════════════════════════╝

set -uo pipefail

# Descobrir diretório base
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Carregar módulos (a ordem importa: core primeiro)
source "${SCRIPT_DIR}/modules/core.sh"
source "${SCRIPT_DIR}/modules/vps.sh"
source "${SCRIPT_DIR}/modules/members.sh"
source "${SCRIPT_DIR}/modules/system.sh"
source "${SCRIPT_DIR}/modules/cromia.sh"
source "${SCRIPT_DIR}/modules/reports.sh"

show_menu() {
    clear
    echo -e "${PURPLE}${BOLD}"
    echo '  ╔══════════════════════════════════════════════════╗'
    echo '  ║                                                  ║'
    echo '  ║     ██████╗██████╗  ██████╗ ███╗   ███╗          ║'
    echo '  ║    ██╔════╝██╔══██╗██╔═══██╗████╗ ████║          ║'
    echo '  ║    ██║     ██████╔╝██║   ██║██╔████╔██║          ║'
    echo '  ║    ██║     ██╔══██╗██║   ██║██║╚██╔╝██║          ║'
    echo '  ║    ╚██████╗██║  ██║╚██████╔╝██║ ╚═╝ ██║          ║'
    echo '  ║     ╚═════╝╚═╝  ╚═╝ ╚═════╝╚═╝     ╚═╝          ║'
    echo '  ║                                                  ║'
    echo '  ║      ORQUESTRADOR — Painel Multi-VPS             ║'
    echo '  ║                                                  ║'
    echo '  ╚══════════════════════════════════════════════════╝'
    echo -e "${NC}"

    # Status da VPS ativa
    if [[ -n "${VPS_HOST:-}" ]]; then
        echo -e "  ${DIM}VPS ATIVA:${NC} ${GREEN}🟢 ${CURRENT_VPS_NAME}${NC} ${DIM}(${VPS_HOST})${NC} | $(date '+%d/%m/%Y %H:%M')"
    else
        echo -e "  ${DIM}VPS ATIVA:${NC} ${RED}⚠ nenhuma configurada${NC}"
    fi
    separator
    echo

    echo -e "  ${BOLD}VPS${NC}"
    echo -e "    ${CYAN}V${NC}   Trocar VPS ativa"
    echo -e "    ${CYAN}T${NC}   Status de todas as VPS"
    echo -e "    ${CYAN}D${NC}   Deploy landing page (VPS ativa)"
    echo -e "    ${CYAN}W${NC}   Instalar crom-workspace na VPS"
    echo

    echo -e "  ${BOLD}MEMBROS${NC}"
    echo -e "    ${CYAN}1${NC}   Criar membro"
    echo -e "    ${CYAN}2${NC}   Listar membros"
    echo -e "    ${CYAN}3${NC}   Banir membro"
    echo -e "    ${CYAN}4${NC}   Restaurar membro banido"
    echo -e "    ${CYAN}5${NC}   Alterar senha"
    echo -e "    ${CYAN}6${NC}   Deletar membro (permanente)"
    echo

    echo -e "  ${BOLD}ACESSOS${NC}"
    echo -e "    ${CYAN}7${NC}   Ver log de acessos"
    echo -e "    ${CYAN}8${NC}   Sessões ativas agora"
    echo -e "    ${CYAN}9${NC}   Desconectar sessão"
    echo

    echo -e "  ${BOLD}SERVIDOR${NC}"
    echo -e "    ${CYAN}10${NC}  Gerar relatório (VPS ativa)"
    echo -e "    ${CYAN}11${NC}  Status dos serviços"
    echo -e "    ${CYAN}12${NC}  Configurar SSL"
    echo -e "    ${CYAN}13${NC}  Shell remoto (SSH direto)"
    echo -e "    ${GREEN}R${NC}   📊 ${BOLD}Relatórios .md${NC} (15 ferramentas → todas VPS)"
    echo

    echo -e "  ${BOLD}INTELIGÊNCIA (CromIA)${NC}"
    echo -e "    ${GREEN}15${NC}  Criar conta CromIA"
    echo -e "    ${GREEN}16${NC}  Listar contas CromIA"
    echo -e "    ${GREEN}17${NC}  Injetar créditos (Saldo)"
    echo -e "    ${GREEN}18${NC}  Gerar/Exportar API Key"
    echo
    separator
    echo -e "    ${CYAN}0${NC}   Sair"
    echo
}

main() {
    check_deps

    while true; do
        show_menu
        read -rp "  ${BOLD}Escolha uma opção:${NC} " choice
        echo

        case $choice in
            # VPS
            v|V)  trocar_vps ;;
            t|T)  status_todas_vps ;;
            d|D)  deploy_landing_vps ;;
            w|W)  instalar_workspace_vps ;;
            # Membros
            1)  criar_membro ;;
            2)  listar_membros ;;
            3)  banir_membro ;;
            4)  restaurar_membro ;;
            5)  mudar_senha ;;
            6)  deletar_membro ;;
            # Acessos
            7)  ver_acessos ;;
            8)  ver_sessoes_ativas ;;
            9)  kick_sessao ;;
            # Servidor
            10) gerar_relatorio ;;
            11) status_servicos ;;
            12) ssl_setup ;;
            13) shell_remoto ;;
            r|R)  menu_relatorios ;;
            # CromIA
            15) criar_conta_cromia ;;
            16) listar_contas_cromia ;;
            17) injetar_creditos_cromia ;;
            18) gerar_key_cromia ;;
            # Sair
            0)  echo -e "  ${GREEN}Até logo! 👋${NC}"; exit 0 ;;
            *)  warn "Opção inválida" ;;
        esac

        echo
        read -rp "  ${DIM}Pressione Enter para continuar...${NC}"
    done
}

# ===== MODO CLI DIRETO =====
if [[ $# -gt 0 ]]; then
    check_deps
    case "$1" in
        # VPS
        vps)        listar_vps ;;
        switch)     trocar_vps ;;
        status)     status_todas_vps ;;
        deploy)     deploy_landing_vps ;;
        install-ws) instalar_workspace_vps ;;
        # Membros
        criar)      criar_membro ;;
        listar)     listar_membros ;;
        banir)      banir_membro ;;
        restaurar)  restaurar_membro ;;
        senha)      mudar_senha ;;
        deletar)    deletar_membro ;;
        # Acessos
        acessos)    ver_acessos ;;
        sessoes)    ver_sessoes_ativas ;;
        kick)       kick_sessao ;;
        # Servidor
        relatorio)  gerar_relatorio ;;
        servicos)   status_servicos ;;
        report)     cli_report "${2:-all}" ;;
        ssl)        ssl_setup ;;
        shell)      shell_remoto ;;
        # CromIA
        cromia-criar)   criar_conta_cromia ;;
        cromia-listar)  listar_contas_cromia ;;
        cromia-saldo)   injetar_creditos_cromia ;;
        cromia-key)     gerar_key_cromia ;;
        help|--help|-h)
            echo "Uso: $0 [comando]"
            echo ""
            echo "VPS:      vps | switch | status | deploy | install-ws"
            echo "Membros:  criar | listar | banir | restaurar | senha | deletar"
            echo "Acessos:  acessos | sessoes | kick"
            echo "Report:   report [tipo]  (projetos|recursos|rede|storage|performance|ssl|seguranca|updates|membros|containers|deploys|nginx|servicos|cron|dns|all)"
            echo "Servidor: relatorio | servicos | ssl | shell"
            echo "CromIA:   cromia-criar | cromia-listar | cromia-saldo | cromia-key"
            ;;
        *)  echo "Comando desconhecido: $1. Use '$0 help'" ;;
    esac
    exit 0
fi

main
