---
theme: dark

server:
  address: "tcp://:9091"

log:
  level: info

totp:
  disable: false
  issuer: ${DOMAIN_NAME}

authentication_backend:
  file:
    path: /config/users_database.yml
    password:
      algorithm: argon2
      argon2:
        variant: argon2id
        iterations: 3
        memory: 65536
        parallelism: 4
        key_length: 32
        salt_length: 16

access_control:
  default_policy: deny
  rules:
    - domain: "auth.${DOMAIN_NAME}"
      policy: bypass

session:
  cookies:
    - domain: "${DOMAIN_NAME}"
      authelia_url: "https://auth.${DOMAIN_NAME}"
      default_redirection_url: "https://${DOMAIN_NAME}"
  redis:
    host: authelia-redis
    port: 6379

regulation:
  max_retries: 3
  find_time: 2m
  ban_time: 5m

storage:
  postgres:
    address: "tcp://authelia-postgres:5432"
    database: authelia
    username: authelia

notifier:
  filesystem:
    filename: /config/notification.txt
