#!/bin/bash
# Script principal optimisé pour démarrer le service d'analyse des ventes

# Chargement des dépendances
source /app/scripts/logging.sh
source /app/scripts/env-loader.sh

# Fonction pour exécuter une étape avec gestion des erreurs et progression
run_step() {
  local step_number=$1
  local step_name=$2
  local script_path=$3
  
  log_header "Étape $step_number: $step_name"
  if [ -f "$script_path" ]; then
    if ! "$script_path"; then
      log_error "Échec lors de l'étape: $step_name"
      return 1
    fi
    log_success "Étape $step_number terminée: $step_name"
  else
    log_error "Script non trouvé: $script_path"
    return 1
  fi
  
  return 0
}

main() {
    log_header "DÉMARRAGE DU SERVICE D'ANALYSE"
    
    # Affichage des informations système si mode verbose
    if [[ "$LOG_LEVEL" -ge "$LOG_LEVEL_VERBOSE" ]]; then
        log_info "Date: $(date)"
        log_info "Utilisateur: $(id -un) ($(id -u):$(id -g))"
        log_info "SQLite: $(sqlite3 --version | head -n1)"
        log_info "Système: $(uname -a)"
    fi
    
    # Liste des étapes à exécuter
    local steps=(
        "Initialisation de la base de données:/app/scripts/init-db.sh"
        "Importation des données:/app/scripts/import-data.sh"
        "Analyse des données:/app/scripts/run-analyses.sh"
    )
    
    local total_steps=${#steps[@]}
    local current_step=0
    
    # Exécuter les étapes séquentiellement avec barre de progression
    for step in "${steps[@]}"; do
        IFS=':' read -r step_name script_path <<< "$step"
        ((current_step++))
        
        # Afficher la progression
        log_progress "Progression de l'analyse" "$current_step" "$total_steps"
        
        if ! run_step "$current_step" "$step_name" "$script_path"; then
            return 1
        fi
    done

    return 0
}

# Démarrage du script
set -eo pipefail

# Informations de débogage sur l'utilisateur
log_debug "UID: $(id -u), GID: $(id -g)"

# Pré-traitements SQL
if [ -f "/app/scripts/preprocess-sql.sh" ]; then
  log_info "Prétraitement des fichiers SQL..."
  /app/scripts/preprocess-sql.sh
fi

# Exécution principale
if main; then
  log_success "Service d'analyse des ventes exécuté avec succès"
else
  log_error "Des erreurs se sont produites lors de l'exécution du service"
  exit 1
fi