#!/usr/bin/env bash
# Verifica se o DNS do crom.me já propagou para o novo IP
# Uso: bash check-dns.sh

TARGET_IP="76.13.165.69"
DOMAIN="crom.me"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "\n  ${CYAN}🔍 Verificando propagação DNS de ${DOMAIN}${NC}\n"
echo -e "  IP esperado: ${GREEN}${TARGET_IP}${NC}\n"

check_dns() {
    local label="$1"
    local server="$2"
    local result

    if [[ -n "$server" ]]; then
        result=$(dig +short "$DOMAIN" A "@$server" 2>/dev/null | head -1)
    else
        result=$(dig +short "$DOMAIN" A 2>/dev/null | head -1)
    fi

    if [[ "$result" == "$TARGET_IP" ]]; then
        printf "  ${GREEN}✓${NC} %-25s → ${GREEN}%s${NC}\n" "$label" "$result"
        return 0
    elif [[ -z "$result" ]]; then
        printf "  ${YELLOW}?${NC} %-25s → ${YELLOW}sem resposta${NC}\n" "$label"
        return 1
    else
        printf "  ${RED}✗${NC} %-25s → ${RED}%s${NC} (antigo)\n" "$label" "$result"
        return 1
    fi
}

ok=0
total=5

check_dns "DNS Local" "" && ((ok++))
check_dns "Google DNS (8.8.8.8)" "8.8.8.8" && ((ok++))
check_dns "Google DNS (8.8.4.4)" "8.8.4.4" && ((ok++))
check_dns "Cloudflare (1.1.1.1)" "1.1.1.1" && ((ok++))
check_dns "OpenDNS (208.67.222.222)" "208.67.222.222" && ((ok++))

echo ""
echo -e "  ─────────────────────────────────────"

if [[ $ok -eq $total ]]; then
    echo -e "  ${GREEN}✅ DNS 100% propagado! Pronto para emitir SSL.${NC}"
    echo -e "  Execute: ${CYAN}./crom-manager.sh ssl${NC}"
else
    echo -e "  ${YELLOW}⏳ Propagação: ${ok}/${total} — aguarde e tente novamente.${NC}"
fi
echo ""
