# Nuxt + Symfony + Keycloak Full Stack Application

A modern full-stack application with Backend for Frontend (BFF) architecture, featuring:
- **Frontend**: Nuxt 3 with Nuxt UI (BFF pattern)
- **Backend**: Symfony 7 with API Platform on FrankenPHP
- **Authentication**: Keycloak for identity management
- **Database**: PostgreSQL
- **Cache**: Redis

## Architecture

This project implements a Backend for Frontend (BFF) pattern where:
- All browser requests go through the Nuxt server
- The Nuxt server makes server-to-server API calls to Symfony
- Authentication tokens are managed server-side for enhanced security
- No direct communication between browser and backend API

## Quick Start

### Prerequisites

- Docker and Docker Compose installed
- Git
- 4GB RAM minimum

### 1. Clone and Setup

```bash
# Clone the repository
git clone <repository-url>
cd nuxt-symfony-keycloak-skeleton
```

### 2. Start Docker Services

```bash
# Start all services
docker-compose up -d

# Watch logs (optional)
docker-compose logs -f
```

First startup will take 5-10 minutes as it:
- Downloads Docker images
- Initializes Symfony with API Platform
- Sets up Nuxt with UI libraries
- Configures Keycloak
- Creates databases

### 3. Access Applications

Once running, access:

- **Frontend**: http://localhost:3000
- **API Documentation**: http://localhost:8080/api
- **Keycloak Admin**: http://localhost:8090/admin
  - Username: `admin`
  - Password: `admin123`

### 4. Configure Keycloak

1. Access Keycloak admin console
2. Create a new realm: `skeleton`
3. Create two clients:
   - `nuxt-frontend` (Public client)
   - `symfony-backend` (Confidential client)
4. Create a test user

## Development

### Backend Development (Symfony)

```bash
# Enter backend container
docker-compose exec backend bash

# Create entity
php bin/console make:entity

# Generate migration
php bin/console make:migration

# Run migrations
php bin/console doctrine:migrations:migrate

# Clear cache
php bin/console cache:clear
```

### Frontend Development (Nuxt)

```bash
# Enter frontend container
docker-compose exec frontend bash

# Install new package
npm install package-name

# Generate component
npx nuxi add component ComponentName

# Generate page
npx nuxi add page pagename
```

### Database Access

```bash
# Connect to PostgreSQL
docker-compose exec postgres psql -U app_user -d app_db
```

## Project Structure

```
├── backend/              # Symfony API (FrankenPHP)
│   ├── src/             # PHP source code
│   ├── config/          # Configuration files
│   └── public/          # Public directory
├── frontend/            # Nuxt 3 BFF
│   ├── pages/          # Application pages
│   ├── components/     # Vue components
│   ├── composables/    # Composable functions
│   └── server/         # Server-side API routes (BFF)
├── docker/             # Docker configuration
│   └── postgres/      # Database init scripts
├── docs/              # Documentation
│   ├── ARCHITECTURE.md
│   ├── API.md
│   ├── SETUP.md
│   └── DEPLOYMENT.md
└── docker-compose.yml  # Docker orchestration
```

## Technology Stack

### Backend
- **Symfony 7.1** - PHP framework
- **API Platform 3** - REST/GraphQL API
- **FrankenPHP** - Modern PHP application server
- **Doctrine ORM** - Database abstraction
- **JWT Authentication** - Secure API access

### Frontend
- **Nuxt 3** - Vue.js framework with SSR
- **Nuxt UI** - Component library
- **Tailwind CSS** - Utility-first CSS
- **Pinia** - State management
- **TypeScript** - Type safety

### Infrastructure
- **Keycloak** - Identity and access management
- **PostgreSQL 16** - Primary database
- **Redis 7** - Caching and sessions
- **Docker** - Containerization

## Common Commands

### Docker Management

```bash
# Start services
docker-compose up -d

# Stop services
docker-compose down

# Rebuild after changes
docker-compose build --no-cache
docker-compose up -d --force-recreate

# View logs
docker-compose logs -f [service-name]

# Remove everything (including data)
docker-compose down -v
```

### Troubleshooting

```bash
# Check service status
docker-compose ps

# Enter container shell
docker-compose exec [service-name] bash

# Reset database
docker-compose exec backend php bin/console doctrine:database:drop --force
docker-compose exec backend php bin/console doctrine:database:create
docker-compose exec backend php bin/console doctrine:migrations:migrate
```

## Environment Variables

Key environment variables are defined in `docker-compose.yml`:

- `KEYCLOAK_ADMIN` - Keycloak admin username (admin)
- `KEYCLOAK_ADMIN_PASSWORD` - Keycloak admin password (admin123)
- `APP_SECRET` - Symfony application secret
- `NUXT_SESSION_SECRET` - Session encryption key
- `DATABASE_URL` - PostgreSQL connection string
- `KEYCLOAK_REALM` - Authentication realm (skeleton)

## Security

- All API requests go through Nuxt BFF layer
- JWT tokens managed server-side only
- HTTPS required in production
- CORS configured for local development
- Session cookies with httpOnly flag

## Contributing

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## License

[Your License]

## Support

For issues and questions:
- Check [docs/](./docs) directory for detailed documentation
- Open an issue on GitHub
- Contact the development team

## Production Deployment

See [docs/DEPLOYMENT.md](./docs/DEPLOYMENT.md) for production deployment instructions.