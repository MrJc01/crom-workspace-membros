#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════
# CROM — Backup Automático do Dokploy (Postgres)
# Configura cron de backup diário do banco interno
# ═══════════════════════════════════════════════════════════════
set -euo pipefail

BACKUP_DIR="/var/backups/dokploy"
RETENTION_DAYS=14

echo "═══ CROM — Setup Backup Dokploy ═══"

# ── 1. Criar diretório de backups ─────────────────────────────
mkdir -p "${BACKUP_DIR}"
echo "✅ Diretório: ${BACKUP_DIR}"

# ── 2. Criar script de backup ────────────────────────────────
cat > /opt/crom/dokploy/backup-postgres.sh << 'BACKUP_EOF'
#!/usr/bin/env bash
# Backup automático do Postgres interno do Dokploy
set -euo pipefail

BACKUP_DIR="/var/backups/dokploy"
TIMESTAMP=$(date +%F-%H%M)
BACKUP_FILE="${BACKUP_DIR}/dokploy-db-${TIMESTAMP}.sql.gz"
RETENTION_DAYS=14

# Identificar container do Postgres do Dokploy
PG_CONTAINER=$(docker ps --filter "name=postgres" --filter "ancestor=postgres" --format "{{.Names}}" | grep -i dokploy | head -1)

if [ -z "${PG_CONTAINER}" ]; then
    # Fallback: procurar qualquer postgres associado ao Dokploy
    PG_CONTAINER=$(docker ps --format "{{.Names}}" | grep -iE 'dokploy.*postgres|postgres.*dokploy' | head -1)
fi

if [ -z "${PG_CONTAINER}" ]; then
    echo "[$(date)] ERRO: Container Postgres do Dokploy não encontrado" >> /var/log/dokploy/backup.log
    exit 1
fi

# Executar pg_dump
docker exec "${PG_CONTAINER}" pg_dumpall -U postgres 2>/dev/null | gzip > "${BACKUP_FILE}"

# Verificar se o backup foi criado com sucesso
if [ -s "${BACKUP_FILE}" ]; then
    SIZE=$(du -h "${BACKUP_FILE}" | cut -f1)
    echo "[$(date)] OK: Backup criado ${BACKUP_FILE} (${SIZE})" >> /var/log/dokploy/backup.log
else
    echo "[$(date)] ERRO: Backup vazio ou falhou" >> /var/log/dokploy/backup.log
    rm -f "${BACKUP_FILE}"
    exit 1
fi

# Limpar backups antigos
find "${BACKUP_DIR}" -name "dokploy-db-*.sql.gz" -mtime +${RETENTION_DAYS} -delete
echo "[$(date)] Limpeza: removidos backups com mais de ${RETENTION_DAYS} dias" >> /var/log/dokploy/backup.log
BACKUP_EOF

chmod +x /opt/crom/dokploy/backup-postgres.sh
echo "✅ Script de backup criado"

# ── 3. Configurar Cron ───────────────────────────────────────
CRON_ENTRY="0 3 * * * /opt/crom/dokploy/backup-postgres.sh"

# Verificar se já existe
if crontab -l 2>/dev/null | grep -qF "backup-postgres.sh"; then
    echo "⚠️ Cron já configurado"
else
    (crontab -l 2>/dev/null; echo "${CRON_ENTRY}") | crontab -
    echo "✅ Cron configurado: backup diário às 03:00"
fi

# ── 4. Executar primeiro backup ──────────────────────────────
echo "📦 Executando primeiro backup..."
/opt/crom/dokploy/backup-postgres.sh && echo "✅ Primeiro backup concluído" || echo "⚠️ Primeiro backup falhou (Dokploy pode ainda não ter Postgres rodando)"

echo ""
echo "═══════════════════════════════════"
echo "📋 Backup configurado:"
echo "  • Frequência: Diário às 03:00"
echo "  • Retenção: ${RETENTION_DAYS} dias"
echo "  • Local: ${BACKUP_DIR}/"
echo "  • Log: /var/log/dokploy/backup.log"
echo "═══════════════════════════════════"
