#!/bin/bash

echo "======================================"
echo "Hello données de ventes"
echo "======================================"
echo "Informations système:"
echo "- Date et heure: $(date)"
echo "- SQLite version: $(sqlite3 --version)"
echo "======================================"

# Charger les variables d'environnement
set -eu
source /app/scripts/env-loader.sh

# Vérifier que la base de données existe (créée par init-db.sh)
if [ ! -f "$DB_PATH" ]; then
    echo "❌ Base de données non trouvée à $DB_PATH"
    echo "Veuillez exécuter init-db.sh en premier pour créer la structure de la base de données."
    exit 1
fi

echo "✅ Base de données trouvée. Vérification des tables..."

# Vérifier que les tables principales existent
TABLES_COUNT=$(sqlite3 $DB_PATH "SELECT count(*) FROM sqlite_master WHERE type='table' AND name IN ('Produits', 'Magasins', 'Ventes');")

if [ "$TABLES_COUNT" -ne "3" ]; then
    echo "❌ Structure de base de données incomplète. Veuillez exécuter init-db.sh."
    exit 1
fi

echo "✅ Structure de base de données validée."

echo "======================================"
echo "Téléchargement et importation des données..."
echo "======================================"

# Création du répertoire de données s'il n'existe pas
mkdir -p $DATA_DIR

# Téléchargement des fichiers CSV
echo "Téléchargement des données produits..."
curl -L "$URL_PRODUITS" -o "$DATA_DIR/$PRODUITS_FILE"

echo "Téléchargement des données magasins..."
curl -L "$URL_MAGASINS" -o "$DATA_DIR/$MAGASINS_FILE"

echo "Téléchargement des données ventes..."
curl -L "$URL_VENTES" -o "$DATA_DIR/$VENTES_FILE"

# Vérification des téléchargements
if [ ! -f "$DATA_DIR/$PRODUITS_FILE" ] || [ ! -f "$DATA_DIR/$MAGASINS_FILE" ] || [ ! -f "$DATA_DIR/$VENTES_FILE" ]; then
    echo "❌ Erreur lors du téléchargement des fichiers CSV!"
    exit 1
fi

echo "✅ Fichiers CSV téléchargés avec succès!"

# Vérifier que le script SQL d'importation existe
if [ ! -f "$IMPORT_SQL" ]; then
    echo "❌ Script SQL d'importation non trouvé à $IMPORT_SQL"
    exit 1
fi

# Exécution du script SQL d'importation
echo "Importation des données dans la base de données..."
sqlite3 $DB_PATH < "$IMPORT_SQL"

# Vérification de l'importation
echo "Vérification de l'importation des données..."
nb_produits=$(sqlite3 $DB_PATH "SELECT COUNT(*) FROM Produits;")
nb_magasins=$(sqlite3 $DB_PATH "SELECT COUNT(*) FROM Magasins;")
nb_ventes=$(sqlite3 $DB_PATH "SELECT COUNT(*) FROM Ventes;")

echo "Nombre de produits importés: $nb_produits"
echo "Nombre de magasins importés: $nb_magasins"
echo "Nombre total de ventes: $nb_ventes"

echo "✅ Importation des données terminée avec succès!"
echo "======================================"
echo "Le service est prêt à exécuter les analyses de ventes."
echo "======================================"