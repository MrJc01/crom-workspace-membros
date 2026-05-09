#!/usr/bin/env bash

# ╔══════════════════════════════════════════════════════════════╗
# ║  CROM Reports Module — 15 Relatórios Multi-VPS              ║
# ║  Gera .md detalhados em relatorios/<timestamp>/              ║
# ╚══════════════════════════════════════════════════════════════╝

# ===== VARIÁVEIS DO MÓDULO =====
declare -a _VPS_IDS=()
declare -A _RAW=()
declare -A _VPS_NAMES=()
declare -A _VPS_IPS=()
_REPORT_DIR=""
_REPORT_TS=""

# ===== INFRAESTRUTURA =====

_discover_vps_ids() {
    _VPS_IDS=()
    local i=0
    while true; do
        local var="VPS${i}_HOST"
        if [[ -n "${!var:-}" ]]; then
            _VPS_IDS+=("$i")
            local nvar="VPS${i}_NAME"
            _VPS_NAMES[$i]="${!nvar:-vps${i}}"
            _VPS_IPS[$i]="${!var}"
        else
            break
        fi
        ((i++))
    done
}

_report_init() {
    _REPORT_TS="$(date '+%Y-%m-%d_%Hh%M')"
    _REPORT_DIR="${SCRIPT_DIR}/relatorios/${_REPORT_TS}"
    mkdir -p "$_REPORT_DIR"
    # Atualizar symlink
    ln -sfn "$_REPORT_DIR" "${SCRIPT_DIR}/relatorios/ultimo"
}

_collect_vps_data() {
    local id="$1"
    local host_var="VPS${id}_HOST"
    local user_var="VPS${id}_USER"
    local pass_var="VPS${id}_PASS"
    local h="${!host_var}" u="${!user_var}" p="${!pass_var}"

    [[ -z "$h" ]] && return 1

    _RAW[$id]=$(timeout 90 sshpass -p "$p" ssh -n -o ServerAliveInterval=15 $SSH_OPTS "${u}@${h}" '
echo "===HOSTNAME==="
hostname
echo "===UPTIME==="
uptime
echo "===UPTIME_P==="
uptime -p 2>/dev/null || uptime
echo "===OS==="
cat /etc/os-release 2>/dev/null | grep PRETTY | cut -d\" -f2
echo "===KERNEL==="
uname -r
echo "===CPU_CORES==="
nproc
echo "===RAM==="
free -h | awk "/Mem:/{print \$2, \$3, \$4, \$7}"
echo "===SWAP==="
free -h | awk "/Swap:/{print \$2, \$3}"
echo "===DISK==="
df -h / | awk "NR==2{print \$2, \$3, \$4, \$5}"
echo "===DISK_INODES==="
df -i / | awk "NR==2{print \$2, \$3, \$5}"
echo "===LOAD==="
cat /proc/loadavg
echo "===NGINX_SITES==="
ls -1 /etc/nginx/sites-enabled/ 2>/dev/null || echo "NONE"
echo "===NGINX_DOMAINS==="
cat /etc/nginx/sites-enabled/* 2>/dev/null | grep "server_name" | sed "s/server_name//;s/;//;s/^[[:space:]]*//" | sed "s/ /\n/g" | grep -v "^$" | sort -u || echo "NONE"
echo "===NGINX_UPSTREAMS==="
cat /etc/nginx/sites-enabled/* 2>/dev/null | grep "proxy_pass" | sed "s/proxy_pass//;s/;//;s/^[[:space:]]*//" | sort -u || echo "NONE"
echo "===PORTS==="
ss -tlnp 2>/dev/null | tail -n +2
echo "===PORTS_UDP==="
ss -ulnp 2>/dev/null | tail -n +2
echo "===CONNECTIONS==="
ss -tun 2>/dev/null | tail -n +2 | wc -l
echo "===CONTAINERS_ROOT==="
podman ps -a --format "{{.Names}}|{{.Status}}|{{.Ports}}|{{.Image}}" 2>/dev/null || echo "NONE"
echo "===SERVICES_RUNNING==="
systemctl list-units --type=service --state=running --no-pager --plain 2>/dev/null | grep -v "^$"
echo "===SERVICES_FAILED==="
systemctl --failed --no-pager --plain 2>/dev/null | grep -v "^$" | head -20
echo "===TIMERS==="
systemctl list-timers --no-pager --plain 2>/dev/null | head -20
echo "===SSL==="
certbot certificates 2>/dev/null || echo "NONE"
echo "===UFW==="
ufw status verbose 2>/dev/null || echo "NONE"
echo "===FAIL2BAN==="
fail2ban-client status 2>/dev/null || echo "NONE"
echo "===FAILED_SSH==="
journalctl -u sshd --since "24 hours ago" --no-pager 2>/dev/null | grep -c "Failed password" || echo "0"
echo "===FAILED_SSH_IPS==="
journalctl -u sshd --since "24 hours ago" --no-pager 2>/dev/null | grep "Failed password" | grep -oP "from \K[0-9.]+" | sort | uniq -c | sort -rn | head -5 || echo "NONE"
echo "===SSHD_CONFIG==="
grep -E "^(PermitRoot|PasswordAuth|Port )" /etc/ssh/sshd_config 2>/dev/null || echo "NONE"
echo "===SUDOERS==="
getent group sudo 2>/dev/null | cut -d: -f4
echo "===MEMBERS==="
gid=$(getent group crom-membros 2>/dev/null | cut -d: -f3)
if [[ -n "$gid" ]]; then
    awk -F: -v gid="$gid" "\$4==gid {print \$1\"|\"\$7}" /etc/passwd
else
    echo "NONE"
fi
echo "===MEMBERS_STATUS==="
gid=$(getent group crom-membros 2>/dev/null | cut -d: -f3)
if [[ -n "$gid" ]]; then
    for u in $(awk -F: -v gid="$gid" "\$4==gid {print \$1}" /etc/passwd); do
        st=$(passwd -S "$u" 2>/dev/null | awk "{print \$2}")
        ll=$(lastlog -u "$u" 2>/dev/null | tail -1 | awk "NR==1{\$1=\"\"; print}" | sed "s/^ //" | head -c 30)
        linger=$(loginctl show-user "$u" 2>/dev/null | grep Linger | cut -d= -f2)
        du_size=$(du -sh "/home/$u" 2>/dev/null | awk "{print \$1}")
        echo "${u}|${st}|${ll}|${linger:-no}|${du_size:-0}"
    done
else
    echo "NONE"
fi
echo "===HOME_USAGE==="
du -sh /home/*/ 2>/dev/null || echo "NONE"
echo "===WWW_USAGE==="
du -sh /var/www/*/ 2>/dev/null || echo "NONE"
echo "===LOG_USAGE==="
du -sh /var/log 2>/dev/null || echo "NONE"
echo "===BIG_FILES==="
timeout 10 find / -xdev -type f -size +50M -printf "%s %p\n" 2>/dev/null | sort -rn | head -10 || echo "NONE"
echo "===TOP_CPU==="
ps aux --sort=-%cpu 2>/dev/null | head -11
echo "===TOP_MEM==="
ps aux --sort=-%mem 2>/dev/null | head -11
echo "===VMSTAT==="
vmstat 2>/dev/null | tail -1
echo "===UPDATES==="
timeout 10 apt list --upgradable 2>/dev/null | tail -n +2 | wc -l
echo "===UPDATES_SEC==="
timeout 10 apt list --upgradable 2>/dev/null | grep -i security | wc -l
echo "===NEEDRESTART==="
needrestart -b 2>/dev/null | head -5 || echo "NONE"
echo "===CRONTAB_ROOT==="
crontab -l 2>/dev/null || echo "NONE"
echo "===CRON_MEMBERS==="
gid=$(getent group crom-membros 2>/dev/null | cut -d: -f3)
if [[ -n "$gid" ]]; then
    for u in $(awk -F: -v gid="$gid" "\$4==gid {print \$1}" /etc/passwd); do
        ct=$(crontab -u "$u" -l 2>/dev/null)
        if [[ -n "$ct" && "$ct" != "no crontab for $u" ]]; then
            echo "USER=$u"
            echo "$ct"
        fi
    done
fi
echo "===CRON_SYSTEM==="
ls /etc/cron.d/ 2>/dev/null || echo "NONE"
echo "===USER_CONTAINERS==="
gid=$(getent group crom-membros 2>/dev/null | cut -d: -f3)
if [[ -n "$gid" ]]; then
    for u in $(awk -F: -v gid="$gid" "\$4==gid {print \$1}" /etc/passwd); do
        pods=$(timeout 5 su - "$u" -c "podman ps -a --format \"{{.Names}}|{{.Status}}|{{.Ports}}|{{.Image}}\"" 2>/dev/null)
        if [[ -n "$pods" ]]; then
            echo "USER=$u"
            echo "$pods"
        fi
        quads=$(ls "/home/$u/.config/containers/systemd/" 2>/dev/null)
        if [[ -n "$quads" ]]; then
            echo "QUADLETS=$u"
            echo "$quads"
        fi
    done
fi
echo "===USER_PROJECTS==="
for d in /home/*/projetos/*/; do
    [[ -d "$d" ]] || continue
    user=$(echo "$d" | cut -d/ -f3)
    proj=$(basename "$d")
    type="unknown"
    [[ -f "$d/package.json" ]] && type="node"
    [[ -f "$d/requirements.txt" ]] && type="python"
    [[ -f "$d/go.mod" ]] && type="go"
    [[ -f "$d/Cargo.toml" ]] && type="rust"
    [[ -f "$d/Containerfile" || -f "$d/Dockerfile" ]] && type="${type}+container"
    echo "${user}|${proj}|${type}"
done
echo "===NGINX_ERRORS==="
tail -10 /var/log/nginx/error.log 2>/dev/null || echo "NONE"
echo "===END==="
' 2>/dev/null)
}

_collect_all() {
    _discover_vps_ids
    for id in "${_VPS_IDS[@]}"; do
        info "🔍 Escaneando VPS ${id} (${_VPS_NAMES[$id]})..."
        if _collect_vps_data "$id"; then
            echo -e "  ${GREEN}✓${NC} ${_VPS_NAMES[$id]} (${_VPS_IPS[$id]})"
        else
            echo -e "  ${RED}✗${NC} ${_VPS_NAMES[$id]} — falha na conexão"
        fi
    done
}

_parse() {
    local id="$1" section="$2"
    echo "${_RAW[$id]}" | awk -v s="===${section}===" -v e="===" '
        $0 == s { found=1; next }
        found && /^===/ { exit }
        found { print }
    '
}

_md_header() {
    local file="$1" title="$2"
    cat > "$file" <<EOF
# ${title}

**Gerado em:** $(date '+%d/%m/%Y às %H:%M:%S') (BRT)
**Orquestrador:** CROM v3.0.0
**VPS escaneadas:** ${#_VPS_IDS[@]}

---

EOF
}

_http_check() {
    local url="$1"
    curl -s -o /dev/null -w "%{http_code}" --connect-timeout 8 --max-time 12 "$url" 2>/dev/null
}
