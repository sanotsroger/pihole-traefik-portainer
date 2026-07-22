http:
  routers:
    pve:
      entryPoints:
        - "https"
      rule: "Host(`pve.${DOMAIN_NAME}`)"
      tls: {}
      service: pve
  services:
    pve:
      loadBalancer:
        servers:
          - url: "http://${PVE_IP}"
        passHostHeader: true
