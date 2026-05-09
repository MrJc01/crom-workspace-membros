#!/usr/bin/env bash
# Relatórios de Serviços (12-14)

# ===== RELATÓRIO 12: NGINX =====
report_nginx() {
    local f="${_REPORT_DIR}/12_nginx.md"
    _md_header "$f" "🌍 Nginx Completo"

    for id in "${_VPS_IDS[@]}"; do
        local name="${_VPS_NAMES[$id]}"

        cat >> "$f" <<EOF
## VPS ${id} — ${name^}

### Sites Habilitados

EOF
        local sites=$(_parse "$id" "NGINX_SITES")
        if [[ "$sites" == "NONE" || -z "$sites" ]]; then
            echo "Nginx não instalado ou sem sites." >> "$f"
        else
            local domains=$(_parse "$id" "NGINX_DOMAINS")
            local upstreams=$(_parse "$id" "NGINX_UPSTREAMS")
            echo "| Site | Domínios | Upstream |" >> "$f"
            echo "|---|---|---|" >> "$f"
            while IFS= read -r site; do
                [[ -z "$site" ]] && continue
                echo "| \`${site}\` | — | — |" >> "$f"
            done <<< "$sites"

            echo "" >> "$f"
            echo "**Domínios configurados:**" >> "$f"
            while IFS= read -r dom; do
                [[ -z "$dom" || "$dom" == "NONE" ]] && continue
                echo "- \`$(echo "$dom" | xargs)\`" >> "$f"
            done <<< "$domains"

            echo "" >> "$f"
            echo "**Upstreams (proxy_pass):**" >> "$f"
            while IFS= read -r up; do
                [[ -z "$up" || "$up" == "NONE" ]] && continue
                echo "- \`$(echo "$up" | xargs)\`" >> "$f"
            done <<< "$upstreams"
        fi

        echo "" >> "$f"
        echo "### Últimos Erros do Nginx" >> "$f"
        echo "" >> "$f"
        echo '```' >> "$f"
        _parse "$id" "NGINX_ERRORS" >> "$f"
        echo '```' >> "$f"

        echo "" >> "$f"
        echo "---" >> "$f"
        echo "" >> "$f"
    done
    echo -e "  ${GREEN}✓${NC} 12_nginx.md"
}

# ===== RELATÓRIO 13: SYSTEMD SERVICES =====
report_servicos() {
    local f="${_REPORT_DIR}/13_servicos.md"
    _md_header "$f" "⚙️ Systemd Services"

    for id in "${_VPS_IDS[@]}"; do
        local name="${_VPS_NAMES[$id]}"

        cat >> "$f" <<EOF
## VPS ${id} — ${name^}

### Serviços Rodando

\`\`\`
$(_parse "$id" "SERVICES_RUNNING")
\`\`\`

### Serviços com Falha

\`\`\`
$(_parse "$id" "SERVICES_FAILED")
\`\`\`

### Timers Ativos

\`\`\`
$(_parse "$id" "TIMERS")
\`\`\`

---

EOF
    done
    echo -e "  ${GREEN}✓${NC} 13_servicos.md"
}

# ===== RELATÓRIO 14: CRON =====
report_cron() {
    local f="${_REPORT_DIR}/14_cron.md"
    _md_header "$f" "⏰ Cron e Timers"

    for id in "${_VPS_IDS[@]}"; do
        local name="${_VPS_NAMES[$id]}"

        cat >> "$f" <<EOF
## VPS ${id} — ${name^}

### Crontab do Root

\`\`\`
$(_parse "$id" "CRONTAB_ROOT")
\`\`\`

### Crontabs dos Membros

\`\`\`
$(_parse "$id" "CRON_MEMBERS")
\`\`\`

### Cron do Sistema (/etc/cron.d/)

\`\`\`
$(_parse "$id" "CRON_SYSTEM")
\`\`\`

---

EOF
    done
    echo -e "  ${GREEN}✓${NC} 14_cron.md"
}
