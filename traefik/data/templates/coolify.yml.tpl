http:
  routers:
    coolify:
      entryPoints:
        - "https"
      rule: "Host(`coolify.${DOMAIN_NAME}`)"
      tls: {}
      service: coolify
  services:
    coolify:
      loadBalancer:
        servers:
          - url: "http://${COOLIFY_IP}"
        passHostHeader: true
