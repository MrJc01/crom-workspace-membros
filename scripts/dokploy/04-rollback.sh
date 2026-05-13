#!/usr/bin/env bash
# CROM — Rollback da Instalação Dokploy
set -euo pipefail

echo "═══ CROM — Rollback Dokploy ═══"
read -rp "Reverter instalação do Dokploy? (s/N) " CONFIRM
[[ "${CONFIRM}" != "s" && "${CONFIRM}" != "S" ]] && echo "Abortado." && exit 0

echo "[1/4] Parando containers..."
[ -f /opt/crom/dokploy/docker-compose-crom-me.yml ] && docker compose -f /opt/crom/dokploy/docker-compose-crom-me.yml down 2>/dev/null || true
for c in dokploy $(docker ps --filter "name=traefik" -q) $(docker ps --format "{{.Names}}" | grep -i 'dokploy.*postgres' | head -1); do
    docker stop "$c" 2>/dev/null; docker rm "$c" 2>/dev/null
done || true

echo "[2/4] Restaurando Nginx..."
LATEST=$(ls -td /root/backup-pre-dokploy-* 2>/dev/null | head -1)
[ -n "$LATEST" ] && [ -f "$LATEST/nginx-config.tar.gz" ] && tar xzf "$LATEST/nginx-config.tar.gz" -C /
systemctl enable --now nginx 2>/dev/null || true

echo "[3/4] Restaurando Certbot..."
systemctl enable --now certbot.timer 2>/dev/null || true

echo "[4/4] Limpando..."
rm -rf /opt/crom/dokploy/traefik-dynamic 2>/dev/null || true
crontab -l 2>/dev/null | grep -vF "backup-postgres.sh" | crontab - 2>/dev/null || true

echo "✅ Rollback concluído. Verifique: curl -sI https://crom.me"
