#!/usr/bin/env bash

ensure_group() {
    remote "getent group ${MEMBERS_GROUP} >/dev/null 2>&1 || groupadd ${MEMBERS_GROUP}"
}

criar_membro() {
    header "📦 CRIAR NOVO MEMBRO"
    read -rp "  Username: " username
    if [[ -z "$username" ]]; then
        error "Username não pode ser vazio"
        return
    fi

    # Verificar se já existe
    if remote "id '$username'" &>/dev/null; then
        error "Usuário '$username' já existe!"
        return
    fi

    read -rp "  Nome completo (opcional): " fullname
    read -rp "  E-mail (opcional): " email
    read -rp "  Cargo (default: Membro): " cargo
    cargo="${cargo:-Membro}"
    read -rsp "  Senha: " password
    echo
    read -rsp "  Confirmar senha: " password2
    echo

    if [[ "$password" != "$password2" ]]; then
        error "Senhas não coincidem!"
        return
    fi

    if [[ ${#password} -lt 8 ]]; then
        error "Senha deve ter no mínimo 8 caracteres"
        return
    fi

    read -rp "  Permitir acesso SSH? (s/N): " allow_ssh
    
    ensure_group

    local shell="/bin/bash"
    if [[ "${allow_ssh,,}" != "s" ]]; then
        shell="/usr/sbin/nologin"
    fi

    local comment="${fullname:-Membro CROM}"

    remote "useradd -m -g ${MEMBERS_GROUP} -s '${shell}' -c '${comment}' '${username}' && echo '${username}:${password}' | chpasswd"
    
    if [[ $? -eq 0 ]]; then
        success "Membro '${username}' criado com sucesso!"
        info "Home: ${MEMBERS_HOME_BASE}/${username}"
        info "Shell: ${shell}"
        info "Grupo: ${MEMBERS_GROUP}"

        # Ativar linger para que serviços do usuário (Podman Quadlets)
        # sobrevivam a reboots e logouts
        remote "loginctl enable-linger '${username}' 2>/dev/null || true"
        info "Linger ativado (serviços persistem no boot)"

        log "CRIAR: usuario=${username} ssh=${allow_ssh} linger=enabled por=$(whoami)"

        # Gerar .md com instruções de acesso
        local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
        local md_dir="${script_dir}/membros/credenciais"
        mkdir -p "$md_dir"
        local md_file="${md_dir}/${username}-acesso.md"
        local data_hoje=$(date '+%d/%m/%Y')
        local nome="${fullname:-$username}"

        cat > "$md_file" <<MDEOF
# 🔐 Credenciais de Acesso — CROM

**Membro**: ${nome}
**Username**: \`${username}\`
**E-mail**: ${email:-N/A}
**Cargo**: ${cargo}
**Data de criação**: ${data_hoje}

---

## Como acessar o servidor

Abra seu terminal e execute:

\`\`\`bash
ssh ${username}@crom.me
\`\`\`

Quando pedir a senha, digite:

\`\`\`
${password}
\`\`\`

> ⚠️ **Altere sua senha no primeiro acesso** com o comando: \`passwd\`

---

## Ferramenta de projetos (crom-ws)

Após conectar, você tem acesso ao \`crom-ws\` para gerenciar seus projetos:

\`\`\`bash
# Ver ajuda
crom-ws help

# Criar um projeto
crom-ws init meu-projeto

# Listar seus projetos
crom-ws list

# Ver detalhes de um projeto
crom-ws info meu-projeto

# Ver status do seu workspace
crom-ws status
\`\`\`

Seus projetos ficam em: \`~/projetos/\`

---

## Regras de uso

- **Não compartilhe** suas credenciais
- **Não acesse** diretórios de outros membros
- **Não instale serviços** em portas públicas sem autorização
- **Não use** o servidor para atividades ilegais
- Todos os comandos são **registrados e auditados**

---

## Ecossistema CROM

| Recurso | Link |
|---------|------|
| Portal Principal | [crom.run](https://crom.run) |
| Comunidade | [crom.run/comunidade](https://crom.run/comunidade) |
| GitHub | [github.com/MrJc01](https://github.com/MrJc01) |
| Discord | [discord.gg/4b5wqdxreZ](https://discord.gg/4b5wqdxreZ) |

---

> *Documento gerado automaticamente em ${data_hoje} — CROM Collective*
> *Credenciais pessoais e intransferíveis*
MDEOF

        success "Documento de acesso gerado: ${md_file}"

        # Registrar no CSV
        local csv="${script_dir}/membros/lista-membros.csv"
        if [[ -f "$csv" ]]; then
            echo "${username},${nome},${email:-},${cargo},$(date +%Y-%m-%d),ativo,***" >> "$csv"
            info "Membro registrado no CSV"
        fi
    else
        error "Falha ao criar membro"
    fi
}

banir_membro() {
    header "🚫 BANIR MEMBRO"
    listar_membros_simples
    separator
    read -rp "  Username para banir: " username
    if [[ -z "$username" ]]; then return; fi

    # Verificar se existe
    if ! remote "id '$username'" &>/dev/null; then
        error "Usuário '$username' não encontrado!"
        return
    fi

    read -rp "  Motivo do ban (opcional): " motivo
    read -rp "  ${YELLOW}Confirmar ban de '${username}'? (s/N):${NC} " confirm
    
    if [[ "${confirm,,}" != "s" ]]; then
        info "Operação cancelada"
        return
    fi

    # Bloquear conta, matar sessões, desabilitar shell
    remote "
        usermod -L '${username}' 2>/dev/null
        usermod -s /usr/sbin/nologin '${username}' 2>/dev/null
        pkill -u '${username}' 2>/dev/null || true
        echo '# BANIDO em $(date -u +%Y-%m-%dT%H:%M:%SZ) | Motivo: ${motivo:-Não especificado}' >> /home/${username}/.ban_info
    "

    success "Membro '${username}' foi BANIDO"
    info "Conta bloqueada, sessões encerradas, shell desabilitado"
    log "BANIR: usuario=${username} motivo='${motivo:-N/A}' por=$(whoami)"
}

restaurar_membro() {
    header "🔓 RESTAURAR MEMBRO BANIDO"
    
    # Listar banidos
    echo -e "  ${DIM}Membros banidos:${NC}"
    remote "
        for u in \$(getent group ${MEMBERS_GROUP} 2>/dev/null | cut -d: -f4 | tr ',' '\n'); do
            status=\$(passwd -S \"\$u\" 2>/dev/null | awk '{print \$2}')
            if [[ \"\$status\" == 'L' ]]; then
                echo \"    ⛔ \$u\"
            fi
        done
    " 2>/dev/null || echo "  Nenhum membro banido encontrado"
    
    separator
    read -rp "  Username para restaurar: " username
    if [[ -z "$username" ]]; then return; fi

    remote "
        usermod -U '${username}' 2>/dev/null
        usermod -s /bin/bash '${username}' 2>/dev/null
        rm -f /home/${username}/.ban_info
    "

    success "Membro '${username}' restaurado!"
    log "RESTAURAR: usuario=${username} por=$(whoami)"
}

mudar_senha() {
    header "🔑 ALTERAR SENHA DE MEMBRO"
    listar_membros_simples
    separator
    read -rp "  Username: " username
    if [[ -z "$username" ]]; then return; fi

    if ! remote "id '$username'" &>/dev/null; then
        error "Usuário '$username' não encontrado!"
        return
    fi

    read -rsp "  Nova senha: " password
    echo
    read -rsp "  Confirmar nova senha: " password2
    echo

    if [[ "$password" != "$password2" ]]; then
        error "Senhas não coincidem!"
        return
    fi

    if [[ ${#password} -lt 8 ]]; then
        error "Senha deve ter no mínimo 8 caracteres"
        return
    fi

    remote "echo '${username}:${password}' | chpasswd"
    success "Senha de '${username}' alterada com sucesso!"
    log "SENHA: usuario=${username} alterada por=$(whoami)"
}

deletar_membro() {
    header "💀 DELETAR MEMBRO (PERMANENTE)"
    listar_membros_simples
    separator
    read -rp "  Username para DELETAR: " username
    if [[ -z "$username" ]]; then return; fi

    if [[ "$username" == "root" ]]; then
        error "Não é possível deletar root!"
        return
    fi

    if ! remote "id '$username'" &>/dev/null; then
        error "Usuário '$username' não encontrado!"
        return
    fi

    echo -e "  ${RED}${BOLD}⚠ ATENÇÃO: Isso irá DELETAR o usuário e TODOS os arquivos!${NC}"
    read -rp "  Digite '${username}' para confirmar: " confirm

    if [[ "$confirm" != "$username" ]]; then
        info "Operação cancelada"
        return
    fi

    remote "pkill -u '${username}' 2>/dev/null || true; userdel -r '${username}' 2>/dev/null"
    success "Membro '${username}' deletado permanentemente!"
    log "DELETAR: usuario=${username} por=$(whoami)"
}

listar_membros_simples() {
    remote "
        echo ''
        members=\$(getent group ${MEMBERS_GROUP} 2>/dev/null | cut -d: -f4 | tr ',' '\n')
        if [[ -z \"\$members\" ]]; then
            # Fallback: listar users do grupo por ID
            for u in \$(awk -F: -v gid=\$(getent group ${MEMBERS_GROUP} 2>/dev/null | cut -d: -f3) '\$4==gid {print \$1}' /etc/passwd 2>/dev/null); do
                echo \"    • \$u\"
            done
        else
            for u in \$members; do
                echo \"    • \$u\"
            done
        fi
        # Also check primary group members
        gid=\$(getent group ${MEMBERS_GROUP} 2>/dev/null | cut -d: -f3)
        if [[ -n \"\$gid\" ]]; then
            awk -F: -v gid=\"\$gid\" '\$4==gid {print \"    • \" \$1}' /etc/passwd
        fi
    " 2>/dev/null | sort -u
}

listar_membros() {
    header "👥 MEMBROS CADASTRADOS"
    
    remote "
        gid=\$(getent group ${MEMBERS_GROUP} 2>/dev/null | cut -d: -f3)
        if [[ -z \"\$gid\" ]]; then
            echo '  Grupo ${MEMBERS_GROUP} não existe ainda.'
            exit 0
        fi

        printf '  %-18s %-8s %-20s %-22s\n' 'USUARIO' 'STATUS' 'SHELL' 'ULTIMO LOGIN'
        echo '  ──────────────────────────────────────────────────────────────────────'

        awk -F: -v gid=\"\$gid\" '\$4==gid {print \$1 \"|\" \$7 \"|\" \$5}' /etc/passwd | while IFS='|' read -r user shell comment; do
            status=\$(passwd -S \"\$user\" 2>/dev/null | awk '{print \$2}')
            if [[ \"\$status\" == 'L' ]]; then
                st='⛔ BAN'
            elif [[ \"\$status\" == 'P' ]]; then
                st='✅ ATIVO'
            else
                st='❓ \$status'
            fi

            last_login=\$(lastlog -u \"\$user\" 2>/dev/null | tail -1 | awk '{\$1=\"\"; print}' | sed 's/^ //' | head -c 20)
            if echo \"\$last_login\" | grep -q 'Never'; then
                last_login='Nunca logou'
            fi

            printf '  %-18s %-8s %-20s %-22s\n' \"\$user\" \"\$st\" \"\$shell\" \"\$last_login\"
        done
    " 2>/dev/null
    echo
}
