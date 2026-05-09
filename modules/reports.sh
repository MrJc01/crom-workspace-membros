#!/usr/bin/env bash

# ╔══════════════════════════════════════════════════════════════╗
# ║  CROM Reports Module — Loader                               ║
# ║  Carrega sub-módulos de relatorios/                          ║
# ╚══════════════════════════════════════════════════════════════╝

_REPORTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/reports" && pwd)"

source "${_REPORTS_DIR}/_engine.sh"          # Infraestrutura: discover, collect, parse
source "${_REPORTS_DIR}/infra.sh"            # Relatórios 1-5: projetos, recursos, rede, storage, performance
source "${_REPORTS_DIR}/security.sh"         # Relatórios 6-8: ssl, segurança, updates
source "${_REPORTS_DIR}/members_report.sh"   # Relatórios 9-11: membros, containers, deploys
source "${_REPORTS_DIR}/services.sh"         # Relatórios 12-14: nginx, systemd, cron
source "${_REPORTS_DIR}/dns.sh"              # Relatório 15: dns
source "${_REPORTS_DIR}/menu.sh"             # Menu interativo + CLI + report_all
