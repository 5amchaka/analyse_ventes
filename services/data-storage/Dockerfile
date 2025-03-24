# -------------------------------------------------------------------
# 🗄️ Service de stockage de données SQLite
# -------------------------------------------------------------------
  FROM alpine:3.19

  # 📦 Installation des dépendances
  RUN apk update && \
      apk add --no-cache \
          sqlite \
          sudo && \
      rm -rf /var/cache/apk/*
  
  # 👤 Création de l'utilisateur non-root (configurable)
  ARG USER_ID=1000
  ARG GROUP_ID=1000
  
  RUN addgroup -g ${GROUP_ID} dbgroup && \
      adduser -D -u ${USER_ID} -G dbgroup dbuser && \
      echo 'dbuser ALL=(ALL) NOPASSWD: /bin/chown, /bin/mkdir' >> /etc/sudoers
  
  # 📁 Préparation de l'environnement
  WORKDIR /app
  RUN mkdir -p /app && \
      chown dbuser:dbgroup /app
  
  # 📂 Copie des fichiers
  COPY --chown=dbuser:dbgroup services/data-storage/entrypoint.sh /entrypoint.sh
  RUN chmod +x /entrypoint.sh
  
  # 🗃️ Configuration des volumes
  VOLUME /app/database
  
  # 🚀 Configuration runtime
  USER dbuser
  ENTRYPOINT ["/entrypoint.sh"]