#!/bin/bash

source /app/scripts/common.sh

main() {
    log_header "Hello données de ventes"
    log_header "Informations système"
    echo "- Date et heure: $(date -u +'%Y-%m-%dT%H:%M:%SZ')"
    log_info "- SQLite version: $(sqlite3 --version | head -n1)"
    
}

error_handler() {
    log_error "Erreur ligne $1"
    exit 1
}

trap 'error_handler $LINENO' ERR
set -euo pipefail

main "$@"

# Chargement environnement
set -eo pipefail
source /app/scripts/env-loader.sh || {
    log_error "Échec du chargement de l'environnement"
    exit 1
}

# Vérification base de données
if [ ! -f "$DB_PATH" ]; then
    log_error "Base de données non trouvée à $DB_PATH"
    log_info "Veuillez exécuter init-db.sh en premier"
    exit 1
fi

# Vérification structure
required_tables=("Produits" "Magasins" "Ventes")
missing_tables=()

for table in "${required_tables[@]}"; do
    if ! sqlite3 "$DB_PATH" "SELECT name FROM sqlite_master WHERE type='table' AND name='$table';" | grep -q "$table"; then
        missing_tables+=("$table")
    fi
done

if [ ${#missing_tables[@]} -gt 0 ]; then
    log_error "Tables manquantes: ${missing_tables[*]}"
    exit 1
fi

function download_file() {
    local url=$1 file=$2 label=$3
    local max_retries=3 retry_count=0 timeout=30

    # Normalisation de l'URL
    [[ "$url" =~ ^https?:// ]] || url="https://$url"

    log_info "Début du téléchargement: $label"
    echo "Source: ${url##*/}"
    echo "Destination: $file"

    while [ $retry_count -lt $max_retries ]; do
        if curl -sS -L --fail \
           --connect-timeout $timeout \
           --max-time $((timeout * 2)) \
           "$url" -o "$file.tmp"; then
            
            if [ -s "$file.tmp" ]; then
                mv "$file.tmp" "$file"
                log_success "Téléchargement réussi"
                echo "Taille: $(du -h "$file" | cut -f1)"
                return 0
            else
                log_warning "Fichier vide reçu"
            fi
        fi

        ((retry_count++))
        timeout=$((timeout + 10)) # Augmentation progressive
        log_warning "Nouvelle tentative dans $((retry_count * 2)) secondes..."
        sleep $((retry_count * 2))
    done

    log_error "Échec définitif du téléchargement"
    return 1
}

log_header "Téléchargement des données"
mkdir -p "$DATA_DIR"

# Liste des fichiers à télécharger
downloads=(
    "$URL_PRODUITS:$DATA_DIR/$PRODUITS_FILE:produits"
    "$URL_MAGASINS:$DATA_DIR/$MAGASINS_FILE:magasins"
    "$URL_VENTES:$DATA_DIR/$VENTES_FILE:ventes"
)

pids=()
for item in "${downloads[@]}"; do
    IFS=':' read -r url file label <<< "$item"
    download_file "$url" "$file" "$label" &
    pids+=($!)
done

# Attente avec gestion d'erreur
for pid in "${pids[@]}"; do
    if ! wait "$pid"; then
        log_error "Un téléchargement a échoué"
        exit 1
    fi
done

# Validation des fichiers
for item in "${downloads[@]}"; do
    IFS=':' read -r _ file _ <<< "$item"
    if [ ! -s "$file" ]; then
        log_error "Fichier vide ou manquant: $(basename "$file")"
        exit 1
    fi
done

# Importation SQL avec vérification
log_header "Importation des données"
if [ ! -f "$IMPORT_SQL" ]; then
    log_error "Script SQL d'importation manquant: $IMPORT_SQL"
    exit 1
fi

if ! sqlite3 -bail "$DB_PATH" < "$IMPORT_SQL" 2>/tmp/sqlite_errors; then
    log_error "Échec de l'importation SQL"
    [ -s /tmp/sqlite_errors ] && log_info "Détails:\n$(cat /tmp/sqlite_errors)"
    exit 1
fi
rm -f /tmp/sqlite_errors

# Vérification finale améliorée
log_header "Vérification des données"
echo -e "\033[1;37mStatistiques d'importation:\033[0m"

# Requête unique plus robuste
results=$(sqlite3 -header -column "$DB_PATH" <<EOF
.mode column
.headers on
SELECT 
    'Produits' as Tableau,
    COUNT(*) as "Nb entrées" 
FROM Produits
UNION ALL
SELECT 
    'Magasins',
    COUNT(*)
FROM Magasins
UNION ALL
SELECT 
    'Ventes',
    COUNT(*)
FROM Ventes;
EOF
)

# Affichage avec formatage natif SQLite
echo "$results"