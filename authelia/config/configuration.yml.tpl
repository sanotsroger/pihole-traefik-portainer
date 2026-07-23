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
  ldap:
    implementation: 'lldap'
    address: 'ldap://lldap:3890'
    base_dn: '${LLDAP_BASE_DN}'
    additional_users_dn: 'ou=people'
    additional_groups_dn: 'ou=groups'
    users_filter: '(&(|({username_attribute}={input})({mail_attribute}={input}))(objectClass=person))'
    groups_filter: '(&(member={dn})(objectClass=groupOfNames))'
    user: 'uid=authelia,ou=people,${LLDAP_BASE_DN}'
    attributes:
      username: uid
      display_name: cn
      mail: mail
      member_of: memberOf

access_control:
  default_policy: deny
  rules:
    - domain: "auth.${DOMAIN_NAME}"
      policy: bypass
    - domain: "*.${DOMAIN_NAME}"
      policy: one_factor

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
