http:
  routers:
    mailpit:
      entryPoints:
        - "https"
      rule: "Host(`mailpit.${DOMAIN_NAME}`)"
      tls: {}
      service: mailpit
  services:
    mailpit:
      loadBalancer:
        servers:
          - url: "http://${MAILPIT_IP}"
        passHostHeader: true

tcp:
  routers:
    mailpit-smtp:
      entryPoints:
        - "mailpit-smtp"
      rule: "HostSNI(`*`)"
      service: mailpit-smtp

  services:
    mailpit-smtp:
      loadBalancer:
        servers:
          - address: "10.0.0.45:1025"
