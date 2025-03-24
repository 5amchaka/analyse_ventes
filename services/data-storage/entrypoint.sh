#!/bin/sh
set -euo pipefail

# -------------------------------------------------------------------
# 🛠️ Initialisation de l'environnement
# -------------------------------------------------------------------

# Vérification et création du répertoire de la base de données
if [ ! -d "/app/database" ]; then
    echo "Création du répertoire /app/database..."
    mkdir -p /app/database
    if [ "$(id -u)" = "0" ]; then
        chown dbuser:dbgroup /app/database
    fi
fi

# -------------------------------------------------------------------
# 🗄 Initialisation de la base de données
# -------------------------------------------------------------------
if [ ! -f "/app/database/test.db" ]; then
    echo "Initialisation de la nouvelle base de données..."
    
    # Premier essai
    if ! sqlite3 /app/database/test.db "VACUUM;"; then
        echo "Correction des permissions et nouvelle tentative..."
        
        # Correction des permissions (seulement si root)
        if [ "$(id -u)" = "0" ]; then
            chown -R dbuser:dbgroup /app/database
        fi
        
        # Deuxième essai
        if ! sqlite3 /app/database/test.db "VACUUM;"; then
            echo "ERREUR: Échec de l'initialisation de la base de données"
            echo "Détail des permissions :"
            ls -ldn /app/database
            exit 1
        fi
    fi
fi

# -------------------------------------------------------------------
# 🔍 Vérification des permissions
# -------------------------------------------------------------------
if ! touch /app/database/test.tmp 2>/dev/null; then
    echo "ERREUR CRITIQUE: Impossible d'écrire dans /app/database!"
    echo "État des permissions :"
    ls -ldn /app/database
    echo "Utilisateur effectif : $(id -un) ($(id -u))"
    exit 1
fi
rm -f /app/database/test.tmp

# -------------------------------------------------------------------
# 🩹 Healthcheck
# -------------------------------------------------------------------
if [ "${1:-}" = "healthcheck" ]; then
    if ! sqlite3 /app/database/test.db "PRAGMA integrity_check;"; then
        echo "ERREUR: Échec du healthcheck"
        exit 1
    fi
    exit 0
fi

# -------------------------------------------------------------------
# 🚀 Démarrage du service
# -------------------------------------------------------------------
cat <<EOF
=== SQLite Storage Service ===
Version: $(sqlite3 --version)
User: $(id -un) ($(id -u)):$(id -gn) ($(id -g))
Database: /app/database/test.db
Status: Prêt
Permissions: $(stat -c "%A %U:%G" /app/database)
==============================
EOF

exec tail -f /dev/null