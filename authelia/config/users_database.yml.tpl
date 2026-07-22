---
# Generate a real hash with:
#   docker run --rm authelia/authelia:${AUTHELIA_VERSION} authelia crypto hash generate argon2 --password 'yourpassword'
# and replace the placeholder below before starting the stack.
users:
  authelia:
    displayname: "Authelia Admin"
    password: "$argon2id$v=19$m=65536,t=3,p=4$CHANGE_ME_GENERATE_A_REAL_HASH$CHANGE_ME"
    email: user@${DOMAIN_NAME}
    groups:
      - admins
