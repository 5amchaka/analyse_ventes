#!/bin/bash

# Définir les couleurs pour une sortie plus lisible
BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'

# Définir les chemins des fichiers
DB_PATH="/app/database/ventes.db"
SQL_SCRIPT="/app/scripts/analyses-ventes.sql"
RESULTS_DIR="/app/results"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
RESULTS_FILE="${RESULTS_DIR}/rapport_ventes_${TIMESTAMP}.txt"

# Centrage sans tput (fallback à 80 cols)
COLS=$(TERM=dumb tput cols 2>/dev/null || echo 80)

# Fonction pour créer une ligne de séparation
function separator() {
    local char=$1
    local color=$2
    printf "${color}%*s${RESET}\n" "$COLS" "" | tr " " "$char"
}

# Vérifier que la base de données existe
if [ ! -f "$DB_PATH" ]; then
    printf "${RED}${BOLD}❌ Erreur: Base de données non trouvée à $DB_PATH${RESET}\n"
    exit 1
fi

# Vérifier que le script SQL existe
if [ ! -f "$SQL_SCRIPT" ]; then
    printf "${RED}${BOLD}❌ Erreur: Script SQL non trouvé à $SQL_SCRIPT${RESET}\n"
    exit 1
fi

# Créer le répertoire de résultats s'il n'existe pas
mkdir -p "$RESULTS_DIR"

# Préparer le rapport
{
  printf "\n"
  printf "%s\n" "================================================================================"
  printf "%s\n" "                            RAPPORT D'ANALYSE DES VENTES                       "
  printf "%s\n" "================================================================================"
  printf "Date du rapport : %s\n" "$(date)"
  printf "\n\n"

  printf "%s\n" "--------------------"
  printf "%s\n" "1. SYNTHÈSE DU CHIFFRE D'AFFAIRES"
  printf "%s\n" "--------------------"
  printf "\n"
  sqlite3 -batch -column -header "$DB_PATH" <<EOF
.read $SQL_SCRIPT
SELECT ROUND(chiffre_affaires_total, 2) AS 'CHIFFRE D''AFFAIRES TOTAL (€)', date_debut || ' à ' || date_fin AS 'PÉRIODE', nombre_ventes AS 'NOMBRE DE VENTES', quantite_totale AS 'QUANTITÉ TOTALE VENDUE' FROM temp_ca_total;
EOF
  printf "\n\n"

  printf "%s\n" "--------------------"
  printf "%s\n" "2. ANALYSE DES VENTES PAR PRODUIT"
  printf "%s\n" "--------------------"
  printf "\n"
  sqlite3 -batch -column -header "$DB_PATH" <<EOF
.read $SQL_SCRIPT
SELECT id_produit AS 'RÉFÉRENCE', nom AS 'PRODUIT', quantite_totale AS 'QUANTITÉ VENDUE', ROUND(chiffre_affaires, 2) || ' €' AS 'CA (€)', pourcentage_ca || ' %' AS 'PART DU CA (%)', nombre_ventes AS 'NB VENTES', quantite_moyenne_par_vente AS 'QTÉ MOY/VENTE' FROM temp_ca_produits;
EOF
  printf "\n\n"

  printf "%s\n" "--------------------"
  printf "%s\n" "3. ANALYSE DES VENTES PAR VILLE"
  printf "%s\n" "--------------------"
  printf "\n"
  sqlite3 -batch -column -header "$DB_PATH" <<EOF
.read $SQL_SCRIPT
SELECT ville AS 'VILLE', ROUND(chiffre_affaires, 2) || ' €' AS 'CA (€)', pourcentage_ca || ' %' AS 'PART DU CA (%)', nombre_ventes AS 'NB VENTES', quantite_totale AS 'QTÉ TOTALE', nombre_produits_differents AS 'DIVERSITÉ PRODUITS', ca_par_salarie || ' €' AS 'CA/EMPLOYÉ (€)' FROM temp_ca_villes;
EOF
  printf "\n\n"
} | tee "$RESULTS_FILE"

printf "${GREEN}${BOLD}✅ Rapport d'analyse des ventes généré avec succès !${RESET}\n"
separator "-" "$BLUE"
printf "${CYAN}Pour visualiser le rapport ultérieurement:${RESET}\n"
printf "${BOLD}cat %s${RESET}\n\n" "$RESULTS_FILE"