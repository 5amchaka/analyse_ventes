#!/bin/bash

source /app/scripts/logging.sh

error_handler() {
    log_error "Erreur ligne $1"
    exit 1
}

trap 'error_handler $LINENO' ERR
set -euo pipefail

# Fonction de téléchargement robuste
function download_file() {
    local url=$1 file=$2 label=$3
    local max_retries=3 retry_count=0 timeout=30

    # Normalisation de l'URL
    [[ "$url" =~ ^https?:// ]] || url="https://$url"

    log_info "Début du téléchargement: $label"
    log_verbose "Source: ${url}" # Affichage URL complète en verbose
    log_verbose "Destination: $file"

    while [ $retry_count -lt $max_retries ]; do
        if curl -sS -L --fail \
           --connect-timeout $timeout \
           --max-time $((timeout * 2)) \
           "$url" -o "$file.tmp"; then
            
            if [ -s "$file.tmp" ]; then
                mv "$file.tmp" "$file"
                log_success "Téléchargement réussi: $(basename "$file")"
                log_verbose "Taille: $(du -h "$file" | cut -f1)"
                return 0
            else
                log_warning "Fichier vide reçu pour $label"
                rm -f "$file.tmp" # Nettoyer le fichier vide
            fi
        else
             log_warning "Échec temporaire du téléchargement pour $label (curl exit code: $?)"
        fi

        ((retry_count++))
        local sleep_time=$((retry_count * 2))
        timeout=$((timeout + 10)) # Augmentation progressive
        log_warning "Nouvelle tentative ($retry_count/$max_retries) dans ${sleep_time}s..."
        sleep "$sleep_time"
    done

    log_error "Échec définitif du téléchargement pour $label"
    rm -f "$file.tmp" # Nettoyer en cas d'échec final
    return 1
}

# --- Fonction Principale ---
main() {
    log_header "IMPORTATION DES DONNÉES DE VENTES"

    # Chargement environnement
    set -eo pipefail
    source /app/scripts/env-loader.sh || {
        log_error "Échec critique du chargement de l'environnement"
        exit 1
    }

    # Validation des variables d'environnement nécessaires
    validate_env # Fonction de logging.sh (vérifie DB_PATH par défaut)
    local required_vars=("DATA_DIR" "URL_PRODUITS" "PRODUITS_FILE" "URL_MAGASINS" "MAGASINS_FILE" "URL_VENTES" "VENTES_FILE")
    for var in "${required_vars[@]}"; do
        if [ -z "${!var}" ]; then
            log_error "Variable d'environnement manquante: $var"
            exit 1
        fi
    done

    # Définition du chemin du script SQL d'importation (maintenant temporaire)
    local IMPORT_SQL="${TEMP_SQL_DIR}/import-data.sql"
    
    
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

        local sqlite_error_log
        sqlite_error_log=$(mktemp)
        # Assurer le nettoyage du fichier temporaire
        trap 'rm -f "$sqlite_error_log"' EXIT INT TERM

        if ! sqlite3 -bail "$DB_PATH" < "$IMPORT_SQL" 2> "$sqlite_error_log"; then
            log_error "Échec de l'importation SQL (voir détails ci-dessous)"
            if [ -s "$sqlite_error_log" ]; then
                log_info "--- Début Erreur SQLite ---"
                cat "$sqlite_error_log"
                log_info "--- Fin Erreur SQLite ---"
            else
                log_warning "Aucun détail d'erreur SQLite capturé."
            fi
            exit 1
        fi
        rm -f "$sqlite_error_log" # Supprimer si succès
        trap - EXIT INT TERM # Annuler le trap si succès

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

    log_success "Importation et vérification terminées avec succès."
}

# --- Exécution ---
main "$@"