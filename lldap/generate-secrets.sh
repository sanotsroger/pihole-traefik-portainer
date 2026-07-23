#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SECRETS_DIR="$SCRIPT_DIR/../secrets/lldap"

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
generate key_seed 32
generate user_pass 32

cat <<EOF

Secrets written to $SECRETS_DIR

Ainda faltam passos manuais antes de terminar a migração (ver docs/ldpa-migration.md):
  1. Subir o container lldap e logar na UI (https://ldap.\${DOMAIN_NAME}) com o usuário
     'admin' e a senha gerada em secrets/lldap/user_pass.
  2. Criar o grupo 'admins' e recriar o usuário 'sanotsroger' dentro do lldap.
  3. Criar o usuário de serviço da Authelia (bind user), com a senha igual ao conteúdo de
     secrets/authelia/ldap_password (gerado por ./authelia/generate-secrets.sh).
EOF
