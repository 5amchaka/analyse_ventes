#!/bin/bash
# Script pour prétraiter les fichiers SQL templates et remplacer les variables d'environnement

# Charger les variables d'environnement
set -eu
source /app/scripts/env-loader.sh

# Fonction pour prétraiter un fichier SQL template
preprocess_sql_template() {
  local template_file=$1
  local output_file=$2
  
  if [ ! -f "$template_file" ]; then
    echo "❌ Fichier template non trouvé: $template_file"
    return 1
  fi
  
  # Créer le répertoire de sortie si nécessaire
  mkdir -p $(dirname "$output_file")
  
  # Remplacer les variables d'environnement
  eval "cat <<EOF
$(cat $template_file)
EOF" > "$output_file"
  
  if [ $? -eq 0 ]; then
    echo "✅ Fichier prétraité avec succès: $output_file"
    return 0
  else
    echo "❌ Erreur lors du prétraitement du fichier: $template_file"
    return 1
  fi
}

# Prétraiter le fichier import-data.sql
preprocess_sql_template "$SCRIPTS_DIR/import-data-template.sql" "$DATA_DIR/import-data.sql"

# Ajouter d'autres prétraitements de fichiers SQL si nécessaire