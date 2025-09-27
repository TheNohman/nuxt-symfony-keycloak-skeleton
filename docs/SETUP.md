# Development Environment Setup Guide

## Prerequisites

- Docker Desktop or Docker Engine (v24.0+)
- Docker Compose (v2.20+)
- Git
- Node.js 20+ (for local development)
- PHP 8.3+ and Composer (for local Symfony development)

## Quick Start

1. Clone the repository
```bash
git clone <repository-url>
cd nuxt-symfony-keycloak-skeleton
```

2. Start all services with Docker Compose
```bash
docker-compose up -d
```

3. Wait for services to be ready (check logs)
```bash
docker-compose logs -f
```

## Service URLs

After successful startup, services are available at:

- **Frontend (Nuxt)**: http://localhost:3000
- **Backend API (Symfony)**: http://localhost:8080
- **API Documentation**: http://localhost:8080/api
- **Keycloak Admin**: http://localhost:8090/admin
  - Default admin: `admin` / `admin123`
- **PostgreSQL**: localhost:5432
  - Database: `app_db`
  - User: `app_user` / `app_password`

## Initial Configuration

### 1. Keycloak Setup

Access Keycloak admin console and:

1. Create a new realm called `app-realm`
2. Create clients:
   - `nuxt-frontend` (public client for Nuxt)
   - `symfony-backend` (confidential client for API)
3. Configure redirect URIs:
   - Nuxt: `http://localhost:3000/*`
   - Symfony: `http://localhost:8080/*`
4. Create initial roles and users

### 2. Backend Setup

```bash
# Enter backend container
docker-compose exec backend bash

# Install dependencies
composer install

# Run database migrations
php bin/console doctrine:migrations:migrate

# Load fixtures (development only)
php bin/console doctrine:fixtures:load
```

### 3. Frontend Setup

```bash
# Enter frontend container
docker-compose exec frontend bash

# Install dependencies
npm install

# Start development server (if not already running)
npm run dev
```

## Development Workflow

### Backend Development

1. Make changes to Symfony code in `backend/` directory
2. Code changes are automatically synced via Docker volumes
3. Clear cache if needed:
```bash
docker-compose exec backend php bin/console cache:clear
```

### Frontend Development

1. Make changes to Nuxt code in `frontend/` directory
2. Hot Module Replacement (HMR) automatically updates the browser
3. No restart required for most changes

### Database Management

```bash
# Create new migration
docker-compose exec backend php bin/console make:migration

# Run migrations
docker-compose exec backend php bin/console doctrine:migrations:migrate

# Reset database (development only)
docker-compose exec backend php bin/console doctrine:database:drop --force
docker-compose exec backend php bin/console doctrine:database:create
docker-compose exec backend php bin/console doctrine:migrations:migrate
```

## Docker Commands

### Start services
```bash
docker-compose up -d
```

### Stop services
```bash
docker-compose down
```

### View logs
```bash
# All services
docker-compose logs -f

# Specific service
docker-compose logs -f backend
docker-compose logs -f frontend
docker-compose logs -f keycloak
```

### Rebuild containers
```bash
docker-compose build --no-cache
docker-compose up -d --force-recreate
```

### Clean up
```bash
# Remove containers and networks
docker-compose down

# Remove everything including volumes
docker-compose down -v

# Remove all unused Docker resources
docker system prune -a
```

## Troubleshooting

### Port conflicts
If ports are already in use, modify `.env` file:
```env
FRONTEND_PORT=3001
BACKEND_PORT=8081
KEYCLOAK_PORT=8091
```

### Database connection issues
Check PostgreSQL is running:
```bash
docker-compose ps postgres
docker-compose logs postgres
```

### Keycloak not starting
Increase memory allocation in Docker settings or:
```bash
docker-compose logs keycloak
```

### Frontend can't connect to backend
Verify CORS settings in `backend/.env`:
```env
CORS_ALLOW_ORIGIN='^http://localhost:3000$'
```

## Environment Variables

### Backend (.env)
```env
DATABASE_URL="postgresql://app_user:app_password@postgres:5432/app_db"
KEYCLOAK_URL="http://keycloak:8090"
KEYCLOAK_REALM="app-realm"
KEYCLOAK_CLIENT_ID="symfony-backend"
KEYCLOAK_CLIENT_SECRET="your-client-secret"
```

### Frontend (.env)
```env
NUXT_PUBLIC_API_BASE_URL="http://localhost:8080"
NUXT_PUBLIC_KEYCLOAK_URL="http://localhost:8090"
NUXT_PUBLIC_KEYCLOAK_REALM="app-realm"
NUXT_PUBLIC_KEYCLOAK_CLIENT_ID="nuxt-frontend"
```

## Testing

### Backend Tests
```bash
# Unit tests
docker-compose exec backend php bin/phpunit

# API tests
docker-compose exec backend php bin/console api:test
```

### Frontend Tests
```bash
# Unit tests
docker-compose exec frontend npm run test

# E2E tests
docker-compose exec frontend npm run test:e2e
```

## Production Deployment

See [DEPLOYMENT.md](./DEPLOYMENT.md) for production deployment instructions.