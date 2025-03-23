#!/bin/bash
# Script principal optimisé pour démarrer le service d'analyse des ventes

set -e  # Arrêter l'exécution en cas d'erreur

echo "======================================"
echo "Démarrage du service d'analyse des ventes"
echo "======================================"

# Rendre tous les scripts exécutables
chmod +x /app/scripts/*.sh

# Copier env-loader.sh s'il n'existe pas déjà dans le répertoire scripts
if [ ! -f "/app/scripts/env-loader.sh" ]; then
  cp /app/env-loader.sh /app/scripts/env-loader.sh
  chmod +x /app/scripts/env-loader.sh
fi

# Charger les variables d'environnement
source /app/scripts/env-loader.sh

# Prétraitement des fichiers SQL templates si nécessaire
if [ -f "/app/scripts/preprocess-sql.sh" ]; then
  echo "Étape 0: Prétraitement des fichiers SQL..."
  /app/scripts/preprocess-sql.sh
fi

# Fonction pour exécuter une étape avec gestion des erreurs
run_step() {
  local step_number=$1
  local step_name=$2
  local script_path=$3
  
  echo "Étape $step_number: $step_name..."
  if [ -f "$script_path" ]; then
    "$script_path"
    if [ $? -ne 0 ]; then
      echo "❌ Erreur lors de $step_name."
      return 1
    fi
  else
    echo "⚠️ Script non trouvé: $script_path"
    return 1
  fi
  
  return 0
}

# Exécuter les étapes séquentiellement
run_step 1 "Initialisation de la base de données" "/app/scripts/init-db.sh" && \
run_step 2 "Importation des données" "/app/scripts/import-data.sh" && \
run_step 3 "Analyse des données" "/app/scripts/run-analyses.sh"

# Vérifier le succès global
if [ $? -eq 0 ]; then
  echo "======================================"
  echo "✅ Service d'analyse des ventes démarré avec succès."
  echo "======================================"
else
  echo "======================================"
  echo "❌ Des erreurs se sont produites lors du démarrage du service."
  echo "======================================"
  exit 1
fi

# Maintenir le conteneur en vie pour permettre l'exécution de commandes
#exec tail -f /dev/null