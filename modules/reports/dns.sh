#!/usr/bin/env bash
# Relatório de DNS (15)

# ===== RELATÓRIO 15: DNS =====
report_dns() {
    local f="${_REPORT_DIR}/15_dns.md"
    _md_header "$f" "🌐 DNS e Domínios"

    cat >> "$f" <<EOF
## Verificação de Propagação DNS

| Domínio | IP Esperado | IP Resolvido | Status |
|---|---|---|---|
EOF

    # Domínios do vps.conf
    while IFS='|' read -r vid vname vdomain vstatus; do
        [[ "$vid" =~ ^# ]] && continue
        [[ -z "$vid" || -z "$vdomain" ]] && continue
        local expected="${_VPS_IPS[$vid]:-—}"
        local resolved=$(dig +short A "$vdomain" 2>/dev/null | head -1)
        local icon="✅"
        [[ "$resolved" != "$expected" ]] && icon="❌"
        [[ -z "$resolved" ]] && resolved="NXDOMAIN" && icon="❌"
        echo "| ${vdomain} | ${expected} | ${resolved} | ${icon} |" >> "$f"
    done < "${SCRIPT_DIR}/infra/vps.conf"

    # Subdomínios dos Nginx configs
    echo "" >> "$f"
    echo "### Subdomínios (Nginx)" >> "$f"
    echo "" >> "$f"
    echo "| Subdomínio | VPS | IP Esperado | IP Resolvido | Status |" >> "$f"
    echo "|---|---|---|---|---|" >> "$f"

    for id in "${_VPS_IDS[@]}"; do
        local name="${_VPS_NAMES[$id]}" ip="${_VPS_IPS[$id]}"
        local domains=$(_parse "$id" "NGINX_DOMAINS")
        while IFS= read -r dom; do
            [[ -z "$dom" || "$dom" == "NONE" ]] && continue
            local dom_clean=$(echo "$dom" | xargs)
            [[ -z "$dom_clean" || "$dom_clean" == "_" ]] && continue
            # Skip main domains already checked
            grep -q "|${dom_clean}|" "${SCRIPT_DIR}/infra/vps.conf" 2>/dev/null && continue
            [[ "$dom_clean" == "www."* ]] && continue

            local resolved=$(dig +short A "$dom_clean" 2>/dev/null | head -1)
            local icon="✅"
            [[ "$resolved" != "$ip" ]] && icon="❌"
            [[ -z "$resolved" ]] && resolved="NXDOMAIN" && icon="❌"
            echo "| ${dom_clean} | ${name} | ${ip} | ${resolved} | ${icon} |" >> "$f"
        done <<< "$domains"
    done

    echo "" >> "$f"
    echo -e "  ${GREEN}✓${NC} 15_dns.md"
}
