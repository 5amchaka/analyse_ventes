#!/bin/bash
# preprocess-sql.sh - Prétraitement des templates SQL

source /app/scripts/logging.sh
source /app/scripts/env-loader.sh|| {
    log_error "Échec du chargement de l'environnement"
    exit 1
}

# Fonction pour prétraiter un fichier SQL template
preprocess_sql_template() {
  local template_file=$1
  local output_file=$2
  
  if [ ! -f "$template_file" ]; then
    log_error "❌ Fichier template non trouvé: $template_file"
    return 1
  fi

  log_info "Début du prétraitement: ${template_file}"
  log_debug "Fichier de sortie: ${output_file}"

  # Création sécurisée du répertoire
  local output_dir=$(dirname "$output_file")
  if ! mkdir -p "$output_dir"; then
      log_error "Échec de création du répertoire: $output_dir"
      return 1
  fi

    log_info "Tentative d'écriture simple..."
  if touch "${output_dir}/test_touch.tmp"; then
    log_success "Écriture simple réussie (touch)"
    rm "${output_dir}/test_touch.tmp"
  else
    log_error "Échec de l'écriture simple (touch)"
    
  fi

   # Vérification des permissions
  if [ ! -w "$output_dir" ]; then
      log_error "Permission d'écriture refusée sur: $output_dir"
      log_debug "Permissions actuelles: $(ls -ld $output_dir)"
      log_debug "Utilisateur actuel: $(id -u):$(id -g)"
      return 1
  fi

  # Génération sécurisée avec vérification
  if ! envsubst < "$template_file" > "$output_file"; then
      log_error "Échec du prétraitement pour: $template_file"
      return 1
  fi

  log_success "Fichier généré: ${output_file}"
  return 0
}

main() {
  log_header "PRÉTRAITEMENT SQL"
  
  #echo "--- DEBUG INFO ---"
  #echo "Executing as user:"
  #id
  #echo "Permissions for /app/tmp:"
  #ls -ld /app/tmp
  #echo "Permissions for /app/tmp/sql_imports:"
  #ls -ld /app/tmp/sql_imports
  #echo "--- END DEBUG INFO ---"

  if [ -z "$TEMP_SQL_DIR" ]; then
    log_error "TEMP_SQL_DIR n'est pas défini dans l'environnement"
    return 1
  fi

  # Afficher des informations de débogage
  log_debug "SQL_DIR est configuré à: $SQL_DIR"
  log_debug "TEMP_SQL_DIR est configuré à: $TEMP_SQL_DIR"

  # Vérifier que le répertoire temporaire existe
  if [ ! -d "$TEMP_SQL_DIR" ]; then
    log_warning "Répertoire temporaire SQL non trouvé, tentative de création..."
    if ! mkdir -p "$TEMP_SQL_DIR"; then
      log_error "Impossible de créer le répertoire temporaire: $TEMP_SQL_DIR"
      return 1
    fi
  fi

  # Prétraiter le fichier import-data.sql dans le répertoire standard
  preprocess_sql_template \
    "$SQL_DIR/import-data-template.sql" \
    "$TEMP_SQL_DIR/import-data.sql" || return 1
  
  # Ajouter d'autres prétraitements de fichiers SQL si nécessaire
  log_success "Le fichier SQL d'importation a été prétraité avec succès"

  return 0
}

# Gestion des erreurs et exécution
if ! main; then
    log_error "❌ Échec du prétraitement SQL"
    exit 1
fi

log_success "✅ PRÉTRAITEMENT TERMINÉ AVEC SUCCÈS"
exit 0