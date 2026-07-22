# Migrar autenticação da Authelia de `file` (users_database.yml) para LDAP via lldap

## Contexto

Hoje a Authelia autentica contra o backend `file`
([authelia/config/configuration.yml](../../Downloads/pihole-traefik-portainer/authelia/config/configuration.yml#L14-L25)),
que lê usuários de `authelia/config/users_database.yml` — atualmente um único usuário
(`sanotsroger`, grupo `admins`, hash argon2id). O usuário quer entender/migrar para um backend
LDAP. Optou por rodar um servidor **lldap** (leve, feito para casar com Authelia) como novo
serviço no próprio stack, em vez de apontar para um LDAP externo.

O objetivo é trocar `authentication_backend.file` por `authentication_backend.ldap`, subir o
container lldap seguindo os mesmos padrões já usados no repo (compose por serviço incluído no
`compose.yml` raiz, secrets como arquivos em `./secrets/<serviço>/`, IP fixo na rede `proxy`,
templates `.tpl` renderizados por `render-templates.sh`), e migrar manualmente o usuário existente
para dentro do lldap (não dá para automatizar 100% isso — precisa da UI do lldap na primeira vez).

## Mudanças

### 1. Novo serviço `lldap/`
- `lldap/compose.yml`: container `${CT_LLDAP}` na rede `proxy` com IP `${CT_LLDAP_IP}`
  (`172.42.0.9`, próximo livre depois do `.8` da authelia-redis). Sem `ports:` publicada —
  mesmo padrão do authelia/postgres/redis: acesso interno via rede docker, UI web exposta só
  via labels do Traefik (roteador `ldap.${DOMAIN_NAME}` -> porta `17170`, entrypoints
  http→https redirect + https com `tls.certresolver=cloudflare`, igual ao bloco de labels da
  authelia em [authelia/compose.yml](../../Downloads/pihole-traefik-portainer/authelia/compose.yml#L39-L54)).
  Proteger a UI do lldap com o middleware `authelia@docker` (já existe, hoje comentado/não
  usado em nenhum outro serviço — ver `traefik/compose.yml:46`) já que essa UI cria/edita
  usuários e senhas.
  - Env vars via secrets (lldap suporta `_FILE` para essas três): `LLDAP_JWT_SECRET_FILE`,
    `LLDAP_KEY_SEED_FILE`, `LLDAP_LDAP_USER_PASS_FILE` apontando para `/run/secrets/...`.
  - `LLDAP_LDAP_BASE_DN=${LLDAP_BASE_DN}`, `UID=${PUID}`, `GID=${PGID}`, `TZ=${TIMEZONE}`.
  - Volume `./data:/data` (sqlite do lldap).
  - Healthcheck simples via wget na porta 17170, igual padrão da authelia.
- `lldap/generate-secrets.sh`: cópia do padrão de
  [authelia/generate-secrets.sh](../../Downloads/pihole-traefik-portainer/authelia/generate-secrets.sh),
  gerando `secrets/lldap/jwt_secret`, `secrets/lldap/key_seed`, `secrets/lldap/user_pass`
  (openssl rand -hex, chmod 600, skip se já existir).
- `secrets/lldap/*_example` (placeholders versionados, mesmo padrão de `secrets/authelia/*_example`).

### 2. `authelia/config/configuration.yml.tpl` (e re-renderizar o `.yml`)
Trocar o bloco `authentication_backend.file` por:
```yaml
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
```
(Sem `password:` no yaml — vem via env, ver item 3. Hostname `lldap` hardcoded, mesmo estilo
já usado para `authelia-postgres`/`authelia-redis` no arquivo atual — não é templatizado.)

Depois de editar o `.tpl`, rodar `./render-templates.sh` (ele já re-renderiza
`configuration.yml` sempre, conforme comentário em
[render-templates.sh:48-55](../../Downloads/pihole-traefik-portainer/render-templates.sh#L48-L55)).

### 3. `authelia/compose.yml`
- Adicionar `AUTHELIA_AUTHENTICATION_BACKEND_LDAP_PASSWORD_FILE: /run/secrets/authelia_ldap_password`
  nas `environment:` (mesmo mecanismo genérico de `_FILE` que a Authelia já usa para
  `AUTHELIA_STORAGE_POSTGRES_PASSWORD_FILE` etc.).
- Adicionar `authelia_ldap_password` em `secrets:` do serviço.
- Adicionar `depends_on: lldap`.

### 4. `compose.yml` (raiz)
- Adicionar ao bloco `secrets:`: `lldap_jwt_secret`, `lldap_key_seed`, `lldap_user_pass`
  (arquivos em `./secrets/lldap/...`) e `authelia_ldap_password`
  (`./secrets/authelia/ldap_password`).
- Adicionar `- lldap/compose.yml` em `include:`.

### 5. `.env` e `.env.example`
Novo bloco, seguindo o padrão de comentários já usado para os outros serviços:
```
# LLDAP
CT_LLDAP=lldap
CT_LLDAP_IP=172.42.0.9
LLDAP_VERSION=stable
# Base DN derivado do domínio: cada parte separada por ponto vira um componente dc=.
# Ex.: sanotsroger.com.br -> dc=sanotsroger,dc=com,dc=br
LLDAP_BASE_DN=dc=sanotsroger,dc=com,dc=br
```
(`.env.example` usa `dc=example,dc=com` para casar com `DOMAIN_NAME=domain.com` de lá.)

### 6. `.gitignore`
Adicionar:
```
# LLDAP
secrets/lldap/jwt_secret
secrets/lldap/key_seed
secrets/lldap/user_pass
secrets/authelia/ldap_password
lldap/data/*
```

### 7. Aposentar `users_database.yml`
Como a Authelia passa a usar `ldap`, o backend `file` não é mais lido. Remover o tratamento
especial de `users_database.yml.tpl` em `render-templates.sh` (bloco de
[render-templates.sh:30-44](../../Downloads/pihole-traefik-portainer/render-templates.sh#L30-L44)),
apagar `authelia/config/users_database.yml` e `.tpl`, e remover as duas linhas de re-include
desses arquivos no `.gitignore`. Atualizar as instruções finais de
`authelia/generate-secrets.sh` (linhas 38-44) trocando o passo "gerar hash e colar no
users_database.yml" pelos passos manuais de LDAP abaixo.

### 8. Passos manuais (não dá pra automatizar via compose)
Depois de subir `lldap` pela primeira vez:
1. Login na UI (`https://ldap.${DOMAIN_NAME}`) com `admin` / senha de `secrets/lldap/user_pass`.
2. Criar grupo `admins` em Groups (equivalente ao grupo do `users_database.yml` atual — hoje
   nenhuma regra de `access_control` usa esse grupo, é só paridade/uso futuro).
3. Recriar o usuário `sanotsroger` (displayname, email, senha), adicionar ao grupo `admins`.
4. Criar um usuário de serviço `authelia` (ou usar o grupo builtin `lldap_strict_readonly`),
   com a senha igual ao conteúdo de `secrets/authelia/ldap_password` — esse é o bind user que
   a Authelia usa para consultar o diretório (nunca usar a conta `admin` para isso).

## Verificação
- `./render-templates.sh` roda sem erro e gera o novo `authentication_backend.ldap` em
  `authelia/config/configuration.yml`.
- `docker compose config` (na raiz) valida sem erro de secret/include faltando.
- Subir a stack, completar os passos manuais acima, e testar login em
  `https://auth.${DOMAIN_NAME}` com o usuário `sanotsroger` recriado no lldap — deve autenticar
  e liberar acesso a um serviço protegido (ex.: rota com `authelia@docker` middleware).
- Checar logs do container `authelia` para confirmar bind LDAP OK (sem erro de credenciais/DN).
