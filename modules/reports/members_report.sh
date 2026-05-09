#!/usr/bin/env bash
# Relatórios de Membros (9-11)

# ===== RELATÓRIO 9: MEMBROS =====
report_membros() {
    local f="${_REPORT_DIR}/09_membros.md"
    _md_header "$f" "👥 Membros e Acessos"

    for id in "${_VPS_IDS[@]}"; do
        local name="${_VPS_NAMES[$id]}"
        local members=$(_parse "$id" "MEMBERS_STATUS")
        [[ "$members" == "NONE" || -z "$members" ]] && continue

        cat >> "$f" <<EOF
## VPS ${id} — ${name^}

| Usuário | Status | Último Login | Linger | Disco |
|---|---|---|---|---|
EOF
        while IFS='|' read -r user st ll linger du_s; do
            [[ -z "$user" ]] && continue
            local icon="✅"; [[ "$st" == "L" ]] && icon="⛔"
            echo "| ${user} | ${icon} ${st} | ${ll:-Nunca} | ${linger:-no} | ${du_s:-—} |" >> "$f"
        done <<< "$members"

        echo "" >> "$f"
    done
    echo -e "  ${GREEN}✓${NC} 09_membros.md"
}

# ===== RELATÓRIO 10: CONTAINERS =====
report_containers() {
    local f="${_REPORT_DIR}/10_containers.md"
    _md_header "$f" "🐳 Containers dos Membros"

    for id in "${_VPS_IDS[@]}"; do
        local name="${_VPS_NAMES[$id]}"

        cat >> "$f" <<EOF
## VPS ${id} — ${name^}

### Containers Root

EOF
        local root_ct=$(_parse "$id" "CONTAINERS_ROOT")
        if [[ "$root_ct" == "NONE" || -z "$root_ct" ]]; then
            echo "Nenhum container root rodando." >> "$f"
        else
            echo "| Nome | Status | Portas | Imagem |" >> "$f"
            echo "|---|---|---|---|" >> "$f"
            while IFS='|' read -r cname cstatus cports cimage; do
                [[ -z "$cname" ]] && continue
                echo "| ${cname} | ${cstatus} | ${cports:-—} | ${cimage} |" >> "$f"
            done <<< "$root_ct"
        fi

        echo "" >> "$f"
        echo "### Containers de Membros (Rootless)" >> "$f"
        echo "" >> "$f"

        local user_ct=$(_parse "$id" "USER_CONTAINERS")
        if [[ -z "$user_ct" ]]; then
            echo "Nenhum container de membro rodando." >> "$f"
        else
            local current_user=""
            while IFS= read -r line; do
                if [[ "$line" == USER=* ]]; then
                    current_user="${line#USER=}"
                    echo "" >> "$f"
                    echo "#### 👤 ${current_user}" >> "$f"
                    echo "" >> "$f"
                    echo "| Nome | Status | Portas | Imagem |" >> "$f"
                    echo "|---|---|---|---|" >> "$f"
                elif [[ "$line" == QUADLETS=* ]]; then
                    current_user="${line#QUADLETS=}"
                    echo "" >> "$f"
                    echo "**Quadlets de ${current_user}:**" >> "$f"
                elif [[ -n "$line" && -n "$current_user" ]]; then
                    if echo "$line" | grep -q '|'; then
                        IFS='|' read -r cname cstatus cports cimage <<< "$line"
                        echo "| ${cname} | ${cstatus} | ${cports:-—} | ${cimage} |" >> "$f"
                    else
                        echo "- \`${line}\`" >> "$f"
                    fi
                fi
            done <<< "$user_ct"
        fi

        echo "" >> "$f"
        echo "---" >> "$f"
        echo "" >> "$f"
    done
    echo -e "  ${GREEN}✓${NC} 10_containers.md"
}

# ===== RELATÓRIO 11: DEPLOYS =====
report_deploys() {
    local f="${_REPORT_DIR}/11_deploys.md"
    _md_header "$f" "🚀 Projetos dos Membros"

    cat >> "$f" <<EOF
## Inventário de Projetos

| VPS | Membro | Projeto | Framework | Status |
|---|---|---|---|---|
EOF

    for id in "${_VPS_IDS[@]}"; do
        local name="${_VPS_NAMES[$id]}"
        local projects=$(_parse "$id" "USER_PROJECTS")
        [[ -z "$projects" ]] && continue

        while IFS='|' read -r user proj ftype; do
            [[ -z "$user" ]] && continue
            echo "| ${name} | ${user} | ${proj} | ${ftype} | Deployado |" >> "$f"
        done <<< "$projects"
    done

    echo "" >> "$f"
    echo -e "  ${GREEN}✓${NC} 11_deploys.md"
}
