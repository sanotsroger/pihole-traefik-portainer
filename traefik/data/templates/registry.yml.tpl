http:
  routers:
    registry:
      entryPoints:
        - "https"
      rule: "Host(`registry.${DOMAIN_NAME}`)"
      tls: {}
      service: registry
  services:
    registry:
      loadBalancer:
        servers:
          - url: "http://${GITLAB_REGISTRY_IP}"
        passHostHeader: true
