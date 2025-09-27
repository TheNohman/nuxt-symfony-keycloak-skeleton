#!/bin/sh
set -e

# Check if Nuxt project is initialized
if [ ! -f "package.json" ] || ! grep -q "nuxt" package.json; then
    echo "Initializing Nuxt 3 project..."
    npx nuxi@latest init . --force --packageManager npm

    # Install Nuxt UI and required dependencies
    npm install @nuxt/ui

    # Install authentication and session packages
    npm install @sidebase/nuxt-auth

    # Install utilities
    npm install @pinia/nuxt pinia
    npm install @vueuse/nuxt
    npm install ofetch
fi

# Install dependencies if node_modules doesn't exist
if [ ! -d "node_modules" ]; then
    npm install
fi

# Start development server
npm run dev -- --host 0.0.0.0