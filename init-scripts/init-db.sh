#!/bin/bash
# init-db.sh - Initialisation de la base de données

source /app/scripts/logging.sh



# --- Initialisation de la base de données ---
log_header "Initialisation SQLite"
log_header "Configuration:"
log_info "- Date: $(date)"
log_info "- SQLite version: $(sqlite3 --version)"
log_info "- Chemin DB: $DB_PATH"


# Chargement environnement
source /app/scripts/env-loader.sh

# Configuration SQLite optimisée
log_header "Configuration des paramètres SQLite"
{
    echo "PRAGMA journal_mode=WAL;" 
    echo "PRAGMA synchronous=NORMAL;"
    echo "PRAGMA foreign_keys=ON;"
    echo "PRAGMA busy_timeout=5000;"
} | sqlite3 "$DB_PATH" || {
    log_error "Échec de la configuration SQLite"
    exit 1
}

# Vérification du schéma SQL
if [ ! -f "$SCHEMA_FILE" ]; then
    log_error "Fichier de schéma introuvable: $SCHEMA_FILE"
    exit 1
fi

# Exécution du schéma avec gestion d'erreur
log_info "Application du schéma de base de données"
if ! sqlite3 -bail "$DB_PATH" < "$SCHEMA_FILE"; then
    log_error "Erreur lors de l'application du schéma"
    echo "Dernière erreur SQLite:"
    sqlite3 "$DB_PATH" "SELECT message FROM sqlite_master WHERE type='error' ORDER BY rowid DESC LIMIT 1;"
    exit 1
fi

# Vérification finale
log_info "Vérification de la structure"
TABLES=$(sqlite3 "$DB_PATH" ".tables")

if [[ -z "$TABLES" ]]; then
    log_error "Aucune table créée - schéma probablement vide"
    exit 1
fi

log_success "Structure créée avec succès"
log_header "Tables disponibles:"

# Nouvelle version robuste
sqlite3 "$DB_PATH" <<EOF | grep -v '^$'
SELECT name 
FROM sqlite_master 
WHERE type='table'
AND name NOT LIKE 'sqlite_%' 
ORDER BY name;
EOF

# Statistiques (debug)
if [ "${DEBUG:-0}" = "1" ]; then
    log_info "Debug - Détails des tables:"
    sqlite3 "$DB_PATH" <<EOF
SELECT 
    name as table_name, 
    sql as definition 
FROM sqlite_master 
WHERE type='table';
EOF
fi