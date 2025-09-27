# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Architecture Overview

This is a modern full-stack application implementing a **Backend for Frontend (BFF) pattern** with the following key components:

- **Frontend**: Nuxt 3 with SSR (port 3000) - serves as the BFF layer
- **Backend**: Symfony 7 with API Platform on FrankenPHP (port 8080)
- **Authentication**: Keycloak identity provider (port 8090)
- **Database**: PostgreSQL 16 with dual schemas (app + keycloak)
- **Cache**: Redis 7 for sessions and caching

### BFF Pattern Implementation

All browser requests flow through the Nuxt server, which then makes server-to-server API calls to Symfony. This provides:
- Enhanced security (no direct browser-to-API communication)
- Server-side token management
- Unified session handling via Redis
- Single point of configuration for client-side routing

## Development Environment

### Container Architecture

The application runs entirely in Docker containers:

- `symfony-backend`: FrankenPHP + Symfony 7 + API Platform
- `nuxt-frontend`: Nuxt 3 with Node.js runtime
- `keycloak`: Identity provider with admin console
- `postgres`: Primary database with multi-database setup
- `redis`: Session storage and application cache
- `nginx`: Reverse proxy (optional for dev, required for production)

### Key Configuration Files

- `docker-compose.yml`: Full container orchestration
- `backend/Caddyfile`: FrankenPHP web server configuration
- `backend/Dockerfile`: Custom FrankenPHP image with PHP extensions
- `frontend/nuxt.config.ts`: Nuxt configuration (minimal baseline)
- `docs/ARCHITECTURE.md`: Detailed technical architecture

## Common Development Commands

### Docker Operations

```bash
# Start all services
docker-compose up -d

# Rebuild services after changes
docker-compose build --no-cache
docker-compose up -d --force-recreate

# View service logs
docker-compose logs -f [service-name]

# Access container shells
docker-compose exec backend sh
docker-compose exec frontend sh

# Check service health
docker-compose ps
```

### Backend Development (Symfony)

```bash
# Enter backend container
docker-compose exec backend sh

# Symfony console commands
php bin/console [command]

# Common Symfony operations
php bin/console make:entity
php bin/console make:migration
php bin/console doctrine:migrations:migrate
php bin/console cache:clear

# API Platform routes
php bin/console debug:router
```

### Frontend Development (Nuxt)

```bash
# Enter frontend container
docker-compose exec frontend sh

# Nuxt development commands
npm run dev
npm run build
npm run generate

# Add components/pages
npx nuxi add component ComponentName
npx nuxi add page pagename
```

### Database Operations

```bash
# Connect to PostgreSQL
docker-compose exec postgres psql -U app_user -d app_db

# Reset database
docker-compose exec backend php bin/console doctrine:database:drop --force
docker-compose exec backend php bin/console doctrine:database:create
docker-compose exec backend php bin/console doctrine:migrations:migrate
```

## Service URLs

- **Frontend (BFF)**: http://localhost:3000
- **Backend API**: http://localhost:8080
- **API Documentation**: http://localhost:8080/api
- **Keycloak Admin**: http://localhost:8090/admin (admin/admin123)

## Key Environment Variables

The application uses environment variables defined in `docker-compose.yml`:

### Backend (Symfony)
- `DATABASE_URL`: PostgreSQL connection string
- `REDIS_URL`: Redis connection string
- `KEYCLOAK_URL`: Internal Keycloak URL for server-to-server
- `KEYCLOAK_REALM`: Currently set to "skeleton"
- `APP_ENV`: Development environment
- `APP_SECRET`: Symfony application secret

### Frontend (Nuxt)
- `NUXT_API_BASE_URL`: Internal backend URL (http://backend:80)
- `NUXT_KEYCLOAK_URL`: Internal Keycloak URL for server-side auth
- `NUXT_PUBLIC_KEYCLOAK_URL`: Public Keycloak URL for browser redirects
- `NUXT_SESSION_SECRET`: Session encryption key

## Authentication Flow

1. User authentication happens via Keycloak OIDC
2. Nuxt server handles token exchange and validation
3. Tokens are stored server-side (never exposed to browser)
4. Nuxt makes authenticated API calls to Symfony on behalf of users
5. Sessions are managed via Redis with httpOnly cookies

## Development Notes

### Keycloak Configuration

The realm name is configured as "skeleton" in the environment variables. When setting up Keycloak:

1. Create realm named "skeleton"
2. Configure clients for `nuxt-frontend` and `symfony-backend`
3. Set up appropriate redirect URIs and client types

### File Structure

```
backend/                    # Symfony API
├── src/                   # PHP application code
├── config/                # Symfony configuration
├── public/                # Web root
├── Caddyfile             # FrankenPHP configuration
└── Dockerfile            # Custom FrankenPHP image

frontend/                  # Nuxt BFF
├── pages/                # Application routes
├── components/           # Vue components
├── composables/          # Shared logic
├── server/               # Server-side API routes (BFF layer)
└── nuxt.config.ts        # Nuxt configuration

docs/                     # Technical documentation
├── ARCHITECTURE.md       # System design
├── API.md               # API documentation
├── SETUP.md             # Setup instructions
└── DEPLOYMENT.md        # Production deployment
```

### Technology Versions

- PHP 8.3+ with FrankenPHP
- Symfony 7.3.*
- API Platform 4.2+
- Nuxt 4.1+
- Vue 3.5+
- Keycloak 24.0
- PostgreSQL 16
- Redis 7

This codebase uses modern versions and follows current best practices for each technology stack.