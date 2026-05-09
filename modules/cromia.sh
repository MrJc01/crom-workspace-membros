#!/usr/bin/env bash

criar_conta_cromia() {
    header "🤖 CRIAR CONTA NO CROMIA"
    listar_membros_simples
    separator
    
    read -rp "  Username do membro (ex: pedrodev): " username
    if [[ -z "$username" ]]; then return; fi

    read -rsp "  Senha para o Dashboard (Enter para padrão 'Cromia@2026!'): " pass
    echo
    local password="${pass:-Cromia@2026!}"

    info "Criando usuário no CromIA..."
    if remote "cd /var/www/cromia-api && ./cromia users create --username ${username} --password '${password}'"; then
        success "Conta criada com sucesso no banco de dados!"
    else
        error "Falha ao criar conta. Talvez o usuário já exista?"
    fi
}

listar_contas_cromia() {
    header "📋 LISTAR CONTAS CROMIA"
    info "Buscando dados no banco de faturamento..."
    echo -e "  ────────────────────────────────────────────────────────"
    remote "cd /var/www/cromia-api && ./cromia users list"
    echo -e "  ────────────────────────────────────────────────────────"
}

injetar_creditos_cromia() {
    header "💰 INJETAR CRÉDITOS NO CROMIA"
    listar_membros_simples
    separator
    
    read -rp "  Username para adicionar fundos: " username
    if [[ -z "$username" ]]; then return; fi

    info "A conversão base é 100 créditos = \$1.00 USD."
    read -rp "  Valor em CRÉDITOS a injetar (ex: 150): " creditos
    if [[ -z "$creditos" ]]; then return; fi

    info "Adicionando ${creditos} créditos..."
    if remote "cd /var/www/cromia-api && ./cromia users add-credits --user ${username} --amount ${creditos}"; then
        success "Créditos injetados com sucesso!"
    else
        error "Falha ao injetar créditos."
    fi
}

gerar_key_cromia() {
    header "🔑 GERAR / EXPORTAR API KEY"
    listar_membros_simples
    separator
    
    read -rp "  Username do membro: " username
    if [[ -z "$username" ]]; then return; fi

    info "Gerando chave de API..."
    local raw_output=$(remote "cd /var/www/cromia-api && ./cromia keys generate --user ${username} --name 'Acesso_CROM_WS'")
    
    # Extrair a chave crom_sk_...
    local api_key=$(echo "$raw_output" | grep -oE 'crom_sk_[a-zA-Z0-9_-]+' | head -n 1)

    if [[ -z "$api_key" ]]; then
        error "Não foi possível capturar a API Key. Verifique se o CromIA está rodando."
        return
    fi

    success "API Key gerada e capturada: ${api_key}"

    # Salvar localmente no cofre de credenciais
    local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
    local md_dir="${script_dir}/app-cromia/credenciais"
    mkdir -p "$md_dir"
    local md_file="${md_dir}/${username}-cromia.md"

    cat > "$md_file" <<MDEOF
# 🤖 Suas Credenciais de IA (CromIA)

Olá **${username}**! Sua API Key do gateway de IA do CROM foi gerada/atualizada.

**Acesso ao Dashboard (Ver Saldo Histórico):**
- URL: https://cromia-api.crom.me
- Usuário: \`${username}\`

**Sua API Key (Para injetar no seu código):**
\`\`\`
${api_key}
\`\`\`

*(URL Base para o SDK da OpenAI: \`https://cromia-api.crom.me/v1\`)*
MDEOF

    success "Credenciais formatadas salvas localmente em: ${md_file}"

    # Opção avançada: Entregar diretamente via GitOps local-first na VPS
    read -rp "  Deseja injetar esse arquivo diretamente na Home do usuário na VPS? (s/N): " push_vps
    if [[ "${push_vps,,}" == "s" ]]; then
        info "Enviando arquivo para a VPS via SCP..."
        sshpass -p "$VPS_PASS" scp -o StrictHostKeyChecking=no "$md_file" "${VPS_USER}@${VPS_HOST}:/home/${username}/.cromia-acesso.md"
        remote "chown ${username}:${MEMBERS_GROUP} /home/${username}/.cromia-acesso.md && chmod 600 /home/${username}/.cromia-acesso.md"
        success "Arquivo entregue com segurança em /home/${username}/.cromia-acesso.md na VPS!"
    fi
}
