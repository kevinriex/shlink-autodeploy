# Shlink Autodeployment

a simple tool which installs shlink and portainer with web ui on a fresh debian server.

## Prerequisites

Before you start with the installation, make sure you have the following:

1. A DNS configured for `domain.tld` and `*.domain.tld`.

```dns
; A record for domain.tld
domain.tld.    IN    A     xxx.xxx.xxx.xxx
; AAAA record for domain.tld
domain.tld.    IN    AAAA  1234:5678:90ab:cdef:1234:5678:90ab:cdef

; Wildcard A record for *.domain.tld
*.domain.tld.  IN    A     xxx.xxx.xxx.xxx

; Wildcard AAAA record for *.domain.tld
*.domain.tld.  IN    AAAA  1234:5678:90ab:cdef:1234:5678:90ab:cdef
```

2. A fresh debian 12 (bookworm) server, for example, Hetzner CX11.

## Start Script

```bash
curl -L https://raw.githubusercontent.com/kevinriex/shlink-autodeploy/master/shlink-autodeploy.sh | sudo bash
```

## Clean Server

This script removes all changed made to the server including ALL DATA!!

```bash
curl -L https://raw.githubusercontent.com/kevinriex/shlink-autodeploy/master/clean-server.sh | sudo bash
```

## Management Commands

### Start

```bash
(cd /storage/compose/shlink && docker-compose up -d) # Start Shlink
(cd /storage/compose/traefik && docker-compose up -d) # Start Traefik Proxy
(cd /storage/compose/portainer && docker-compose up -d) # Start Portainer
```

### Stop

```bash
(cd /storage/compose/shlink && docker-compose down) # Stop Shlink
(cd /storage/compose/traefik && docker-compose down) # Stop Traefik Proxy
(cd /storage/compose/portainer && docker-compose down) # Stop Portainer
```

### Restart

```bash
(cd /storage/compose/shlink && docker-compose down && docker-compose up -d) # Restart Shlink
(cd /storage/compose/traefik && docker-compose down && docker-compose up -d) # Restart Traefik Proxy
(cd /storage/compose/portainer && docker-compose down && docker-compose up -d) # Restart Portainer
```

## Update

```bash
(cd /storage/compose/shlink && docker-compose pull && docker-compose up -d) # Restart Shlink
(cd /storage/compose/traefik && docker-compose pull && docker-compose up -d) # Restart Traefik Proxy
(cd /storage/compose/portainer && docker-compose pull && docker-compose up -d) # Restart Portainer
```

## View Logs

```bash
(cd /storage/compose/shlink && docker-compose logs) # Shows logs from Shlink
(cd /storage/compose/traefik && docker-compose logs) # Shows logs from Traefik Proxy
(cd /storage/compose/portainer && docker-compose logs) # Shows logs from Portainer
```