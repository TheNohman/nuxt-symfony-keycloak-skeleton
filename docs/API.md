# API Documentation

## Overview

The Symfony backend provides a RESTful API built with API Platform, offering automatic OpenAPI documentation, pagination, filtering, and validation.

## Base URL

- Development: `http://localhost:8080/api`
- Production: `https://api.yourdomain.com`

## Authentication

All API endpoints (except public ones) require JWT authentication via Bearer token.

### Request Headers
```http
Authorization: Bearer <jwt-token>
Content-Type: application/json
```

### Obtaining Tokens

Tokens are obtained through Keycloak OIDC flow. The frontend handles this automatically.

## API Endpoints

### Core Resources

#### Users
```
GET    /api/users          - List all users (admin only)
GET    /api/users/{id}     - Get user details
PUT    /api/users/{id}     - Update user
DELETE /api/users/{id}     - Delete user (admin only)
```

#### Example User Resource
```json
{
  "@context": "/api/contexts/User",
  "@id": "/api/users/1",
  "@type": "User",
  "id": 1,
  "email": "user@example.com",
  "firstName": "John",
  "lastName": "Doe",
  "roles": ["ROLE_USER"],
  "createdAt": "2024-01-01T00:00:00+00:00",
  "updatedAt": "2024-01-01T00:00:00+00:00"
}
```

### Pagination

API Platform provides automatic pagination:

```
GET /api/users?page=1&itemsPerPage=30
```

Response includes pagination metadata:
```json
{
  "@context": "/api/contexts/User",
  "@id": "/api/users",
  "@type": "hydra:Collection",
  "hydra:member": [...],
  "hydra:totalItems": 100,
  "hydra:view": {
    "@id": "/api/users?page=1",
    "@type": "hydra:PartialCollectionView",
    "hydra:first": "/api/users?page=1",
    "hydra:last": "/api/users?page=4",
    "hydra:next": "/api/users?page=2"
  }
}
```

### Filtering

Built-in filters for searching and filtering:

```
GET /api/users?email=john@example.com
GET /api/users?firstName=John
GET /api/users?order[createdAt]=desc
```

### Error Responses

API Platform provides standardized error responses:

#### 400 Bad Request
```json
{
  "@context": "/api/contexts/Error",
  "@type": "hydra:Error",
  "hydra:title": "An error occurred",
  "hydra:description": "Invalid input provided",
  "violations": [
    {
      "propertyPath": "email",
      "message": "This value is not a valid email address."
    }
  ]
}
```

#### 401 Unauthorized
```json
{
  "@context": "/api/contexts/Error",
  "@type": "hydra:Error",
  "hydra:title": "An error occurred",
  "hydra:description": "JWT Token not found"
}
```

#### 403 Forbidden
```json
{
  "@context": "/api/contexts/Error",
  "@type": "hydra:Error",
  "hydra:title": "An error occurred",
  "hydra:description": "Access Denied."
}
```

#### 404 Not Found
```json
{
  "@context": "/api/contexts/Error",
  "@type": "hydra:Error",
  "hydra:title": "An error occurred",
  "hydra:description": "Not Found"
}
```

## OpenAPI Documentation

API Platform automatically generates OpenAPI (Swagger) documentation:

- **Swagger UI**: http://localhost:8080/api
- **OpenAPI JSON**: http://localhost:8080/api/docs.json
- **JSON-LD Context**: http://localhost:8080/api/contexts/{Entity}

## GraphQL Support (Optional)

If enabled, GraphQL endpoint is available at:

- **GraphQL Endpoint**: http://localhost:8080/api/graphql
- **GraphiQL IDE**: http://localhost:8080/api/graphql/graphiql

Example GraphQL query:
```graphql
query {
  users {
    edges {
      node {
        id
        email
        firstName
        lastName
      }
    }
  }
}
```

## Rate Limiting

API implements rate limiting per IP address:

- Default: 100 requests per minute
- Authenticated: 1000 requests per minute

Rate limit headers in response:
```http
X-RateLimit-Limit: 100
X-RateLimit-Remaining: 99
X-RateLimit-Reset: 1640995200
```

## Webhooks

For real-time updates, webhook subscriptions can be configured:

```json
POST /api/webhooks
{
  "url": "https://your-app.com/webhook",
  "events": ["user.created", "user.updated"],
  "secret": "your-webhook-secret"
}
```

## Testing API Endpoints

### Using cURL
```bash
# Get token from Keycloak
TOKEN=$(curl -X POST http://localhost:8090/realms/app-realm/protocol/openid-connect/token \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=password" \
  -d "client_id=symfony-backend" \
  -d "username=testuser" \
  -d "password=password" | jq -r '.access_token')

# Make API request
curl -H "Authorization: Bearer $TOKEN" \
     -H "Content-Type: application/json" \
     http://localhost:8080/api/users
```

### Using Postman

1. Import OpenAPI spec from http://localhost:8080/api/docs.json
2. Configure OAuth 2.0 authentication with Keycloak
3. Test endpoints with automatic token refresh

## Custom Endpoints

### Health Check
```
GET /api/health

Response:
{
  "status": "healthy",
  "timestamp": "2024-01-01T00:00:00+00:00",
  "services": {
    "database": "connected",
    "keycloak": "connected",
    "redis": "connected"
  }
}
```

### Statistics
```
GET /api/stats

Response:
{
  "users": {
    "total": 1000,
    "active": 850,
    "new_this_month": 50
  }
}
```

## API Versioning

API versioning is handled via URL path:

- v1: `/api/v1/*` (current)
- v2: `/api/v2/*` (future)

Deprecation notices are included in response headers:
```http
Sunset: Sat, 31 Dec 2024 23:59:59 GMT
Deprecation: true
Link: </api/v2/users>; rel="successor-version"
```