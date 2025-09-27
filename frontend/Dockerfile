FROM node:20-alpine

# Install dependencies for development
RUN apk add --no-cache curl

# Set working directory
WORKDIR /app

# Copy entrypoint script
COPY docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

# Expose port
EXPOSE 3000

# Environment variables for development
ENV HOST=0.0.0.0
ENV PORT=3000
ENV NODE_ENV=development

# Entrypoint
ENTRYPOINT ["docker-entrypoint.sh"]