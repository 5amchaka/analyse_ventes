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

# Création d'un environnement virtuel
RUN python3 -m venv /venv

# Installation des bibliothèques Python dans l'environnement virtuel
RUN . /venv/bin/activate && pip install --upgrade pip && pip install pandas numpy

# Ajout du dossier /venv/bin au PATH
ENV PATH="/venv/bin:$PATH"

# Création d'un répertoire de travail
WORKDIR /app

# Création des répertoires pour les données et les résultats
RUN mkdir -p /app/data /app/results

# Copie des scripts dans le conteneur
COPY scripts/ /app/scripts/

# Rendre les scripts exécutables
RUN chmod +x /app/scripts/*.sh

# Exposer le port pour l'interaction (facultatif pour cette étape)
EXPOSE 8080

# Commande par défaut pour tester
CMD ["/app/scripts/hello-world.sh"]
