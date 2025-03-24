# -------------------------------------------------------------------
# 🗄️ Service de stockage de données SQLite (Version sécurisée)
# -------------------------------------------------------------------
  FROM alpine:3.19

  # -------------------------------------------------------------------
  # 📦 Installation des dépendances minimales
  # -------------------------------------------------------------------
  RUN apk update && \
      apk add --no-cache \
          sqlite \
          tini && \
      rm -rf /var/cache/apk/*
  
  # -------------------------------------------------------------------
  # 👤 Création de l'utilisateur non-root
  # -------------------------------------------------------------------
  ARG USER_ID=1000
  ARG GROUP_ID=1000
  
  RUN addgroup -g ${GROUP_ID} dbgroup && \
      adduser -D -u ${USER_ID} -G dbgroup dbuser
  
  # -------------------------------------------------------------------
  # 📁 Configuration de l'environnement
  # -------------------------------------------------------------------
  WORKDIR /app
  
  # Création des répertoires avec permissions sécurisées
  RUN mkdir -p /app/database && \
      chown -R dbuser:dbgroup /app && \
      chmod 755 /app && \
      chmod 700 /app/database  # Sécurité renforcée pour le volume
  
  # -------------------------------------------------------------------
  # 📂 Copie des fichiers
  # -------------------------------------------------------------------
  COPY --chown=dbuser:dbgroup services/data-storage/entrypoint.sh /entrypoint.sh
  RUN chmod 750 /entrypoint.sh  # rx pour l'utilisateur, aucun droit pour les autres
  
  # -------------------------------------------------------------------
  # 🗃️ Configuration des volumes
  # -------------------------------------------------------------------
  VOLUME /app/database
  
  # -------------------------------------------------------------------
  # 🚀 Configuration runtime
  # -------------------------------------------------------------------
  USER dbuser
  ENTRYPOINT ["/sbin/tini", "--", "/entrypoint.sh"]