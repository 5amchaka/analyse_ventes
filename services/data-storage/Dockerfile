FROM alpine:3.19

# Utiliser des labels pour la documentation
LABEL description="Service de stockage de données SQLite optimisé"
LABEL version="1.0"

# Installation minimale : uniquement SQLite
RUN apk update && \
    apk add --no-cache sqlite && \
    rm -rf /var/cache/apk/*

# Préparer le répertoire de travail
WORKDIR /app

# Créer le répertoire pour la base de données
RUN mkdir -p /app/database

# Exposer un volume pour la persistance des données
VOLUME /app/database

# Script d'entrée pour le conteneur
COPY services/data-storage/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Vérification de l'état de santé
HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
  CMD sqlite3 --version || exit 1

# Point d'entrée
ENTRYPOINT ["/entrypoint.sh"]