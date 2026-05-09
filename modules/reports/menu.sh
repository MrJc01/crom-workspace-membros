#!/usr/bin/env bash
# Menu e CLI de Relatórios

# ===== RELATÓRIO COMPLETO (CONSOLIDADO) =====
report_all() {
    local f="${_REPORT_DIR}/full_report.md"
    _md_header "$f" "📋 Relatório Completo — Ecossistema CROM"

    # Resumo executivo
    cat >> "$f" <<EOF
## Resumo Executivo

| Métrica | Valor |
|---|---|
| **Data** | $(date '+%d/%m/%Y %H:%M') |
| **VPS Online** | ${#_VPS_IDS[@]} |
EOF

    for id in "${_VPS_IDS[@]}"; do
        local name="${_VPS_NAMES[$id]}" ip="${_VPS_IPS[$id]}"
        local ram=$(_parse "$id" "RAM")
        local disk=$(_parse "$id" "DISK")
        local up=$(_parse "$id" "UPTIME_P")
        echo "| **${name^}** | ${ip} — RAM: $(echo "$ram" | awk '{print $2"/"$1}') — Disco: $(echo "$disk" | awk '{print $2"/"$1" ("$4")"}') — ${up:-—} |" >> "$f"
    done

    echo "" >> "$f"
    echo "---" >> "$f"
    echo "" >> "$f"

    # Concatenar todos os relatórios individuais
    for num in 01 02 03 04 05 06 07 08 09 10 11 12 13 14 15; do
        local part=$(ls "${_REPORT_DIR}/${num}_"*.md 2>/dev/null | head -1)
        if [[ -f "$part" ]]; then
            echo "" >> "$f"
            # Pular o header de cada sub-relatório (primeiras 6 linhas)
            tail -n +7 "$part" >> "$f"
            echo "" >> "$f"
        fi
    done

    echo -e "  ${GREEN}✓${NC} full_report.md"
}

# ===== SUBMENU INTERATIVO =====
menu_relatorios() {
    header "📊 GERADOR DE RELATÓRIOS"
    echo -e "  ${BOLD}Escolha o relatório:${NC}"
    echo
    echo -e "  ${BOLD}INFRAESTRUTURA${NC}"
    echo -e "    ${CYAN}1${NC}   🌐 Projetos no ar (sites, APIs, health check)"
    echo -e "    ${CYAN}2${NC}   📊 Recursos (RAM, disco, CPU, uptime)"
    echo -e "    ${CYAN}3${NC}   🔌 Portas e rede (listening, conexões)"
    echo -e "    ${CYAN}4${NC}   💾 Storage (uso por usuário, maiores arquivos)"
    echo -e "    ${CYAN}5${NC}   ⚡ Performance (top processos, load)"
    echo
    echo -e "  ${BOLD}SEGURANÇA${NC}"
    echo -e "    ${CYAN}6${NC}   🔒 Certificados SSL (validade, alertas)"
    echo -e "    ${CYAN}7${NC}   🛡️  Auditoria de segurança (UFW, fail2ban, SSH)"
    echo -e "    ${CYAN}8${NC}   📦 Atualizações pendentes (kernel, pacotes)"
    echo
    echo -e "  ${BOLD}MEMBROS${NC}"
    echo -e "    ${CYAN}9${NC}   👥 Membros e acessos (status, login, linger)"
    echo -e "    ${CYAN}10${NC}  🐳 Containers dos membros (Podman/Quadlets)"
    echo -e "    ${CYAN}11${NC}  🚀 Projetos dos membros (frameworks, deploys)"
    echo
    echo -e "  ${BOLD}SERVIÇOS${NC}"
    echo -e "    ${CYAN}12${NC}  🌍 Nginx completo (vhosts, erros, upstreams)"
    echo -e "    ${CYAN}13${NC}  ⚙️  Systemd services (rodando, falhos, timers)"
    echo -e "    ${CYAN}14${NC}  ⏰ Cron e timers (root + membros)"
    echo
    echo -e "  ${BOLD}VISÃO GERAL${NC}"
    echo -e "    ${CYAN}15${NC}  🌐 DNS e domínios (propagação, verificação)"
    echo
    separator
    echo -e "    ${GREEN}0${NC}   📋 ${BOLD}GERAR TODOS${NC} (15 relatórios + consolidado)"
    echo -e "    ${CYAN}Q${NC}   Voltar ao menu principal"
    echo
    read -rp "  ${BOLD}Opção:${NC} " rchoice
    echo

    [[ "${rchoice,,}" == "q" || -z "$rchoice" ]] && return

    header "📊 GERANDO RELATÓRIOS..."
    separator

    # Coletar dados de todas VPS
    _collect_all
    _report_init

    echo
    info "📝 Gerando relatórios..."
    echo

    case "$rchoice" in
        1)  report_projetos ;;
        2)  report_recursos ;;
        3)  report_rede ;;
        4)  report_storage ;;
        5)  report_performance ;;
        6)  report_ssl ;;
        7)  report_seguranca ;;
        8)  report_updates ;;
        9)  report_membros ;;
        10) report_containers ;;
        11) report_deploys ;;
        12) report_nginx ;;
        13) report_servicos ;;
        14) report_cron ;;
        15) report_dns ;;
        0)
            report_projetos
            report_recursos
            report_rede
            report_storage
            report_performance
            report_ssl
            report_seguranca
            report_updates
            report_membros
            report_containers
            report_deploys
            report_nginx
            report_servicos
            report_cron
            report_dns
            report_all
            ;;
        *)  warn "Opção inválida"; return ;;
    esac

    echo
    success "Relatórios salvos em: ${_REPORT_DIR}/"
    success "Atalho: relatorios/ultimo/"
    log "REPORT: tipo=${rchoice} dir=${_REPORT_TS}"
}

# ===== CLI ENTRY POINT =====
cli_report() {
    local tipo="${1:-all}"

    header "📊 GERANDO RELATÓRIOS..."
    separator

    _collect_all
    _report_init

    echo
    info "📝 Gerando relatórios..."
    echo

    case "$tipo" in
        all|todos)
            report_projetos; report_recursos; report_rede
            report_storage; report_performance; report_ssl
            report_seguranca; report_updates; report_membros
            report_containers; report_deploys; report_nginx
            report_servicos; report_cron; report_dns
            report_all
            ;;
        projetos)     report_projetos ;;
        recursos)     report_recursos ;;
        rede)         report_rede ;;
        storage)      report_storage ;;
        performance)  report_performance ;;
        ssl)          report_ssl ;;
        seguranca)    report_seguranca ;;
        updates)      report_updates ;;
        membros)      report_membros ;;
        containers)   report_containers ;;
        deploys)      report_deploys ;;
        nginx)        report_nginx ;;
        servicos)     report_servicos ;;
        cron)         report_cron ;;
        dns)          report_dns ;;
        *)
            error "Tipo desconhecido: ${tipo}"
            echo "  Tipos: projetos|recursos|rede|storage|performance|ssl|seguranca|updates|membros|containers|deploys|nginx|servicos|cron|dns|all"
            return 1
            ;;
    esac

    echo
    success "Relatórios salvos em: ${_REPORT_DIR}/"
    success "Atalho: relatorios/ultimo/"
    log "REPORT_CLI: tipo=${tipo} dir=${_REPORT_TS}"
}
