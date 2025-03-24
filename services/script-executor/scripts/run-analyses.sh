#!/bin/bash
# run-analyses.sh - Génération des rapports d'analyse

source /app/scripts/logging.sh
source /app/scripts/env-loader.sh

# Configuration
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
RESULTS_FILE="${RESULTS_DIR}/${RAPPORT_PREFIX}${TIMESTAMP}.txt"
TERMINAL_WIDTH=$(tput cols 2>/dev/null || echo 80)

# Fonction pour créer des séparateurs
separator() {
    local char=$1
    local width=${2:-$TERMINAL_WIDTH}
    
    printf "%${width}s\n" | tr " " "$char"
}

# Validation initiale
validate_file() {
    local file=$1
    local desc=$2
    
    if [ ! -f "$file" ]; then
        log_error "${desc} non trouvé(e) : $file"
        exit 1
    fi
}

# Génération de section de rapport avec formatage amélioré
# Version pour terminal (avec couleurs)
generate_section_terminal() {
    local title=$1
    local query=$2
    
    log_header "${title}"
    
    # Utilisation de l'option -column pour un affichage tabulaire et -header pour les noms de colonnes
    sqlite3 -batch -column -header "$DB_PATH" <<EOF
.read $ANALYSES_SQL
.mode column
.headers on
.width auto
${query}
EOF
}

# Version pour fichier (sans couleurs)
generate_section_file() {
    local title=$1
    local query=$2
    local output_file=$3
    
    # En-tête de section
    {
        echo ""
        echo "======================================"
        echo " ${title}"
        echo "======================================"
        echo ""
    } >> "$output_file"
    
    # Exécution et enregistrement de la requête SQL sans couleurs
    sqlite3 -batch -column -header "$DB_PATH" <<EOF >> "$output_file"
.read $ANALYSES_SQL
.mode column
.headers on
.width auto
${query}
EOF
}

# Fonction pour ajouter une bordure décorative au rapport
add_report_header() {
    local title="$1"
    local width=${2:-$TERMINAL_WIDTH}
    local date_str="$(date '+%d/%m/%Y %H:%M:%S')"
    
    # Affichage dans le terminal (avec couleurs si activées)
    echo -e "${COLOR_HEADER}"
    separator "=" "$width"
    
    # Centrer le titre
    local title_len=${#title}
    local padding=$(( (width - title_len) / 2 ))
    printf "%${padding}s%s%${padding}s\n" "" "$title" ""
    
    separator "-" "$width"
    printf " Date: %s\n" "$date_str"
    printf " Base de données: %s\n" "$(basename "$DB_PATH")"
    printf " Fichier rapport: %s\n" "$(basename "$RESULTS_FILE")"
    separator "=" "$width"
    echo -e "${COLOR_RESET}"
    
    # Enregistrement dans le fichier (sans couleurs)
    {
        separator "=" "$width"
        local title_len=${#title}
        local padding=$(( (width - title_len) / 2 ))
        printf "%${padding}s%s%${padding}s\n" "" "$title" ""
        separator "-" "$width"
        printf " Date: %s\n" "$date_str"
        printf " Base de données: %s\n" "$(basename "$DB_PATH")"
        printf " Fichier rapport: %s\n" "$(basename "$RESULTS_FILE")"
        separator "=" "$width"
        echo ""
    } > "$RESULTS_FILE"
}

main() {
    log_header "DÉBUT DE L'ANALYSE"
    
    # Vérifications
    validate_file "$DB_PATH" "Base de données"
    validate_file "$ANALYSES_SQL" "Script SQL d'analyse"
    
    # Préparation environnement
    mkdir -p "$RESULTS_DIR"
    
    # Génération du rapport
    # 1. Affichage dans le terminal avec couleurs
    add_report_header "RAPPORT D'ANALYSE DES VENTES" 80
    
    generate_section_terminal "SYNTHÈSE DU CHIFFRE D'AFFAIRES" \
        "SELECT ROUND(chiffre_affaires_total, 2) AS 'CA TOTAL (€)', 
        date_debut || ' à ' || date_fin AS PÉRIODE, 
        nombre_ventes AS 'NB VENTES', 
        quantite_totale AS 'QTÉ TOTALE' 
        FROM temp_ca_total;"

    # Enregistrement dans le fichier (version sans couleurs)
    generate_section_file "SYNTHÈSE DU CHIFFRE D'AFFAIRES" \
        "SELECT ROUND(chiffre_affaires_total, 2) AS 'CA TOTAL (€)', 
        date_debut || ' à ' || date_fin AS PÉRIODE, 
        nombre_ventes AS 'NB VENTES', 
        quantite_totale AS 'QTÉ TOTALE' 
        FROM temp_ca_total;" \
        "$RESULTS_FILE"

    echo ""
    generate_section_terminal "ANALYSE PAR PRODUIT" \
        "SELECT id_produit AS RÉFÉRENCE, 
        nom AS PRODUIT, 
        quantite_totale AS 'QTÉ VENDUE', 
        ROUND(chiffre_affaires, 2) || ' €' AS 'CA (€)', 
        pourcentage_ca || ' %' AS 'PART CA', 
        nombre_ventes AS 'NB VENTES', 
        quantite_moyenne_par_vente AS 'MOYENNE/VENTE' 
        FROM temp_ca_produits;"

    generate_section_file "ANALYSE PAR PRODUIT" \
        "SELECT id_produit AS RÉFÉRENCE, 
        nom AS PRODUIT, 
        quantite_totale AS 'QTÉ VENDUE', 
        ROUND(chiffre_affaires, 2) || ' €' AS 'CA (€)', 
        pourcentage_ca || ' %' AS 'PART CA', 
        nombre_ventes AS 'NB VENTES', 
        quantite_moyenne_par_vente AS 'MOYENNE/VENTE' 
        FROM temp_ca_produits;" \
        "$RESULTS_FILE"

    echo ""
    generate_section_terminal "ANALYSE PAR VILLE" \
        "SELECT ville AS VILLE, 
        ROUND(chiffre_affaires, 2) || ' €' AS 'CA (€)', 
        pourcentage_ca || ' %' AS 'PART CA', 
        nombre_ventes AS 'NB VENTES', 
        quantite_totale AS 'QTÉ TOTALE', 
        nombre_produits_differents AS 'DIVERSITÉ', 
        ca_par_salarie || ' €' AS 'CA/EMPLOYÉ' 
        FROM temp_ca_villes;"

    generate_section_file "ANALYSE PAR VILLE" \
        "SELECT ville AS VILLE, 
        ROUND(chiffre_affaires, 2) || ' €' AS 'CA (€)', 
        pourcentage_ca || ' %' AS 'PART CA', 
        nombre_ventes AS 'NB VENTES', 
        quantite_totale AS 'QTÉ TOTALE', 
        nombre_produits_differents AS 'DIVERSITÉ', 
        ca_par_salarie || ' €' AS 'CA/EMPLOYÉ' 
        FROM temp_ca_villes;" \
        "$RESULTS_FILE"

    # Pied de page
    echo ""
    echo -e "${COLOR_HEADER}"
    separator "="
    echo "FIN DU RAPPORT - $(date '+%d/%m/%Y %H:%M:%S')"
    separator "="
    echo -e "${COLOR_RESET}"
    
    # Ajout du pied de page au fichier (sans couleurs)
    {
        echo ""
        separator "="
        echo "FIN DU RAPPORT - $(date '+%d/%m/%Y %H:%M:%S')"
        separator "="
    } >> "$RESULTS_FILE"

    log_success "Rapport généré : ${RESULTS_FILE}"
}

# Exécution principale
main