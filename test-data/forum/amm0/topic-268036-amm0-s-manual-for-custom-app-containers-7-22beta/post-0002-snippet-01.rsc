# Source: https://forum.mikrotik.com/t/amm0s-manual-for-custom-app-containers-7-22beta/268036/2
# Topic: 📚 Amm0's Manual for "Custom" /app containers (7.22beta+)
# Source archive: mcp-discourse SQLite (source_name=amm0)
# Extracted from: code-block

# Root-level metadata properties
name: comprehensive-app
descr: A comprehensive example demonstrating all available YAML schema options for MikroTik RouterOS container deployments
page: https://example.com/comprehensive-app
category: productivity
default-credentials: admin:SuperSecurePass123
icon: https://example.com/assets/comprehensive-app-logo.png
url-path: /dashboard
auto-update: false

# Service definitions
services:
  # Database - demonstrates environment (object), volumes, user, shm_size, stop_grace_period
  database:
    image: docker.io/postgres:16-alpine
    container_name: app-db
    hostname: database
    user: "999:999"
    environment:
      POSTGRES_DB: comprehensive
      POSTGRES_USER: appuser
      POSTGRES_PASSWORD: DatabasePass456
    volumes:
      - database/data:/var/lib/postgresql/data
      - database/backups:/backups
    restart: unless-stopped
    stop_grace_period: 30s
    shm_size: "256mb"

  # Application - demonstrates all port variations, depends_on, configs with mode
  app:
    image: ghcr.io/example/comprehensive-app:latest
    container_name: app-server
    hostname: appserver
    ports:
      - 8080:80:web
      - 8443:443/tcp:web-https
      - 9090:9090/udp:metrics
      - 5432:5432:database-proxy
    environment:
      DB_HOST: 127.0.0.1
      DB_NAME: comprehensive
      APP_URL: "[accessProto]://[accessIP]:[accessPort]"
      TRUSTED_DOMAINS: "[accessIP]"
    volumes:
      - app/data:/var/app/data
      - app/logs:/var/app/logs
    depends_on:
      - database
      - worker
    configs:
      - source: 'app_config'
        target: '/etc/app/config.yaml'
        mode: 0644
      - source: 'init_script'
        target: '/docker-entrypoint.sh'
        mode: 0755
    restart: unless-stopped

  # Worker - demonstrates environment (array) and command (array)
  worker:
    image: ghcr.io/example/comprehensive-app:latest
    container_name: app-worker
    environment:
      - WORKER_MODE=true
      - PUID=1000
      - PGID=1000
    command:
      - php
      - artisan
      - queue:work
      - --verbose
    volumes:
      - app/data:/var/app/data
    restart: unless-stopped

  # Proxy - demonstrates command (string) and security_opt
  proxy:
    image: docker.io/nginx:alpine
    container_name: app-proxy
    security_opt:
      - seccomp:unconfined
      - no-new-privileges:true
    command: nginx -g 'daemon off;'
    ports:
      - 80:80/tcp:http
    configs:
      - source: 'nginx_config'
        target: '/etc/nginx/nginx.conf'
    restart: unless-stopped

# Configuration file definitions
configs:
  'app_config':
    content: |
      server:
        host: 0.0.0.0
        port: 80
      database:
        driver: postgresql
        pool_size: 10

  'init_script':
    content: |
      #!/bin/bash
      echo "Initializing application..."
      php artisan migrate --force

  'nginx_config':
    content: |
      events {
          worker_connections 1024;
      }
      http {
          server {
              listen 80;
              location / {
                  proxy_pass http://127.0.0.1:8080;
              }
          }
      }

# Network configuration
networks:
  default:
    name: lan
    external: true
