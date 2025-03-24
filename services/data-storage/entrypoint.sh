#!/bin/sh
set -euo pipefail

# -------------------------------------------------------------------
# 🛠️ Initialisation de l'environnement
# -------------------------------------------------------------------

# Vérification et création du répertoire de la base de données
if [ ! -d "/app/database" ]; then
    echo "Création du répertoire /app/database..."
    sudo mkdir -p /app/database
    sudo chown dbuser:dbgroup /app/database
fi

# -------------------------------------------------------------------
# 🗄 Initialisation de la base de données
# -------------------------------------------------------------------
if [ ! -f "/app/database/test.db" ]; then
    echo "Initialisation de la nouvelle base de données..."
    if ! sqlite3 /app/database/test.db "VACUUM;"; then
        echo "Correction des permissions et nouvelle tentative..."
        sudo chown -R dbuser:dbgroup /app/database
        sqlite3 /app/database/test.db "VACUUM;" || {
            echo "ERREUR: Échec de l'initialisation de la base de données"
            exit 1
        }
    fi
fi

# -------------------------------------------------------------------
# 🔍 Vérification des permissions
# -------------------------------------------------------------------
if ! touch /app/database/test.tmp 2>/dev/null; then
    echo "ERREUR: Impossible d'écrire dans /app/database!"
    echo "Permissions actuelles :"
    ls -ld /app/database
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
==============================
EOF

exec tail -f /dev/null