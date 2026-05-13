#!/usr/bin/env bash
# ═══════════════════════════════════════════════════════════════
# CROM — Instalação do Dokploy + Migração de Serviços
# Executa na VPS dos Guardiões APÓS o backup (01-backup)
# ═══════════════════════════════════════════════════════════════
set -euo pipefail

CROM_DOMAIN="crom.me"
DOKPLOY_DOMAIN="dokploy.${CROM_DOMAIN}"
CROMIA_PORT=8085

echo "═══ CROM — Instalação Dokploy ═══"
echo "🌐 Domínio principal: ${CROM_DOMAIN}"
echo "🖥️ Painel: ${DOKPLOY_DOMAIN}"
echo ""

# ── 0. Pré-Checks ────────────────────────────────────────────
echo "[0/6] Verificando pré-requisitos..."

# Docker
if ! command -v docker &>/dev/null; then
    echo "  📦 Instalando Docker..."
    curl -fsSL https://get.docker.com | sh
    systemctl enable docker
    systemctl start docker
    echo "  ✅ Docker instalado"
else
    echo "  ✅ Docker já instalado: $(docker --version)"
fi

# Verificar se portas 80/443 estão ocupadas
if ss -tlnp | grep -qE ':80\s'; then
    echo "  ⚠️ Porta 80 em uso (provavelmente Nginx)"
    NGINX_ACTIVE=true
else
    NGINX_ACTIVE=false
fi

# ── 1. Parar Nginx (liberar portas para Traefik) ─────────────
echo "[1/6] Preparando portas 80/443..."
if systemctl is-active --quiet nginx 2>/dev/null; then
    echo "  🛑 Parando Nginx..."
    systemctl stop nginx
    systemctl disable nginx
    echo "  ✅ Nginx parado e desabilitado"
    echo "  ℹ️  Para reverter: systemctl enable --now nginx"
else
    echo "  ✅ Nginx não estava rodando"
fi

# Certbot renewal timer (pode conflitar com Traefik)
if systemctl is-active --quiet certbot.timer 2>/dev/null; then
    echo "  🛑 Desabilitando timer do Certbot (Traefik gerenciará SSL)..."
    systemctl stop certbot.timer
    systemctl disable certbot.timer
fi

# ── 2. Instalar Dokploy ──────────────────────────────────────
echo "[2/6] Instalando Dokploy..."
echo "  ⏳ Executando script oficial..."
curl -sSL https://dokploy.com/install.sh | sh

echo "  ⏳ Aguardando containers subirem..."
sleep 15

# Verificar se subiu
if docker ps | grep -q dokploy; then
    echo "  ✅ Dokploy rodando"
else
    echo "  ❌ ERRO: Dokploy não iniciou. Verifique: docker ps -a"
    echo "  🔄 Tentando: docker logs dokploy"
    docker logs dokploy 2>&1 | tail -20
    exit 1
fi

# ── 3. Firewall ──────────────────────────────────────────────
echo "[3/6] Configurando Firewall..."
if command -v ufw &>/dev/null; then
    # Porta 3000 (painel) — restringir depois
    ufw allow 3000/tcp comment 'Dokploy Painel (temporário)'
    # Portas 80/443 (Traefik)
    ufw allow 80/tcp comment 'Traefik HTTP'
    ufw allow 443/tcp comment 'Traefik HTTPS'
    echo "  ✅ Regras UFW adicionadas"
    ufw status | grep -E '(3000|80|443)'
else
    echo "  ⚠️ UFW não instalado, verificar iptables manualmente"
fi

# ── 4. Criar diretório de logs ────────────────────────────────
echo "[4/6] Configurando logs..."
mkdir -p /var/log/dokploy
echo "  ✅ /var/log/dokploy criado"

# ── 5. Migrar site estático crom.me via Docker ────────────────
echo "[5/6] Migrando crom.me para container..."

# Criar config Nginx customizada para o container
mkdir -p /opt/crom/dokploy
cat > /opt/crom/dokploy/crom-me-nginx.conf << 'NGINX_EOF'
server {
    listen 80;
    server_name crom.me www.crom.me;

    root /usr/share/nginx/html;
    index index.html;

    # Security Headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;

    # Gzip
    gzip on;
    gzip_types text/plain text/css application/json application/javascript text/xml;
    gzip_min_length 256;

    location / {
        try_files $uri $uri/ =404;
    }

    location ~* \.(css|js|png|jpg|jpeg|gif|ico|svg|woff|woff2)$ {
        expires 30d;
        add_header Cache-Control "public, immutable";
    }

    location ~ /\. {
        deny all;
        access_log off;
        log_not_found off;
    }
}
NGINX_EOF

# Docker compose para o site estático
cat > /opt/crom/dokploy/docker-compose-crom-me.yml << 'COMPOSE_EOF'
version: "3.8"

services:
  crom-me:
    image: nginx:alpine
    container_name: crom-me-static
    restart: unless-stopped
    volumes:
      - /var/www/crom-me:/usr/share/nginx/html:ro
      - /opt/crom/dokploy/crom-me-nginx.conf:/etc/nginx/conf.d/default.conf:ro
    networks:
      - dokploy-network
    labels:
      - "traefik.enable=true"
      # HTTP Router
      - "traefik.http.routers.crom-me.rule=Host(`crom.me`) || Host(`www.crom.me`)"
      - "traefik.http.routers.crom-me.entrypoints=web"
      # HTTPS Router
      - "traefik.http.routers.crom-me-secure.rule=Host(`crom.me`) || Host(`www.crom.me`)"
      - "traefik.http.routers.crom-me-secure.entrypoints=websecure"
      - "traefik.http.routers.crom-me-secure.tls.certresolver=letsencrypt"
      # HTTP → HTTPS redirect
      - "traefik.http.routers.crom-me.middlewares=redirect-to-https"
      - "traefik.http.middlewares.redirect-to-https.redirectscheme.scheme=https"
      - "traefik.http.middlewares.redirect-to-https.redirectscheme.permanent=true"
      # Service
      - "traefik.http.services.crom-me.loadbalancer.server.port=80"

networks:
  dokploy-network:
    external: true

COMPOSE_EOF

echo "  📦 Subindo container crom.me..."
docker compose -f /opt/crom/dokploy/docker-compose-crom-me.yml up -d

sleep 5
if docker ps | grep -q crom-me-static; then
    echo "  ✅ crom.me rodando como container"
else
    echo "  ❌ Container crom.me falhou"
    docker logs crom-me-static 2>&1 | tail -10
fi

# ── 6. Configurar Traefik para CromIA API (External Service) ──
echo "[6/6] Configurando rota Traefik para CromIA API..."

# Traefik dynamic config file provider
TRAEFIK_DYNAMIC_DIR="/opt/crom/dokploy/traefik-dynamic"
mkdir -p "${TRAEFIK_DYNAMIC_DIR}"

cat > "${TRAEFIK_DYNAMIC_DIR}/cromia-api.yml" << TRAEFIK_EOF
http:
  routers:
    cromia-api:
      rule: "Host(\`cromia-api.${CROM_DOMAIN}\`)"
      entryPoints:
        - websecure
      tls:
        certResolver: letsencrypt
      service: cromia-api
    cromia-api-http:
      rule: "Host(\`cromia-api.${CROM_DOMAIN}\`)"
      entryPoints:
        - web
      middlewares:
        - redirect-to-https
      service: cromia-api

  services:
    cromia-api:
      loadBalancer:
        servers:
          - url: "http://172.17.0.1:${CROMIA_PORT}"

  middlewares:
    redirect-to-https:
      redirectScheme:
        scheme: https
        permanent: true
TRAEFIK_EOF

echo "  ✅ Rota Traefik criada para cromia-api.crom.me → localhost:${CROMIA_PORT}"

# Montar o diretório dinâmico no Traefik
# Precisamos verificar o container do Traefik e adicionar o volume
TRAEFIK_CONTAINER=$(docker ps --filter "name=traefik" --format "{{.Names}}" | head -1)

if [ -n "${TRAEFIK_CONTAINER}" ]; then
    echo "  ℹ️  Container Traefik: ${TRAEFIK_CONTAINER}"
    echo ""
    echo "  ⚠️  AÇÃO MANUAL NECESSÁRIA:"
    echo "  Para que o Traefik carregue configs dinâmicas, execute no painel Dokploy:"
    echo "  1. Vá em Settings → Traefik"
    echo "  2. Adicione file provider apontando para /opt/crom/dokploy/traefik-dynamic/"
    echo "  OU adicione o volume ao container do Traefik:"
    echo "    docker cp ${TRAEFIK_DYNAMIC_DIR}/cromia-api.yml ${TRAEFIK_CONTAINER}:/etc/traefik/dynamic/"
    echo ""
else
    echo "  ⚠️ Container Traefik não encontrado — configurar manualmente"
fi

echo ""
echo "═══════════════════════════════════════════════════════"
echo "✅ INSTALAÇÃO CONCLUÍDA"
echo ""
echo "📋 Próximos passos:"
echo "  1. Acesse http://$(hostname -I | awk '{print $1}'):3000"
echo "  2. Crie conta admin no Dokploy"
echo "  3. Configure domínio do painel: ${DOKPLOY_DOMAIN}"
echo "  4. Configure file provider do Traefik no painel"
echo "  5. Execute 03-setup-backup.sh para cron de backup"
echo ""
echo "🔄 Para rollback: execute 04-rollback.sh"
echo "═══════════════════════════════════════════════════════"
