#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SECRETS_DIR="$SCRIPT_DIR/../secrets/authelia"

FORCE=0
if [[ "${1:-}" == "-f" || "${1:-}" == "--force" ]]; then
  FORCE=1
fi

mkdir -p "$SECRETS_DIR"

generate() {
  local name="$1" bytes="$2"
  local file="$SECRETS_DIR/$name"

  if [[ -f "$file" && "$FORCE" -ne 1 ]]; then
    echo "skip:  $name (already exists, use -f/--force to overwrite)"
    return
  fi

  openssl rand -hex "$bytes" > "$file"
  chmod 600 "$file"
  echo "wrote: $name"
}

generate jwt_secret 64
generate session_secret 64
generate storage_password 32
generate storage_encryption_key 32
generate redis_password 32

cat <<EOF

Secrets written to $SECRETS_DIR

Ainda faltam passos manuais antes de subir o stack:
  1. Gerar o hash da senha do usuário e colar em authelia/config/users_database.yml:
       docker run --rm authelia/authelia:\${AUTHELIA_VERSION} authelia crypto hash generate argon2 --password 'suasenha'
  2. Substituir 'domain.com' pelo seu domínio real em:
       authelia/config/configuration.yml
       authelia/config/users_database.yml
EOF
