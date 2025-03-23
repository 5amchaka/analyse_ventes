#!/bin/bash
# Script wrapper pour exécuter init-db.sh suivi de hello-world.sh

echo "======================================"
echo "Démarrage du service d'analyse des ventes"
echo "======================================"

# Exécution du script d'initialisation de la base de données
echo "Étape 1: Initialisation de la base de données..."
/app/scripts/init-db.sh

# Vérifier le code de retour
if [ $? -ne 0 ]; then
    echo "❌ Erreur lors de l'initialisation de la base de données."
    exit 1
fi

# Exécution du script d'importation des données
echo "Étape 2: Importation des données..."
/app/scripts/hello-world.sh

# Vérifier le code de retour
if [ $? -ne 0 ]; then
    echo "❌ Erreur lors de l'importation des données."
    exit 1
fi

# Exécution du script d'analyse des données
echo "Étape 3: Analyse des données..."
/app/scripts/run-analyses.sh

# Vérifier le code de retour
if [ $? -ne 0 ]; then
    echo "❌ Erreur lors de l'analyse des données."
    exit 1
fi

echo "======================================"
echo "Service d'analyse des ventes démarré avec succès."
echo "======================================"

# Maintenir le conteneur en vie pour permettre l'exécution de commandes
#tail -f /dev/null