#!/bin/bash
# Script principal optimisé pour démarrer le service d'analyse des ventes

#Chargement des dépendances
source /app/scripts/common.sh
source /app/scripts/env-loader.sh

# Fonction pour exécuter une étape avec gestion des erreurs
run_step() {
  local step_number=$1
  local step_name=$2
  local script_path=$3
  
  log_info "Étape $step_number: $step_name..."
  if [ -f "$script_path" ]; then
    if ! "$script_path"; then
      log_error "❌ Erreur lors de $step_name."
      return 1
    fi
  else
    log_error "⚠️ Script non trouvé: $script_path"
    return 1
  fi
  
  return 0
}

main() {
    log_header "DÉMARRAGE DU SERVICE"
    # Exécuter les étapes séquentiellement
    run_step 1 "Initialisation de la base de données" "/app/scripts/init-db.sh" || return 1
    run_step 2 "Importation des données" "/app/scripts/import-data.sh" || return 1
    run_step 3 "Analyse des données" "/app/scripts/run-analyses.sh" || return 1

    return 0
}

# Demarrage du script
set -eo pipefail

log_info "👤 UID: $(id -u), 👥 GID: $(id -g)"

# Pré-traitements SQL
if [ -f "/app/scripts/preprocess-sql.sh" ]; then
  log_info "Prétraitement des fichiers SQL..."
  /app/scripts/preprocess-sql.sh
fi

# Exécution principale
if main; then
  log_success "✅ Service d'analyse des ventes exécuté avec succès."
else
  log_error "❌ Des erreurs se sont produites lors de l'exécution du service."
  exit 1
fi