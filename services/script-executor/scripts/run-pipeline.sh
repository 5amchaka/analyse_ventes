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

clean_temp_files() {
    log_header "Nettoyage des fichiers temporaires"
    
    # Nettoyage des fichiers SQL temporaires
    if [ -d "$TEMP_SQL_DIR" ] && [ -n "$TEMP_SQL_DIR" ]; then
        log_info "Nettoyage du répertoire $TEMP_SQL_DIR"
        find "$TEMP_SQL_DIR" -type f -name "*.sql" -exec rm -f {} \;
    fi
    
    log_success "Nettoyage terminé"
}

verify_cleanup() {
    log_header "Vérification du nettoyage"
    
    # Vérification des fichiers SQL temporaires
    if [ -d "$TEMP_SQL_DIR" ]; then
        temp_files_count=$(find "$TEMP_SQL_DIR" -type f -name "*.sql" | wc -l)
        
        if [ "$temp_files_count" -eq 0 ]; then
            log_success "Nettoyage réussi: Aucun fichier SQL temporaire trouvé dans $TEMP_SQL_DIR"
        else
            log_warning "Nettoyage incomplet: $temp_files_count fichier(s) SQL temporaire(s) trouvé(s) dans $TEMP_SQL_DIR"
            
            # Afficher les fichiers qui n'ont pas été supprimés (mode verbose ou debug)
            if [ "$LOG_LEVEL" -ge "$LOG_LEVEL_VERBOSE" ]; then
                log_verbose "Liste des fichiers non supprimés:"
                find "$TEMP_SQL_DIR" -type f -name "*.sql" -exec ls -l {} \; | sed 's/^/  /'
            fi
        fi
    else
        log_warning "Répertoire $TEMP_SQL_DIR non trouvé pour vérification"
    fi
    
    # Vérification de l'espace disque pour détection de problèmes potentiels
    if [ "$LOG_LEVEL" -ge "$LOG_LEVEL_DEBUG" ]; then
        log_debug "État de l'espace disque après nettoyage:"
        df -h /app/tmp | sed 's/^/  /'
    fi
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

clean_temp_files
verify_cleanup