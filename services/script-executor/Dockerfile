# -------------------------------------------------------------------
# 🐳 Image finale minimaliste et sécurisée
# -------------------------------------------------------------------
    FROM alpine:3.19

    # 📋 Metadata
    LABEL maintainer="VotreÉquipe"
    LABEL description="Service d'exécution des scripts d'analyse de ventes"
    LABEL version="1.0"
    
    # 📦 Dépendances strictement nécessaires
    RUN apk update && \
        apk add --no-cache \
            bash \
            sqlite \
            curl \
            ncurses \
            tini && \
        rm -rf /var/cache/apk/*
    
    # 👤 Création utilisateur non-root (configurable)
    ARG USER_ID=1001
    ARG GROUP_ID=1001
    RUN addgroup -g ${GROUP_ID} appgroup && \
        adduser -D -u ${USER_ID} -G appgroup appuser
    
    # 📁 Structure des répertoires
    WORKDIR /app
    RUN mkdir -p /app/{data,results,database,scripts} && \
        chown -R appuser:appgroup /app
    
    # 📂 Copie des fichiers (directe depuis le host)
    COPY --chown=appuser:appgroup services/script-executor/scripts/ /app/scripts/
    COPY --chown=appuser:appgroup init-scripts/ /app/scripts/
    COPY --chown=appuser:appgroup sql/ /app/scripts/
    COPY --chown=appuser:appgroup services/script-executor/scripts/env-loader.sh /app/
    
    # 🔐 Permissions
    RUN chmod +x /app/env-loader.sh && \
        find /app/scripts -type f -name "*.sh" -exec chmod +x {} \;
    
    # 🩹 Healthcheck
    HEALTHCHECK --interval=30s --timeout=3s \
      CMD pgrep -f start-service.sh || exit 1
    
    # 📡 Configuration runtime
    VOLUME ["/app/database", "/app/data", "/app/results"]
    EXPOSE 8080
    USER appuser
    ENTRYPOINT ["/sbin/tini", "--"]
    CMD ["/app/scripts/start-service.sh"]