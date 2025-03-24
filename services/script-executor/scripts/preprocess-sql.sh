#!/bin/bash
# preprocess-sql.sh - Prétraitement des templates SQL

source /app/scripts/common.sh
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

  # Création sécurisée du répertoire
  local output_dir=$(dirname "$output_file")
  if ! mkdir -p "$output_dir"; then
      log_error "Échec de création du répertoire: $output_dir"
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
  # Prétraiter le fichier import-data.sql
  preprocess_sql_template \
    "$SCRIPTS_DIR/import-data-template.sql" \
    "$DATA_DIR/import-data.sql" || return 1
  
  # Ajouter d'autres prétraitements de fichiers SQL si nécessaire
  
  return 0
}

# Gestion des erreurs et exécution
if ! main; then
    log_error "❌ Échec du prétraitement SQL"
    exit 1
fi

log_success "✅ PRÉTRAITEMENT TERMINÉ AVEC SUCCÈS"
exit 0