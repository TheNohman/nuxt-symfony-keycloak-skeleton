# FrankenPHP container for Symfony application
FROM dunglas/frankenphp:1-php8.3

# Install additional PHP extensions needed for Symfony
RUN install-php-extensions \
    pdo_pgsql \
    intl \
    opcache \
    redis \
    zip

# Install Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Create non-root user
RUN groupadd -g 1000 appuser && \
    useradd -r -u 1000 -g appuser appuser

# Set working directory
WORKDIR /app

# Copy application files
COPY --chown=appuser:appuser . /app

# Change ownership of the working directory
RUN chown -R appuser:appuser /app

# Switch to non-root user
USER appuser

# Expose port 80 for FrankenPHP
EXPOSE 80

# Copy Caddyfile
COPY --chown=appuser:appuser Caddyfile /etc/caddy/Caddyfile

# Start FrankenPHP server
CMD ["frankenphp", "run", "--config", "/etc/caddy/Caddyfile"]