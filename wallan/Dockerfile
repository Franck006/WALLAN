# Utiliser une image officielle de Node.js
FROM node:24-alpine

# Définir le dossier de travail dans le conteneur
WORKDIR /app

# Copier les fichiers de dépendances
COPY package.json package-lock.json ./

# Installer les dépendances
RUN npm ci

# Copier le code source
COPY . .

# Exposer le port de Next.js
EXPOSE 3000

# Démarrer le serveur Next.js en mode développement
CMD ["npm", "run", "dev", "--", "--hostname", "0.0.0.0"]
