#!/usr/bin/env bash
# Relatórios de Infraestrutura (1-5)

# ===== RELATÓRIO 1: PROJETOS NO AR =====
report_projetos() {
    local f="${_REPORT_DIR}/01_projetos-no-ar.md"
    _md_header "$f" "🌐 Projetos no Ar"

    local total_ok=0 total_fail=0 total_proj=0

    for id in "${_VPS_IDS[@]}"; do
        local name="${_VPS_NAMES[$id]}" ip="${_VPS_IPS[$id]}"
        local domain=$(grep "^${id}|" "${SCRIPT_DIR}/infra/vps.conf" 2>/dev/null | cut -d'|' -f3)

        cat >> "$f" <<EOF
## VPS ${id} — ${name^} (\`${domain:-$ip}\`)

| Projeto | URL | Porta | HTTP | Tipo | Responsável |
|---|---|---|---|---|---|
EOF

        # Landing page
        if [[ -n "$domain" ]]; then
            local status=$(_http_check "https://${domain}")
            local icon="🟢"; [[ "$status" != "200" ]] && icon="🔴" && ((total_fail++)) || ((total_ok++))
            echo "| Landing Page | ${domain} | 443 | ${icon} ${status} | Estática | Core |" >> "$f"
            ((total_proj++))
        fi

        # Subdomínios do Nginx (proxied services)
        local domains=$(_parse "$id" "NGINX_DOMAINS")
        while IFS= read -r dom; do
            [[ -z "$dom" || "$dom" == "NONE" || "$dom" == "$domain" || "$dom" == "www.$domain" ]] && continue
            local dom_clean=$(echo "$dom" | xargs)
            [[ -z "$dom_clean" || "$dom_clean" == "_" ]] && continue
            local status=$(_http_check "https://${dom_clean}")
            local icon="🟢"; [[ "$status" != "200" ]] && icon="🔴" && ((total_fail++)) || ((total_ok++))
            local resp="Core"
            [[ "$dom_clean" == *"-"* ]] && resp=$(echo "$dom_clean" | cut -d'-' -f2 | cut -d'.' -f1)
            local tipo="Serviço"
            [[ "$dom_clean" == *"n8n"* ]] && tipo="Automação (n8n)"
            [[ "$dom_clean" == *"api"* || "$dom_clean" == *"cromia"* ]] && tipo="API"
            [[ "$dom_clean" == *"trendhunter"* ]] && tipo="App (Node.js)"
            local sname=$(echo "$dom_clean" | cut -d'.' -f1)
            echo "| ${sname} | ${dom_clean} | 443 | ${icon} ${status} | ${tipo} | ${resp} |" >> "$f"
            ((total_proj++))
        done <<< "$domains"

        # Processos Node/Python diretos (não cobertos pelo Nginx)
        local ports=$(_parse "$id" "PORTS")
        while IFS= read -r line; do
            [[ -z "$line" ]] && continue
            if echo "$line" | grep -qE "node|python|gunicorn|uvicorn"; then
                local port=$(echo "$line" | grep -oP ':\K[0-9]+' | head -1)
                local proc=$(echo "$line" | grep -oP 'users:\(\("\K[^"]+')
                if [[ -n "$port" && "$port" != "22" && "$port" != "80" && "$port" != "443" ]]; then
                    echo "| ${proc:-processo} | ${ip}:${port} | ${port} | — | Processo direto | Membro |" >> "$f"
                fi
            fi
        done <<< "$ports"

        echo "" >> "$f"
    done

    # Resumo
    cat >> "$f" <<EOF
---

## Resumo

| Métrica | Valor |
|---|---|
| **Total de projetos** | ${total_proj} |
| **Online (HTTP 200)** | ${total_ok} |
| **Com problemas** | ${total_fail} |
| **VPS escaneadas** | ${#_VPS_IDS[@]} |
EOF
    echo -e "  ${GREEN}✓${NC} 01_projetos-no-ar.md"
}

# ===== RELATÓRIO 2: RECURSOS =====
report_recursos() {
    local f="${_REPORT_DIR}/02_recursos.md"
    _md_header "$f" "📊 Recursos do Sistema"

    cat >> "$f" <<EOF
## Visão Geral

| VPS | RAM Usada | RAM Total | Disco Usado | Disco Total | CPU | Load (1/5/15) | Uptime |
|---|---|---|---|---|---|---|---|
EOF

    for id in "${_VPS_IDS[@]}"; do
        local name="${_VPS_NAMES[$id]}"
        local ram=$(_parse "$id" "RAM")
        local disk=$(_parse "$id" "DISK")
        local load=$(_parse "$id" "LOAD")
        local cores=$(_parse "$id" "CPU_CORES")
        local up=$(_parse "$id" "UPTIME_P")

        local ram_total=$(echo "$ram" | awk '{print $1}')
        local ram_used=$(echo "$ram" | awk '{print $2}')
        local disk_total=$(echo "$disk" | awk '{print $1}')
        local disk_used=$(echo "$disk" | awk '{print $2}')
        local disk_pct=$(echo "$disk" | awk '{print $4}')
        local load_vals=$(echo "$load" | awk '{print $1"/"$2"/"$3}')

        local icon="🟢"
        local pct_num=${disk_pct//%/}
        [[ "${pct_num:-0}" -gt 80 ]] && icon="🔴"
        [[ "${pct_num:-0}" -gt 60 ]] && icon="🟡"

        echo "| ${icon} ${name} | ${ram_used:-—} | ${ram_total:-—} | ${disk_used:-—} | ${disk_total:-—} | ${cores:-—} cores | ${load_vals:-—} | ${up:-—} |" >> "$f"
    done

    # Detalhamento por VPS
    for id in "${_VPS_IDS[@]}"; do
        local name="${_VPS_NAMES[$id]}"
        local swap=$(_parse "$id" "SWAP")
        local os=$(_parse "$id" "OS")
        local kernel=$(_parse "$id" "KERNEL")
        local hostname=$(_parse "$id" "HOSTNAME")

        cat >> "$f" <<EOF

---

### VPS ${id} — ${name^}

| Campo | Valor |
|---|---|
| **Hostname** | \`${hostname:-—}\` |
| **OS** | ${os:-—} |
| **Kernel** | ${kernel:-—} |
| **Swap** | ${swap:-—} |
EOF
    done
    echo -e "  ${GREEN}✓${NC} 02_recursos.md"
}

# ===== RELATÓRIO 3: REDE =====
report_rede() {
    local f="${_REPORT_DIR}/03_rede.md"
    _md_header "$f" "🔌 Portas e Rede"

    for id in "${_VPS_IDS[@]}"; do
        local name="${_VPS_NAMES[$id]}" ip="${_VPS_IPS[$id]}"
        local conns=$(_parse "$id" "CONNECTIONS")

        cat >> "$f" <<EOF
## VPS ${id} — ${name^} (\`${ip}\`)

**Conexões ativas:** ${conns:-0}

### Portas TCP (LISTEN)

\`\`\`
$(_parse "$id" "PORTS")
\`\`\`

### Portas UDP (LISTEN)

\`\`\`
$(_parse "$id" "PORTS_UDP")
\`\`\`

---

EOF
    done
    echo -e "  ${GREEN}✓${NC} 03_rede.md"
}

# ===== RELATÓRIO 4: STORAGE =====
report_storage() {
    local f="${_REPORT_DIR}/04_storage.md"
    _md_header "$f" "💾 Storage por Usuário"

    for id in "${_VPS_IDS[@]}"; do
        local name="${_VPS_NAMES[$id]}"
        local disk=$(_parse "$id" "DISK")
        local inodes=$(_parse "$id" "DISK_INODES")

        cat >> "$f" <<EOF
## VPS ${id} — ${name^}

**Disco:** ${disk:-—} | **Inodes:** ${inodes:-—}

### /home (por usuário)

\`\`\`
$(_parse "$id" "HOME_USAGE")
\`\`\`

### /var/www (sites)

\`\`\`
$(_parse "$id" "WWW_USAGE")
\`\`\`

### /var/log

\`\`\`
$(_parse "$id" "LOG_USAGE")
\`\`\`

### Top 10 maiores arquivos (>50MB)

\`\`\`
$(_parse "$id" "BIG_FILES")
\`\`\`

---

EOF
    done
    echo -e "  ${GREEN}✓${NC} 04_storage.md"
}

# ===== RELATÓRIO 5: PERFORMANCE =====
report_performance() {
    local f="${_REPORT_DIR}/05_performance.md"
    _md_header "$f" "⚡ Performance"

    for id in "${_VPS_IDS[@]}"; do
        local name="${_VPS_NAMES[$id]}"
        local load=$(_parse "$id" "LOAD")

        cat >> "$f" <<EOF
## VPS ${id} — ${name^}

**Load Average:** ${load:-—}

### Top 10 Processos por CPU

\`\`\`
$(_parse "$id" "TOP_CPU")
\`\`\`

### Top 10 Processos por RAM

\`\`\`
$(_parse "$id" "TOP_MEM")
\`\`\`

---

EOF
    done
    echo -e "  ${GREEN}✓${NC} 05_performance.md"
}
