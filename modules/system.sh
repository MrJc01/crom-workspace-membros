#!/usr/bin/env bash

ver_acessos() {
    header "📋 LOG DE ACESSOS RECENTES"
    
    read -rp "  Filtrar por username (Enter para todos): " username
    
    if [[ -n "$username" ]]; then
        info "Últimos acessos de '${username}':"
        separator
        remote "last -a -n 20 '${username}' 2>/dev/null || echo '  Sem registros'"
    else
        info "Últimos 30 acessos ao servidor:"
        separator
        remote "last -a -n 30 2>/dev/null | head -35"
    fi
    echo
}

ver_sessoes_ativas() {
    header "🔴 SESSÕES ATIVAS AGORA"
    remote "
        echo '  Usuários conectados agora:'
        echo '  ─────────────────────────────────────'
        who -u 2>/dev/null | while read -r line; do
            echo \"    \$line\"
        done
        total=\$(who | wc -l)
        echo ''
        echo \"  Total: \$total sessão(ões) ativa(s)\"
    " 2>/dev/null
    echo
}

kick_sessao() {
    header "⚡ DESCONECTAR SESSÃO"
    ver_sessoes_ativas
    separator
    read -rp "  Username para desconectar: " username
    if [[ -z "$username" ]]; then return; fi

    remote "pkill -u '${username}' 2>/dev/null || true"
    success "Sessões de '${username}' encerradas"
    log "KICK: usuario=${username} por=$(whoami)"
}

gerar_relatorio() {
    header "📊 RELATÓRIO DO SERVIDOR"
    
    remote "
        echo '  ╔══════════════════════════════════════════════╗'
        echo '  ║      RELATÓRIO VPS CROM — MEMBROS            ║'
        echo '  ╚══════════════════════════════════════════════╝'
        echo ''
        echo '  📅 Data: $(date \"+%Y-%m-%d %H:%M:%S %Z\")'
        echo '  🖥  Host: $(hostname)'
        echo '  🐧 OS: $(cat /etc/os-release | grep PRETTY | cut -d\\\" -f2)'
        echo ''
        echo '  ═══ RECURSOS ═══'
        echo \"  CPU:      \$(nproc) core(s)\"
        echo \"  RAM:      \$(free -h | awk '/Mem:/ {printf \"%s / %s (%s usado)\", \$3, \$2, \$5}')\"
        echo \"  Disco:    \$(df -h / | awk 'NR==2 {printf \"%s / %s (%s usado)\", \$3, \$2, \$5}')\"
        echo \"  Uptime:   \$(uptime -p)\"
        echo \"  Load:     \$(cat /proc/loadavg | awk '{print \$1, \$2, \$3}')\"
        echo ''
        echo '  ═══ MEMBROS ═══'
        gid=\$(getent group ${MEMBERS_GROUP} 2>/dev/null | cut -d: -f3)
        if [[ -n \"\$gid\" ]]; then
            total=\$(awk -F: -v gid=\"\$gid\" '\$4==gid' /etc/passwd | wc -l)
            ativos=\$(awk -F: -v gid=\"\$gid\" '\$4==gid {print \$1}' /etc/passwd | while read u; do
                s=\$(passwd -S \"\$u\" 2>/dev/null | awk '{print \$2}')
                [[ \"\$s\" == 'P' ]] && echo \$u
            done | wc -l)
            banidos=\$((total - ativos))
            echo \"  Total:    \$total membro(s)\"
            echo \"  Ativos:   \$ativos\"
            echo \"  Banidos:  \$banidos\"
        else
            echo '  Grupo ${MEMBERS_GROUP} não criado ainda'
        fi
        echo ''
        echo '  ═══ REDE ═══'
        echo \"  Conexões: \$(ss -tun | tail -n +2 | wc -l) ativas\"
        echo \"  SSH:      \$(ss -tun | grep ':22' | wc -l) sessões\"
        echo \"  HTTP:     \$(ss -tun | grep -E ':80|:443' | wc -l) conexões\"
        echo ''
        echo '  ═══ SEGURANÇA ═══'
        echo \"  UFW:      \$(ufw status 2>/dev/null | head -1)\"
        echo \"  Fail2ban: \$(systemctl is-active fail2ban 2>/dev/null || echo 'não instalado')\"
        echo \"  Última atualização: \$(stat -c '%y' /var/lib/apt/lists/ 2>/dev/null | cut -d' ' -f1 || echo 'N/A')\"
        echo ''
        echo '  ═══ NGINX ═══'
        echo \"  Status:   \$(systemctl is-active nginx 2>/dev/null)\"
        echo \"  Sites:    \$(ls /etc/nginx/sites-enabled/ 2>/dev/null | tr '\n' ', ')\"
        echo ''
        echo '  ═══ SSL ═══'
        certbot certificates 2>/dev/null | grep -E 'Domains|Expiry' | sed 's/^/  /' || echo '  Nenhum certificado SSL emitido'
        echo ''
        echo '  ═══ ÚLTIMOS 5 LOGINS ═══'
        last -n 5 2>/dev/null | head -5 | sed 's/^/  /'
    " 2>/dev/null

    echo
    read -rp "  Salvar relatório em arquivo? (s/N): " save
    if [[ "${save,,}" == "s" ]]; then
        local filename="relatorio-crom-$(date +%Y%m%d-%H%M%S).txt"
        remote "
            echo 'RELATÓRIO VPS CROM — $(date)' 
            echo '================================'
            echo 'RAM:' \$(free -h | awk '/Mem:/ {print \$3 \"/\" \$2}')
            echo 'Disco:' \$(df -h / | awk 'NR==2 {print \$3 \"/\" \$2}')
            echo 'Uptime:' \$(uptime -p)
            echo 'Membros do grupo ${MEMBERS_GROUP}:'
            getent group ${MEMBERS_GROUP} 2>/dev/null
            echo 'Últimos 20 logins:'
            last -n 20 2>/dev/null
        " > "$filename" 2>/dev/null
        success "Relatório salvo em: ${filename}"
    fi
}

status_servicos() {
    header "⚙️  STATUS DOS SERVIÇOS"
    remote "
        for svc in nginx ssh ufw certbot.timer fail2ban; do
            status=\$(systemctl is-active \$svc 2>/dev/null || echo 'não encontrado')
            if [[ \"\$status\" == 'active' ]]; then
                printf '  ✅ %-20s %s\n' \"\$svc\" \"ativo\"
            elif [[ \"\$status\" == 'inactive' ]]; then
                printf '  ⬚  %-20s %s\n' \"\$svc\" \"inativo\"
            else
                printf '  ❓ %-20s %s\n' \"\$svc\" \"\$status\"
            fi
        done
    " 2>/dev/null
    echo
}

deploy_site() {
    header "🚀 DEPLOY DO SITE"
    local local_site_dir
    read -rp "  Caminho local da pasta do site (default: ./site): " local_site_dir
    local_site_dir="${local_site_dir:-./site}"

    if [[ ! -d "$local_site_dir" ]]; then
        error "Pasta '$local_site_dir' não encontrada!"
        return
    fi

    info "Enviando arquivos para /var/www/crom-me/..."
    sshpass -p "$VPS_PASS" scp -r $SSH_OPTS "$local_site_dir"/* "${VPS_USER}@${VPS_HOST}:/var/www/crom-me/"
    
    remote "nginx -t && systemctl reload nginx"
    success "Site atualizado e Nginx recarregado!"
    log "DEPLOY: site atualizado por=$(whoami)"
}

shell_remoto() {
    header "🖥  SHELL REMOTO"
    info "Conectando ao VPS... (digite 'exit' para sair)"
    separator
    sshpass -p "$VPS_PASS" ssh $SSH_OPTS "${VPS_USER}@${VPS_HOST}"
}

ssl_setup() {
    header "🔒 CONFIGURAR SSL"
    read -rp "  Domínio (ex: crom.me): " domain
    if [[ -z "$domain" ]]; then return; fi

    read -rp "  E-mail para Let's Encrypt: " email
    if [[ -z "$email" ]]; then
        error "E-mail obrigatório"
        return
    fi

    info "Emitindo certificado SSL para ${domain}..."
    remote "certbot --nginx -d '${domain}' --non-interactive --agree-tos -m '${email}' --redirect"
    
    if [[ $? -eq 0 ]]; then
        success "SSL configurado para ${domain}!"
    else
        error "Falha ao emitir certificado. Verifique se o DNS já aponta para este servidor."
    fi
    log "SSL: dominio=${domain} por=$(whoami)"
}
