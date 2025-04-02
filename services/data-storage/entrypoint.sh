#!/bin/sh
set -euo pipefail

# -------------------------------------------------------------------
# 🛠️ Initialisation de l'environnement
# -------------------------------------------------------------------

# Le répertoire /app/database est créé par le montage du volume Docker.
# L'initialisation est gérée par le service script-executor.
# L'initialisation de la base de données (création du fichier et du schéma)
# est gérée par le script init-db.sh dans le conteneur script-executor.

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
    if ! sqlite3 "/app/database/${SQLITE_DB_NAME:-test.db}" "PRAGMA integrity_check;"; then
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
Database: /app/database/${SQLITE_DB_NAME:-test.db}
Status: Prêt
Permissions: $(stat -c "%A %U:%G" /app/database)
==============================
EOF

exec tail -f /dev/null