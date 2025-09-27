#!/bin/bash
set -e

# This script creates multiple databases in PostgreSQL
# Used to create separate databases for the app and Keycloak

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
    CREATE DATABASE keycloak_db;
    GRANT ALL PRIVILEGES ON DATABASE keycloak_db TO $POSTGRES_USER;
    \c keycloak_db
    GRANT ALL ON SCHEMA public TO $POSTGRES_USER;
EOSQL