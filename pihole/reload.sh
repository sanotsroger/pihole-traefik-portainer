#!/usr/bin/env bash
set -euo pipefail

# Campos FTLCONF_* (ex.: dns.cnameRecords) ficam travados para edição em tempo
# real pelo próprio pihole-FTL quando definidos via variável de ambiente — só
# são reaplicados quando o container é recriado com o env atualizado. Não
# existe hot-reload possível para esses campos; este script apenas automatiza
# o fluxo: re-renderiza os templates (gera pihole/cname.env atualizado) e
# recria só o serviço pihole (não afeta os outros containers da stack).

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

"$ROOT_DIR/render-templates.sh"

cd "$ROOT_DIR"
docker compose up -d pihole
