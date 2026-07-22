http:
  routers:
    gitlab:
      entryPoints:
        - "https"
      rule: "Host(`gitlab.${DOMAIN_NAME}`)"
      tls: {}
      service: gitlab
  services:
    gitlab:
      loadBalancer:
        servers:
          - url: "http://${GITLAB_IP}"
        passHostHeader: true

tcp:
  routers:
    gitlab-ssh:
      entryPoints:
        - "ssh-gitlab"
      rule: "HostSNI(`*`)"
      service: gitlab-ssh

  services:
    gitlab-ssh:
      loadBalancer:
        servers:
          - address: "${GITLAB_IP}:${GITLAB_SSH_PORT}"
