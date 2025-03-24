#!/bin/bash
# run-analyses.sh - Génération des rapports d'analyse

source /app/scripts/common.sh
source /app/scripts/env-loader.sh

# Configuration
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
RESULTS_FILE="${RESULTS_DIR}/${RAPPORT_PREFIX}${TIMESTAMP}.txt"

# Fonction pour créer des séparateurs
separator() {
    local char=$1
    log_header "$(printf "%${COLS}s" "" | tr " " "$char")"
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

# Génération de section de rapport
generate_section() {
    local title=$1
    local query=$2
    
    #separator "-" 
    log_header "${title}"
    sqlite3 -batch -column -header "$DB_PATH" <<EOF
.read $ANALYSES_SQL
${query}
EOF
}

main() {
    log_header "DÉBUT DE L'ANALYSE"
    
    # Vérifications
    validate_file "$DB_PATH" "Base de données"
    validate_file "$ANALYSES_SQL" "Script SQL d'analyse"
    
    # Préparation environnement
    mkdir -p "$RESULTS_DIR"
    
    # Génération du rapport
    {
        log_header "RAPPORT D'ANALYSE DES VENTES"
        log_info "Généré le : $(date)"
        
        generate_section "SYNTHÈSE DU CHIFFRE D'AFFAIRES" \
            "SELECT ROUND(chiffre_affaires_total, 2) AS 'CA TOTAL (€)', 
            date_debut || ' à ' || date_fin AS PÉRIODE, 
            nombre_ventes AS 'NB VENTES', 
            quantite_totale AS 'QTÉ TOTALE' 
            FROM temp_ca_total;"

        generate_section "ANALYSE PAR PRODUIT" \
            "SELECT id_produit AS RÉFÉRENCE, 
            nom AS PRODUIT, 
            quantite_totale AS 'QTÉ VENDUE', 
            ROUND(chiffre_affaires, 2) || ' €' AS 'CA (€)', 
            pourcentage_ca || ' %' AS 'PART CA', 
            nombre_ventes AS 'NB VENTES', 
            quantite_moyenne_par_vente AS 'MOYENNE/VENTE' 
            FROM temp_ca_produits;"

        generate_section "ANALYSE PAR VILLE" \
            "SELECT ville AS VILLE, 
            ROUND(chiffre_affaires, 2) || ' €' AS 'CA (€)', 
            pourcentage_ca || ' %' AS 'PART CA', 
            nombre_ventes AS 'NB VENTES', 
            quantite_totale AS 'QTÉ TOTALE', 
            nombre_produits_differents AS 'DIVERSITÉ', 
            ca_par_salarie || ' €' AS 'CA/EMPLOYÉ' 
            FROM temp_ca_villes;"

    } | tee "$RESULTS_FILE"

    log_success "Rapport généré : ${RESULTS_FILE}"
    #separator "="
}

# Exécution principale
main