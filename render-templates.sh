#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="$ROOT_DIR/.env"

if [[ ! -f "$ENV_FILE" ]]; then
  echo "error: $ENV_FILE not found. Copy .env.example to .env and set DOMAIN_NAME first." >&2
  exit 1
fi

set -a
# shellcheck disable=SC1090
source "$ENV_FILE"
set +a

if [[ -z "${DOMAIN_NAME:-}" ]]; then
  echo "error: DOMAIN_NAME is not set in $ENV_FILE" >&2
  exit 1
fi

command -v envsubst >/dev/null || { echo "error: envsubst not found (install gettext)" >&2; exit 1; }

# Build the envsubst whitelist from every variable name defined in .env
# (not the full inherited shell environment). Passing an explicit list
# restricts substitution to just these names, so unrelated "$" sequences
# elsewhere (e.g. argon2 hashes in users_database.yml) are copied through
# untouched instead of being blanked out.
SUBST_VARS="$(grep -oE '^[A-Za-z_][A-Za-z0-9_]*=' "$ENV_FILE" | sed -e 's/=$//' -e 's/^/$/' | tr '\n' ' ')"

# authelia/config/users_database.yml holds real credentials (password hash,
# email) once you edit it. It must never be silently overwritten by a
# re-render, so it's rendered once from its .tpl (if missing) and skipped on
# every run after that.
USERS_DB_TPL="$ROOT_DIR/authelia/config/users_database.yml.tpl"
USERS_DB="$ROOT_DIR/authelia/config/users_database.yml"
if [[ -f "$USERS_DB_TPL" ]]; then
  if [[ -f "$USERS_DB" ]]; then
    echo "skip:     authelia/config/users_database.yml (already exists, edit it directly)"
  else
    envsubst "$SUBST_VARS" < "$USERS_DB_TPL" > "$USERS_DB"
    echo "rendered: authelia/config/users_database.yml (first time)"
  fi
fi

count=0

# authelia/config/configuration.yml.tpl has no user-editable per-file content
# (only domain placeholders), so it's safe to always re-render in place.
while IFS= read -r -d '' tpl; do
  out="${tpl%.tpl}"
  envsubst "$SUBST_VARS" < "$tpl" > "$out"
  echo "rendered: ${out#"$ROOT_DIR"/}"
  count=$((count + 1))
done < <(find "$ROOT_DIR/authelia/config" -maxdepth 1 -name '*.tpl' -not -name 'users_database.yml.tpl' -print0)

# traefik/data/templates/*.yml.tpl are rendered into traefik/data/config.d/.
# Once a rendered file exists there it's assumed to be hand-edited (real
# backend IPs/ports), so it's never overwritten by a re-render.
TEMPLATES_DIR="$ROOT_DIR/traefik/data/templates"
CONFIG_D_DIR="$ROOT_DIR/traefik/data/config.d"
mkdir -p "$CONFIG_D_DIR"
while IFS= read -r -d '' tpl; do
  out="$CONFIG_D_DIR/$(basename "${tpl%.tpl}")"
  if [[ -f "$out" ]]; then
    echo "skip:     ${out#"$ROOT_DIR"/} (already exists, edit it directly)"
    continue
  fi
  envsubst "$SUBST_VARS" < "$tpl" > "$out"
  echo "rendered: ${out#"$ROOT_DIR"/}"
  count=$((count + 1))
done < <(find "$TEMPLATES_DIR" -maxdepth 1 -name '*.tpl' -print0)

echo "$count template(s) rendered."
