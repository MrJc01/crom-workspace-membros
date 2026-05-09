#!/usr/bin/env bash
# Relatórios de Segurança (6-8)

# ===== RELATÓRIO 6: SSL =====
report_ssl() {
    local f="${_REPORT_DIR}/06_ssl.md"
    _md_header "$f" "🔒 Certificados SSL"

    cat >> "$f" <<EOF
## Visão Consolidada

| Domínio | VPS | Expira em | Dias | Status |
|---|---|---|---|---|
EOF

    for id in "${_VPS_IDS[@]}"; do
        local name="${_VPS_NAMES[$id]}"
        local ssl=$(_parse "$id" "SSL")
        [[ "$ssl" == "NONE" || -z "$ssl" ]] && continue

        local current_domain="" current_expiry=""
        while IFS= read -r line; do
            if echo "$line" | grep -q "Domains:"; then
                current_domain=$(echo "$line" | sed 's/.*Domains: //')
            fi
            if echo "$line" | grep -q "Expiry Date:"; then
                current_expiry=$(echo "$line" | sed 's/.*Expiry Date: //')
                local days=$(echo "$current_expiry" | grep -oP 'VALID: \K[0-9]+')
                local icon="🟢"
                [[ "${days:-0}" -lt 15 ]] && icon="🔴"
                [[ "${days:-0}" -lt 30 && "${days:-0}" -ge 15 ]] && icon="🟡"
                local expiry_date=$(echo "$current_expiry" | cut -d' ' -f1)
                echo "| ${current_domain} | ${name} | ${expiry_date} | ${days:-?} dias | ${icon} |" >> "$f"
            fi
        done <<< "$ssl"
    done

    echo "" >> "$f"

    # Alertas
    echo "## ⚠️ Alertas" >> "$f"
    echo "" >> "$f"
    local has_alert=false
    for id in "${_VPS_IDS[@]}"; do
        local ssl=$(_parse "$id" "SSL")
        while IFS= read -r line; do
            if echo "$line" | grep -q "VALID:"; then
                local days=$(echo "$line" | grep -oP 'VALID: \K[0-9]+')
                if [[ "${days:-999}" -lt 30 ]]; then
                    echo "> [!WARNING]" >> "$f"
                    echo "> Certificado com menos de 30 dias de validade detectado!" >> "$f"
                    has_alert=true
                fi
            fi
        done <<< "$ssl"
    done
    $has_alert || echo "Nenhum alerta. Todos os certificados estão saudáveis. ✅" >> "$f"

    echo -e "  ${GREEN}✓${NC} 06_ssl.md"
}

# ===== RELATÓRIO 7: SEGURANÇA =====
report_seguranca() {
    local f="${_REPORT_DIR}/07_seguranca.md"
    _md_header "$f" "🛡️ Auditoria de Segurança"

    for id in "${_VPS_IDS[@]}"; do
        local name="${_VPS_NAMES[$id]}"
        local failed=$(_parse "$id" "FAILED_SSH")
        local failed_ips=$(_parse "$id" "FAILED_SSH_IPS")
        local sshd=$(_parse "$id" "SSHD_CONFIG")
        local sudoers=$(_parse "$id" "SUDOERS")

        cat >> "$f" <<EOF
## VPS ${id} — ${name^}

### SSH

| Config | Valor |
|---|---|
| **Tentativas de login falhas (24h)** | ${failed:-0} |
| **Sudoers** | ${sudoers:-root} |

\`\`\`
${sshd:-Config padrão}
\`\`\`

### Top IPs com login falho (24h)

\`\`\`
${failed_ips:-Nenhum}
\`\`\`

### Firewall (UFW)

\`\`\`
$(_parse "$id" "UFW")
\`\`\`

### Fail2Ban

\`\`\`
$(_parse "$id" "FAIL2BAN")
\`\`\`

---

EOF
    done
    echo -e "  ${GREEN}✓${NC} 07_seguranca.md"
}

# ===== RELATÓRIO 8: UPDATES =====
report_updates() {
    local f="${_REPORT_DIR}/08_updates.md"
    _md_header "$f" "📦 Atualizações Pendentes"

    cat >> "$f" <<EOF
## Visão Geral

| VPS | OS | Kernel | Pacotes Pendentes | Segurança |
|---|---|---|---|---|
EOF

    for id in "${_VPS_IDS[@]}"; do
        local name="${_VPS_NAMES[$id]}"
        local os=$(_parse "$id" "OS")
        local kernel=$(_parse "$id" "KERNEL")
        local updates=$(_parse "$id" "UPDATES")
        local sec=$(_parse "$id" "UPDATES_SEC")

        local icon="🟢"; [[ "${updates:-0}" -gt 0 ]] && icon="🟡"
        [[ "${sec:-0}" -gt 0 ]] && icon="🔴"

        echo "| ${icon} ${name} | ${os:-—} | ${kernel:-—} | ${updates:-0} | ${sec:-0} |" >> "$f"
    done

    for id in "${_VPS_IDS[@]}"; do
        local name="${_VPS_NAMES[$id]}"
        local nr=$(_parse "$id" "NEEDRESTART")
        if [[ -n "$nr" && "$nr" != "NONE" ]]; then
            cat >> "$f" <<EOF

### VPS ${id} — ${name^} — Needrestart

\`\`\`
${nr}
\`\`\`
EOF
        fi
    done
    echo -e "  ${GREEN}✓${NC} 08_updates.md"
}
