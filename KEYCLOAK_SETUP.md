# Configuration Keycloak pour l'authentification OIDC

## Accès à l'interface d'administration

1. Ouvrez votre navigateur et allez à : http://localhost:8090/admin
2. Connectez-vous avec les identifiants par défaut :
   - **Utilisateur** : `admin`
   - **Mot de passe** : `admin123`

## Configuration du realm "skeleton"

### 1. Créer ou vérifier le realm

1. Si le realm "skeleton" n'existe pas déjà, cliquez sur le dropdown en haut à gauche (Master) et cliquez sur "Create Realm"
2. Nommez le realm : `skeleton`
3. Activez le realm

### 2. Configurer le client OIDC

1. Dans le realm "skeleton", allez à **Clients** dans le menu de gauche
2. Cliquez sur **Create client**
3. Configurez le client :
   - **Client type** : `OpenID Connect`
   - **Client ID** : `nuxt-frontend`
   - Cliquez **Next**

4. Configuration des capacités :
   - **Client authentication** : `On` (pour avoir un client secret)
   - **Authorization** : `Off`
   - **Authentication flow** : Cochez `Standard flow` et `Direct access grants`
   - Cliquez **Next**

5. Configuration des URLs :
   - **Root URL** : `http://localhost:3000`
   - **Home URL** : `http://localhost:3000`
   - **Valid redirect URIs** : `http://localhost:3000/api/auth/keycloak`
   - **Valid post logout redirect URIs** : `http://localhost:3000`
   - **Web origins** : `http://localhost:3000`
   - Cliquez **Save**

6. **Important** : Notez le **Client Secret** dans l'onglet **Credentials**
   - Copiez cette valeur et mettez-la à jour dans `/frontend/.env` :
   ```bash
   NUXT_OAUTH_KEYCLOAK_CLIENT_SECRET=votre-client-secret-ici
   ```

### 3. Créer un utilisateur de test

1. Allez à **Users** dans le menu de gauche
2. Cliquez sur **Create new user**
3. Configurez l'utilisateur :
   - **Username** : `testuser`
   - **Email** : `test@example.com`
   - **First name** : `Test`
   - **Last name** : `User`
   - **Email verified** : `Yes`
   - **Enabled** : `Yes`
   - Cliquez **Create**

4. Définir le mot de passe :
   - Allez dans l'onglet **Credentials**
   - Cliquez **Set password**
   - **Password** : `testpass`
   - **Password confirmation** : `testpass`
   - **Temporary** : `Off` (pour éviter de devoir changer le mot de passe)
   - Cliquez **Save**

## Vérification de la configuration

### Variables d'environnement finales

Assurez-vous que votre fichier `/frontend/.env` contient :

```bash
NUXT_SESSION_PASSWORD=435faf74e6f04fc0baf3050b40a3b83a

# Keycloak OAuth configuration
NUXT_OAUTH_KEYCLOAK_CLIENT_ID=nuxt-frontend
NUXT_OAUTH_KEYCLOAK_CLIENT_SECRET=[votre-client-secret-obtenu-dans-keycloak]
NUXT_OAUTH_KEYCLOAK_SERVER_URL=http://localhost:8090
NUXT_OAUTH_KEYCLOAK_REALM=skeleton

# Public URLs
NUXT_PUBLIC_KEYCLOAK_URL=http://localhost:8090
```

### Test de la configuration

1. Démarrez votre application Nuxt :
   ```bash
   docker compose up -d
   ```

2. Ouvrez http://localhost:3000

3. Cliquez sur "Se connecter"

4. Vous devriez être redirigé vers Keycloak

5. Connectez-vous avec :
   - **Utilisateur** : `testuser`
   - **Mot de passe** : `testpass`

6. Après connexion, vous devriez être redirigé vers l'application avec vos informations de profil affichées

## URLs importantes

- **Application Nuxt** : http://localhost:3000
- **Admin Keycloak** : http://localhost:8090/admin
- **Realm Keycloak** : http://localhost:8090/realms/skeleton
- **OIDC Configuration** : http://localhost:8090/realms/skeleton/.well-known/openid_configuration

## Dépannage

### Erreur de redirection
- Vérifiez que les URLs de redirection dans Keycloak correspondent exactement
- Assurez-vous que le client secret est correct

### Erreur de CORS
- Vérifiez que les "Web origins" sont configurées dans Keycloak
- Assurez-vous que le realm est activé

### Token invalide
- Vérifiez que les scopes `openid profile email` sont disponibles
- Redémarrez l'application après avoir modifié les variables d'environnement