#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════
# CROM — Backup Pré-Instalação Dokploy
# Executa na VPS dos Guardiões ANTES de qualquer mudança
# ═══════════════════════════════════════════════════════════════
set -euo pipefail

BACKUP_DIR="/root/backup-pre-dokploy-$(date +%F-%H%M)"
LOG_FILE="${BACKUP_DIR}/backup.log"

echo "═══ CROM — Backup Pré-Dokploy ═══"
echo "📁 Diretório: ${BACKUP_DIR}"

mkdir -p "${BACKUP_DIR}"

# ── 1. Auditoria do estado atual ─────────────────────────────
echo "[1/5] Capturando estado atual..."
{
    echo "=== PORTAS EM USO ==="
    ss -tlnp
    echo ""
    echo "=== CONTAINERS DOCKER ==="
    docker ps -a 2>/dev/null || echo "Docker não instalado"
    echo ""
    echo "=== PROCESSOS RELEVANTES ==="
    ps aux | grep -E '(nginx|traefik|cromia|node|docker)' | grep -v grep
    echo ""
    echo "=== FIREWALL ==="
    ufw status verbose 2>/dev/null || echo "UFW não configurado"
    echo ""
    echo "=== DISCO ==="
    df -h
    echo ""
    echo "=== MEMÓRIA ==="
    free -h
} > "${BACKUP_DIR}/estado-pre-install.txt" 2>&1

# ── 2. Backup do Nginx ───────────────────────────────────────
echo "[2/5] Backup do Nginx..."
if [ -d /etc/nginx ]; then
    tar czf "${BACKUP_DIR}/nginx-config.tar.gz" /etc/nginx/ 2>/dev/null
    echo "  ✅ /etc/nginx/ salvo"
else
    echo "  ⚠️ /etc/nginx/ não encontrado"
fi

# ── 3. Backup dos sites ──────────────────────────────────────
echo "[3/5] Backup dos sites em /var/www/..."
if [ -d /var/www ]; then
    tar czf "${BACKUP_DIR}/var-www.tar.gz" /var/www/ 2>/dev/null
    echo "  ✅ /var/www/ salvo"
else
    echo "  ⚠️ /var/www/ não encontrado"
fi

# ── 4. Backup do Systemd services ────────────────────────────
echo "[4/5] Backup dos serviços Systemd..."
mkdir -p "${BACKUP_DIR}/systemd"
for svc in cromia-api crom-me; do
    if [ -f "/etc/systemd/system/${svc}.service" ]; then
        cp "/etc/systemd/system/${svc}.service" "${BACKUP_DIR}/systemd/"
        echo "  ✅ ${svc}.service salvo"
    fi
done

# ── 5. Backup de SSL/Certbot ─────────────────────────────────
echo "[5/5] Backup de certificados SSL..."
if [ -d /etc/letsencrypt ]; then
    tar czf "${BACKUP_DIR}/letsencrypt.tar.gz" /etc/letsencrypt/ 2>/dev/null
    echo "  ✅ /etc/letsencrypt/ salvo"
else
    echo "  ⚠️ Let's Encrypt não encontrado"
fi

echo ""
echo "═══════════════════════════════════"
echo "✅ Backup completo em: ${BACKUP_DIR}"
echo "📋 Estado capturado em: ${BACKUP_DIR}/estado-pre-install.txt"
echo "═══════════════════════════════════"
ls -lah "${BACKUP_DIR}/"
