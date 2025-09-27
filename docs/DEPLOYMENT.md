# Production Deployment Guide

## Overview

This guide covers deploying the application stack to production using Docker Swarm or Kubernetes.

## Production Architecture

```mermaid
graph TB
    subgraph "Internet"
        Users[Users]
        CDN[CDN/CloudFlare]
    end

    subgraph "Load Balancer"
        LB[Nginx/Traefik]
    end

    subgraph "Application Tier"
        NUXT1[Nuxt Instance 1]
        NUXT2[Nuxt Instance 2]
        API1[Symfony API 1]
        API2[Symfony API 2]
    end

    subgraph "Authentication"
        KC1[Keycloak Primary]
        KC2[Keycloak Standby]
    end

    subgraph "Data Tier"
        PG1[(PostgreSQL Primary)]
        PG2[(PostgreSQL Replica)]
        REDIS[Redis Cluster]
    end

    Users --> CDN
    CDN --> LB
    LB --> NUXT1 & NUXT2
    LB --> API1 & API2
    NUXT1 & NUXT2 --> API1 & API2
    API1 & API2 --> KC1
    KC1 -.-> KC2
    API1 & API2 --> PG1
    PG1 -.-> PG2
    API1 & API2 --> REDIS
```

## Prerequisites

- Linux server (Ubuntu 22.04 LTS recommended)
- Docker Engine and Docker Compose installed
- Domain name with DNS configured
- SSL certificates (Let's Encrypt recommended)
- Minimum 4GB RAM, 2 CPUs

## Environment Preparation

### 1. Server Setup

```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Install Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Configure firewall
sudo ufw allow 22
sudo ufw allow 80
sudo ufw allow 443
sudo ufw enable
```

### 2. Create Production Directory Structure

```bash
mkdir -p /opt/app/{config,data,logs,backups}
cd /opt/app
```

## Docker Compose Production Configuration

Create `docker-compose.prod.yml`:

```yaml
version: '3.9'

services:
  nginx:
    image: nginx:alpine
    container_name: nginx
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./config/nginx:/etc/nginx/conf.d
      - ./data/certbot/conf:/etc/letsencrypt
      - ./data/certbot/www:/var/www/certbot
    depends_on:
      - frontend
      - backend
    restart: always
    networks:
      - app-network

  frontend:
    build:
      context: ./frontend
      dockerfile: Dockerfile.prod
    container_name: frontend
    environment:
      NUXT_PUBLIC_API_BASE_URL: https://api.yourdomain.com
      NUXT_PUBLIC_KEYCLOAK_URL: https://auth.yourdomain.com
      NUXT_PUBLIC_KEYCLOAK_REALM: production
      NUXT_PUBLIC_KEYCLOAK_CLIENT_ID: nuxt-frontend
    restart: always
    networks:
      - app-network

  backend:
    build:
      context: ./backend
      dockerfile: Dockerfile.prod
    container_name: backend
    environment:
      APP_ENV: prod
      APP_SECRET: ${APP_SECRET}
      DATABASE_URL: postgresql://${DB_USER}:${DB_PASSWORD}@postgres:5432/${DB_NAME}
      JWT_SECRET_KEY: ${JWT_SECRET_KEY}
      JWT_PUBLIC_KEY: ${JWT_PUBLIC_KEY}
      KEYCLOAK_URL: http://keycloak:8080
      KEYCLOAK_REALM: production
      KEYCLOAK_CLIENT_ID: symfony-backend
      KEYCLOAK_CLIENT_SECRET: ${KEYCLOAK_CLIENT_SECRET}
      REDIS_URL: redis://redis:6379
    depends_on:
      - postgres
      - redis
    restart: always
    networks:
      - app-network

  keycloak:
    image: quay.io/keycloak/keycloak:latest
    container_name: keycloak
    command: start
    environment:
      KC_DB: postgres
      KC_DB_URL: jdbc:postgresql://postgres:5432/keycloak
      KC_DB_USERNAME: ${KC_DB_USER}
      KC_DB_PASSWORD: ${KC_DB_PASSWORD}
      KC_HOSTNAME: auth.yourdomain.com
      KC_PROXY: edge
      KC_HTTP_ENABLED: true
      KEYCLOAK_ADMIN: ${KEYCLOAK_ADMIN}
      KEYCLOAK_ADMIN_PASSWORD: ${KEYCLOAK_ADMIN_PASSWORD}
    depends_on:
      - postgres
    restart: always
    networks:
      - app-network

  postgres:
    image: postgres:16-alpine
    container_name: postgres
    environment:
      POSTGRES_DB: ${DB_NAME}
      POSTGRES_USER: ${DB_USER}
      POSTGRES_PASSWORD: ${DB_PASSWORD}
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./backups:/backups
    restart: always
    networks:
      - app-network

  redis:
    image: redis:7-alpine
    container_name: redis
    command: redis-server --appendonly yes
    volumes:
      - redis_data:/data
    restart: always
    networks:
      - app-network

  certbot:
    image: certbot/certbot
    container_name: certbot
    volumes:
      - ./data/certbot/conf:/etc/letsencrypt
      - ./data/certbot/www:/var/www/certbot
    entrypoint: "/bin/sh -c 'trap exit TERM; while :; do certbot renew; sleep 12h & wait $${!}; done;'"

volumes:
  postgres_data:
  redis_data:

networks:
  app-network:
    driver: bridge
```

## SSL Configuration

### 1. Initial Certificate Generation

```bash
# Create nginx config for cert generation
cat > config/nginx/default.conf <<EOF
server {
    listen 80;
    server_name yourdomain.com api.yourdomain.com auth.yourdomain.com;

    location /.well-known/acme-challenge/ {
        root /var/www/certbot;
    }

    location / {
        return 301 https://\$host\$request_uri;
    }
}
EOF

# Start nginx
docker-compose -f docker-compose.prod.yml up -d nginx

# Generate certificates
docker-compose -f docker-compose.prod.yml run --rm certbot certonly \
    --webroot \
    --webroot-path /var/www/certbot \
    --email your-email@example.com \
    --agree-tos \
    --no-eff-email \
    -d yourdomain.com \
    -d api.yourdomain.com \
    -d auth.yourdomain.com
```

### 2. Production Nginx Configuration

Create `config/nginx/app.conf`:

```nginx
upstream frontend {
    server frontend:3000;
}

upstream backend {
    server backend:80;
}

upstream keycloak {
    server keycloak:8080;
}

# Frontend
server {
    listen 443 ssl http2;
    server_name yourdomain.com;

    ssl_certificate /etc/letsencrypt/live/yourdomain.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/yourdomain.com/privkey.pem;

    location / {
        proxy_pass http://frontend;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}

# API
server {
    listen 443 ssl http2;
    server_name api.yourdomain.com;

    ssl_certificate /etc/letsencrypt/live/yourdomain.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/yourdomain.com/privkey.pem;

    location / {
        proxy_pass http://backend;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}

# Keycloak
server {
    listen 443 ssl http2;
    server_name auth.yourdomain.com;

    ssl_certificate /etc/letsencrypt/live/yourdomain.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/yourdomain.com/privkey.pem;

    location / {
        proxy_pass http://keycloak;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_buffer_size 64k;
        proxy_buffers 8 64k;
        proxy_busy_buffers_size 64k;
    }
}
```

## Environment Variables

Create `.env.prod`:

```env
# Database
DB_NAME=app_production
DB_USER=app_user
DB_PASSWORD=<strong-password>

# Keycloak Database
KC_DB_USER=keycloak
KC_DB_PASSWORD=<strong-password>

# Keycloak Admin
KEYCLOAK_ADMIN=admin
KEYCLOAK_ADMIN_PASSWORD=<strong-admin-password>

# Symfony
APP_SECRET=<generate-with-openssl-rand-hex-32>
JWT_SECRET_KEY=<path-to-private-key>
JWT_PUBLIC_KEY=<path-to-public-key>
KEYCLOAK_CLIENT_SECRET=<from-keycloak-console>
```

## Deployment Steps

### 1. Build and Deploy

```bash
# Clone repository
git clone <repository-url> /opt/app
cd /opt/app

# Copy production environment file
cp .env.prod .env

# Build and start services
docker-compose -f docker-compose.prod.yml build
docker-compose -f docker-compose.prod.yml up -d

# Run migrations
docker-compose -f docker-compose.prod.yml exec backend php bin/console doctrine:migrations:migrate --no-interaction

# Clear and warm cache
docker-compose -f docker-compose.prod.yml exec backend php bin/console cache:clear --env=prod
docker-compose -f docker-compose.prod.yml exec backend php bin/console cache:warmup --env=prod
```

### 2. Configure Keycloak

1. Access Keycloak admin: https://auth.yourdomain.com/admin
2. Create production realm
3. Configure clients with production URLs
4. Set up user federation if needed (LDAP/AD)
5. Configure email settings for password reset

## Monitoring and Maintenance

### Health Checks

```bash
# Check all services
docker-compose -f docker-compose.prod.yml ps

# Check logs
docker-compose -f docker-compose.prod.yml logs -f [service-name]

# Health endpoint
curl https://api.yourdomain.com/health
```

### Backup Strategy

Create backup script `/opt/app/scripts/backup.sh`:

```bash
#!/bin/bash

BACKUP_DIR="/opt/app/backups"
DATE=$(date +%Y%m%d_%H%M%S)

# Database backup
docker-compose -f docker-compose.prod.yml exec -T postgres pg_dumpall -U app_user > $BACKUP_DIR/db_backup_$DATE.sql

# Keycloak realm export
docker-compose -f docker-compose.prod.yml exec -T keycloak \
    /opt/keycloak/bin/kc.sh export --dir /tmp --realm production
docker cp keycloak:/tmp/production-realm.json $BACKUP_DIR/keycloak_$DATE.json

# Compress old backups
find $BACKUP_DIR -name "*.sql" -mtime +7 -exec gzip {} \;

# Delete backups older than 30 days
find $BACKUP_DIR -name "*.gz" -mtime +30 -delete
```

Add to crontab:
```bash
0 2 * * * /opt/app/scripts/backup.sh
```

### Updates and Maintenance

```bash
# Pull latest changes
git pull origin main

# Rebuild and deploy with zero downtime
docker-compose -f docker-compose.prod.yml build
docker-compose -f docker-compose.prod.yml up -d --no-deps --build frontend
docker-compose -f docker-compose.prod.yml up -d --no-deps --build backend

# Run migrations if needed
docker-compose -f docker-compose.prod.yml exec backend php bin/console doctrine:migrations:migrate --no-interaction
```

## Performance Optimization

### 1. Enable OPcache
Already configured in production Dockerfile

### 2. Redis Configuration
```redis
maxmemory 256mb
maxmemory-policy allkeys-lru
```

### 3. PostgreSQL Tuning
```postgresql
shared_buffers = 256MB
effective_cache_size = 1GB
maintenance_work_mem = 64MB
```

### 4. Nginx Caching
Add to nginx config:
```nginx
proxy_cache_path /var/cache/nginx levels=1:2 keys_zone=app_cache:10m max_size=1g;
proxy_cache app_cache;
proxy_cache_valid 200 60m;
```

## Security Hardening

### 1. Firewall Rules
```bash
# Only allow necessary ports
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow 22/tcp
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw enable
```

### 2. Fail2ban Installation
```bash
sudo apt install fail2ban
sudo systemctl enable fail2ban
```

### 3. Regular Updates
```bash
# System updates
sudo apt update && sudo apt upgrade -y

# Docker images
docker-compose -f docker-compose.prod.yml pull
docker-compose -f docker-compose.prod.yml up -d
```

## Troubleshooting

### Common Issues

1. **502 Bad Gateway**
   - Check if services are running
   - Verify nginx upstream configuration
   - Check service logs

2. **Database Connection Failed**
   - Verify PostgreSQL is running
   - Check credentials in .env
   - Ensure network connectivity

3. **Keycloak Issues**
   - Check Keycloak logs
   - Verify database connection
   - Ensure proper realm configuration

### Debug Commands
```bash
# Container logs
docker logs [container-name] --tail 100 -f

# Enter container shell
docker exec -it [container-name] /bin/sh

# Network debugging
docker network inspect app_app-network

# Resource usage
docker stats
```