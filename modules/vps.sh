#!/usr/bin/env bash

# ╔══════════════════════════════════════════════════════════════╗
# ║  CROM VPS Module — Gestão Multi-VPS                         ║
# ╚══════════════════════════════════════════════════════════════╝

# Listar todas as VPS registradas
listar_vps() {
    header "🖥  VPS DO ECOSSISTEMA"
    printf "  ${BOLD}%-4s %-14s %-22s %-18s %-10s${NC}\n" "ID" "NOME" "DOMÍNIO" "IP" "STATUS"
    separator

    while IFS='|' read -r id nome dominio status; do
        [[ "$id" =~ ^# ]] && continue
        [[ -z "$id" ]] && continue
        local host_var="VPS${id}_HOST"
        local ip="${!host_var:-—}"

        # Indicador de VPS ativa
        local marker=""
        [[ "$id" == "$CURRENT_VPS_ID" ]] && marker=" ${GREEN}◄${NC}"

        printf "  %-4s %-14s %-22s %-18s %-10s" "$id" "$nome" "$dominio" "$ip" "$status"
        echo -e "$marker"
    done < "${SCRIPT_DIR}/infra/vps.conf"
    echo
}

# Menu para trocar VPS ativa
trocar_vps() {
    listar_vps
    read -rp "  ID da VPS para ativar: " vps_id
    [[ -z "$vps_id" ]] && return

    if select_vps "$vps_id"; then
        success "VPS ativa: ${CURRENT_VPS_NAME} (${VPS_HOST})"
        log "VPS_SWITCH: para=${CURRENT_VPS_NAME} id=${CURRENT_VPS_ID}"
    fi
}

# Status rápido de TODAS as VPS (conecta em cada uma)
status_todas_vps() {
    header "📡 STATUS DE TODAS AS VPS"
    printf "  %-14s %-18s %-6s %-14s %-14s\n" "NOME" "IP" "PING" "RAM" "DISCO"
    separator

    # Salvar estado atual
    local save_id="$CURRENT_VPS_ID"
    local save_host="$VPS_HOST"
    local save_user="$VPS_USER"
    local save_pass="$VPS_PASS"
    local save_name="$CURRENT_VPS_NAME"

    # Usa fd 3 para ler o arquivo — evita que SSH consuma o stdin do while loop
    while IFS='|' read -r -u 3 id nome dominio vps_status; do
        [[ "$id" =~ ^# ]] && continue
        [[ -z "$id" ]] && continue
        local host_var="VPS${id}_HOST"
        local ip="${!host_var}"

        if [[ -z "$ip" ]]; then
            printf "  ⚫ %-12s %-18s %-6s %-14s %-14s\n" "$nome" "—" "—" "—" "(sem IP)"
            continue
        fi

        select_vps "$id" 2>/dev/null

        # ssh -n impede consumo do stdin (que quebraria o while loop)
        local ping_result
        if ping_result=$(sshpass -p "$VPS_PASS" ssh -n $SSH_OPTS "${VPS_USER}@${VPS_HOST}" "echo ok" 2>/dev/null) && [[ "$ping_result" == *"ok"* ]]; then
            local ram disk
            ram=$(sshpass -p "$VPS_PASS" ssh -n $SSH_OPTS "${VPS_USER}@${VPS_HOST}" "free -h 2>/dev/null | awk '/Mem:/{printf \"%s/%s\", \$3, \$2}'" 2>/dev/null) || ram="—"
            disk=$(sshpass -p "$VPS_PASS" ssh -n $SSH_OPTS "${VPS_USER}@${VPS_HOST}" "df -h / 2>/dev/null | awk 'NR==2{printf \"%s/%s\", \$3, \$2}'" 2>/dev/null) || disk="—"
            [[ -z "$ram" ]] && ram="—"
            [[ -z "$disk" ]] && disk="—"
            printf "  🟢 %-12s %-18s %-6s %-14s %-14s\n" "$nome" "$ip" "OK" "$ram" "$disk"
        else
            printf "  🔴 %-12s %-18s %-6s %-14s %-14s\n" "$nome" "$ip" "FAIL" "—" "OFFLINE"
        fi
    done 3< "${SCRIPT_DIR}/infra/vps.conf"

    # Restaurar estado
    CURRENT_VPS_ID="$save_id"
    VPS_HOST="$save_host"
    VPS_USER="$save_user"
    VPS_PASS="$save_pass"
    CURRENT_VPS_NAME="$save_name"
    echo
}

# Deploy landing page na VPS ativa
deploy_landing_vps() {
    header "🌐 DEPLOY LANDING PAGE"
    local vps_name="${CURRENT_VPS_NAME}"
    local site_dir="${SCRIPT_DIR}/sites/${vps_name}"

    if [[ ! -d "$site_dir" ]]; then
        warn "Pasta sites/${vps_name}/ não encontrada."
        read -rp "  Gerar a partir do template? (s/N): " use_tpl
        if [[ "${use_tpl,,}" == "s" ]]; then
            cp -r "${SCRIPT_DIR}/sites/_template" "$site_dir"
            sed -i "s/{{VPS_NAME}}/${vps_name^}/g" "${site_dir}/index.html"
            sed -i "s/{{VPS_DOMAIN}}/$(grep "^${CURRENT_VPS_ID}|" "${SCRIPT_DIR}/infra/vps.conf" | cut -d'|' -f3)/g" "${site_dir}/index.html"
            success "Landing page gerada em sites/${vps_name}/"
        else
            return
        fi
    fi

    info "Enviando landing page para ${VPS_HOST} (${vps_name})..."
    sshpass -p "$VPS_PASS" scp -r $SSH_OPTS "${site_dir}"/* "${VPS_USER}@${VPS_HOST}:/var/www/crom-me/"
    remote "nginx -t && systemctl reload nginx"
    success "Landing page deployada na VPS ${vps_name}!"
    log "DEPLOY_LANDING: vps=${vps_name} por=$(whoami)"
}

# Instalar crom-workspace em uma VPS
instalar_workspace_vps() {
    header "📦 INSTALAR CROM-WORKSPACE NA VPS"
    info "VPS ativa: ${CURRENT_VPS_NAME} (${VPS_HOST})"
    read -rp "  Confirmar instalação do crom-workspace? (s/N): " confirm
    [[ "${confirm,,}" != "s" ]] && { info "Cancelado"; return; }

    local ws_dir="${SCRIPT_DIR}/crom-workspace"
    if [[ ! -d "$ws_dir" ]]; then
        error "crom-workspace/ não encontrado em ${ws_dir}"
        return
    fi

    info "Enviando crom-workspace para o servidor..."
    sshpass -p "$VPS_PASS" scp -r $SSH_OPTS "${ws_dir}/cli/crom-ws" "${VPS_USER}@${VPS_HOST}:/tmp/"
    sshpass -p "$VPS_PASS" scp -r $SSH_OPTS "${ws_dir}/cli/crom-publish-helper" "${VPS_USER}@${VPS_HOST}:/tmp/"
    sshpass -p "$VPS_PASS" scp -r $SSH_OPTS "${ws_dir}/cli/modules" "${VPS_USER}@${VPS_HOST}:/tmp/"
    sshpass -p "$VPS_PASS" scp -r $SSH_OPTS "${ws_dir}/monitor/crom-monitor.sh" "${VPS_USER}@${VPS_HOST}:/tmp/"
    sshpass -p "$VPS_PASS" scp -r $SSH_OPTS "${ws_dir}/install.sh" "${VPS_USER}@${VPS_HOST}:/tmp/"

    info "Executando instalador..."
    remote "cd /tmp && cp crom-ws . && cp crom-publish-helper . && cp crom-monitor.sh . && bash install.sh"

    success "crom-workspace instalado na VPS ${CURRENT_VPS_NAME}!"
    log "INSTALL_WORKSPACE: vps=${CURRENT_VPS_NAME} por=$(whoami)"
}
