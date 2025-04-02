# -------------------------------------------------------------------
# 🐳 Image finale minimaliste et sécurisée
# -------------------------------------------------------------------
    FROM alpine:3.19

    # 📋 Metadata
    LABEL description="Service d'exécution des scripts d'analyse de ventes"
    LABEL version="2.0"

    # -------------------------------------------------------------------
    # 📦 Dépendances strictement nécessaires
    # -------------------------------------------------------------------
    RUN apk update && \
        apk add --no-cache \
            bash \
            sqlite \
            curl \
            ncurses \
            gettext \
            tini && \
        rm -rf /var/cache/apk/*
    
    # -------------------------------------------------------------------
    # 👤 Création utilisateur non-root (configurable)
    # -------------------------------------------------------------------
    ARG USER_ID=1000
    ARG GROUP_ID=1000
    RUN addgroup -g ${GROUP_ID} appgroup && \
        adduser -D -u ${USER_ID} -G appgroup appuser
    
    # -------------------------------------------------------------------
    # 📁 Structure des répertoires
    # -------------------------------------------------------------------
    WORKDIR /app
    RUN mkdir -p /app/{data,results,database,scripts,sql} && \
        mkdir -p /app/tmp/sql_imports && \
        chown -R appuser:appgroup /app && \
        chown -R appuser:appgroup /app/tmp && \
        chmod -R 755 /app/tmp && \
        chmod -R 770 /app/tmp/sql_imports
    
    # -------------------------------------------------------------------
    # 📂 Copie des fichiers (directe depuis le host)
    # -------------------------------------------------------------------
    COPY --chown=appuser:appgroup services/script-executor/scripts/ /app/scripts/
    COPY --chown=appuser:appgroup init-scripts/init-db.sh /app/scripts/
    COPY --chown=appuser:appgroup sql/ /app/sql/
    COPY --chown=appuser:appgroup .env /app/.env
    
    # -------------------------------------------------------------------
    # 🔐 Permissions
    # -------------------------------------------------------------------
    RUN find /app/scripts -type f -name "*.sh" -exec chmod +x {} \;
        
    # -------------------------------------------------------------------
    # � Configuration runtime
    # -------------------------------------------------------------------
    VOLUME ["/app/database", "/app/data", "/app/results"]
    USER appuser
    ENTRYPOINT ["/sbin/tini", "--"]
    CMD ["/bin/bash", "/app/scripts/run-pipeline.sh"]