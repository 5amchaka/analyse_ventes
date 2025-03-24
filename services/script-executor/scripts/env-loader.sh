#!/bin/bash

# Fonction pour charger les variables d'environnement à partir du fichier .env
load_env() {
  local env_file=${1:-/app/.env}
  
  # Vérifier que le fichier existe
  if [ ! -f "$env_file" ]; then
    echo "❌ Fichier .env non trouvé à $env_file"
    return 1
  fi
  
  # Optimisation: Utiliser grep pour ignorer les commentaires et les lignes vides
  # puis awk pour extraire les clés et valeurs proprement
  grep -v "^\s*#" "$env_file" | grep -v "^\s*$" | \
  while IFS='=' read -r key val || [ -n "$key" ]; do
    # Supprime les espaces et les guillemets
    val=$(echo "$val" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' -e 's/^"//' -e 's/"$//')
    # Exporter la variable si elle n'est pas déjà définie
    if [ -z "${!key}" ]; then
      export "$key=$val"
    fi
  done
  
  return 0
}

# Charger les variables d'environnement (utiliser le chemin par défaut)
load_env

# Fonction de debug pour afficher les variables chargées (uniquement si DEBUG est activé)
debug_env() {
  if [ "${DEBUG:-0}" = "1" ]; then
    echo "Variables d'environnement chargées :"
    echo "------------------------------------"
    env | grep -v "^_" | sort
    echo "------------------------------------"
  fi
}

# Activer pour déboguer si nécessaire
debug_env