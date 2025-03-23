# Utilisation de multi-stage build pour une image finale minimale

# Stage 1: Image de construction 
FROM alpine:3.19 as builder

# Copier uniquement les fichiers nécessaires pour la validation
COPY services/script-executor/scripts/ /scripts/
COPY init-scripts/ /init-scripts/
COPY sql/ /sql/

# Stage 2: Image finale minimale
FROM alpine:3.19

# Utiliser des labels pour la documentation
LABEL description="Service d'exécution des scripts d'analyse de ventes"
LABEL version="1.0"

# Installation des dépendances strictement nécessaires
# Analyse du code: sqlite pour les requêtes, bash pour les scripts, curl pour les téléchargements
RUN apk update && \
    apk add --no-cache \
        bash \
        sqlite \
        curl \
        ncurses && \
    rm -rf /var/cache/apk/*

# Définir le répertoire de travail principal
WORKDIR /app

# Création des répertoires nécessaires
RUN mkdir -p /app/data /app/results /app/database /app/scripts

# Copier les scripts et les fichiers SQL depuis le builder
COPY --from=builder /scripts/ /app/scripts/
COPY --from=builder /init-scripts/ /app/scripts/
COPY --from=builder /sql/ /app/scripts/

# Copier le script de chargement des variables d'environnement
COPY services/script-executor/scripts/env-loader.sh /app/env-loader.sh

# Rendre les scripts exécutables
RUN chmod +x /app/env-loader.sh && \
    chmod +x /app/scripts/*.sh

# Exposer les volumes pour les données persistantes
VOLUME ["/app/database", "/app/data", "/app/results"]

# Exposer un port pour une éventuelle API future
EXPOSE 8080

# Définir l'entrée par défaut du conteneur
ENTRYPOINT ["/bin/bash"]
CMD ["/app/scripts/start-service.sh"]