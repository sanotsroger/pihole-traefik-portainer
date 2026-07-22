http:
  routers:
    gitlab-pages:
      entryPoints:
        - "https"
      rule: "Host(`pages.${DOMAIN_NAME}`)"
      tls: {}
      service: gitlab-pages
  services:
    gitlab-pages:
      loadBalancer:
        servers:
          - url: "http://${GITLAB_PAGES_IP}"
        passHostHeader: true
