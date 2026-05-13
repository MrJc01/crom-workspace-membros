#!/usr/bin/env bash
# CROM — Verificação Pós-Deploy Dokploy
set -euo pipefail

echo "═══ CROM — Verificação Pós-Deploy ═══"
PASS=0; FAIL=0

check() {
    if eval "$2" &>/dev/null; then echo "  ✅ $1"; ((PASS++))
    else echo "  ❌ $1"; ((FAIL++)); fi
}

echo "[Docker]"
check "Dokploy rodando" "docker ps | grep -q dokploy"
check "Traefik rodando" "docker ps | grep -q traefik"
check "crom-me container" "docker ps | grep -q crom-me-static"

echo "[Rede]"
check "Porta 3000 (painel)" "ss -tlnp | grep -q ':3000'"
check "Porta 80 (Traefik)" "ss -tlnp | grep -q ':80'"
check "Porta 443 (Traefik)" "ss -tlnp | grep -q ':443'"
check "CromIA API porta 8085" "ss -tlnp | grep -q ':8085'"

echo "[HTTP]"
check "crom.me responde" "curl -sfo /dev/null -w '%{http_code}' http://crom.me | grep -qE '(200|301|302)'"
check "cromia-api responde" "curl -sfo /dev/null -w '%{http_code}' http://cromia-api.crom.me | grep -qE '(200|301|302|401)'"
check "Painel Dokploy" "curl -sfo /dev/null -w '%{http_code}' http://localhost:3000 | grep -qE '(200|301|302)'"

echo "[Nginx desativado]"
check "Nginx não rodando" "! systemctl is-active --quiet nginx"

echo ""
echo "═══ Resultado: ${PASS} OK / ${FAIL} FALHAS ═══"
[ "$FAIL" -eq 0 ] && echo "🎉 Deploy validado!" || echo "⚠️ Corrija as falhas acima."
