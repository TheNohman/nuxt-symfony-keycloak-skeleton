FROM dunglas/frankenphp

# Installation des dépendances système supplémentaires si nécessaires
RUN apt-get update && apt-get install -y \
    git \
    unzip \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Installation de Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Configuration du répertoire de travail
WORKDIR /app

# Copie des fichiers du projet
COPY . .

# Installation des dépendances
RUN composer install --no-dev --optimize-autoloader

# Création du répertoire des médias avec bonnes permissions
RUN mkdir -p /app/public/media && chmod 777 /app/public/media

# Configuration des permissions
RUN chown -R www-data:www-data /app

# Copie du Caddyfile
COPY Caddyfile /etc/caddy/Caddyfile

# Exposition des ports HTTP, HTTPS et HTTP/3
EXPOSE 80 443 443/udp

# FrankenPHP démarre automatiquement avec le Caddyfile
CMD ["frankenphp", "run", "--config", "/etc/caddy/Caddyfile"]
