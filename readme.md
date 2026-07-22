# Homelab Arch

## Network

Create network external.

```shell
docker network create --gateway 172.42.0.1 --subnet 172.42.0.0/24 proxy
```

## Domain Pi-Hole

Edit `/etc/hosts`.

```shell
sudo nano /etc/hosts
```

Added line

```shel
127.0.0.1  docker.local
```

Create DNS Records [A/AAAA]

| Domain       | Ip          |
| ------------ | ----------- |
| docker.local | 192.168.0.x |

Local CNAME Records

| Domain                 | Target       |
| ---------------------- | ------------ |
| pihole.domain.com      | docker.local |
| portainer.domain.com   | docker.local |
| traefik.domain.com     | docker.local |

## Clouflare

Access this link to [create token](https://dash.cloudflare.com/profile/api-tokens) in Cloudflare.

![alt text](assets/images/cloudflare-token-01.png)

![alt text](assets/images/cloudflare-token-02.png)

## Traefik

Before uploading the container, create the following directories and files, giving them the necessary permissions.

```bash
mkdir -p traefik/data && cd traefik/data && touch acme.json && chmod 600 acme.json
```

## Pihole Tips

![alt text](assets/images/pihole-interface-settings.png)

Configura o ip real da maquina local

![alt text](assets/images/config-ip-01.png)

![alt text](assets/images/config-ip-02.png)

![alt text](assets/images/config-ip-03.png)

## Portainer

Verifique os logs para obter o `setup_token`.

```bash
docker logs portainer -f
```
