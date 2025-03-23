# Utilisation d'Alpine Linux comme base légère avec bash
FROM alpine:latest

# Installation des dépendances nécessaires
RUN apk update && \
    apk add --no-cache \
    bash \
    sqlite \
    python3 \
    py3-pip \
    py3-virtualenv \
    curl

# Création d'un environnement virtuel Python
RUN python3 -m venv /venv

# Installation des bibliothèques Python dans l'environnement virtuel
# Important : utilisation de '&&' pour que l'environnement reste activé pendant la ligne
RUN /venv/bin/pip install --upgrade pip && \
    /venv/bin/pip install pandas numpy

# Ajout du dossier /venv/bin au PATH global
ENV PATH="/venv/bin:$PATH"

# Définir le répertoire de travail principal
WORKDIR /app

# Création des répertoires pour les données et les résultats
RUN mkdir -p /app/data /app/results /app/database /app/scripts

# Copie des scripts shell et SQL (depuis le contexte de build)
COPY ../../init-scripts/init-db.sh /app/scripts/init-db.sh
COPY ../../init-scripts/schema.sql /app/scripts/schema.sql

# Rendre les scripts exécutables
RUN chmod +x /app/scripts/*.sh

# Exposer un port si une API ou un service est exposé (optionnel ici)
EXPOSE 8080

# Commande par défaut : exécution du script de test ou d'init
CMD ["/app/scripts/init-db.sh"]
