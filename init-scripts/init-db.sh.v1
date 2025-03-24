#!/bin/bash

echo "======================================"
echo "Initialisation et importation de la base de données"
echo "======================================"
echo "Informations système:"
echo "- Date et heure: $(date)"
echo "- SQLite version: $(sqlite3 --version)"
echo "======================================"

# Charger les variables d'environnement
source /app/scripts/env-loader.sh

echo "Création et initialisation de la base de données..."
echo "Chemin de la base de données: $DB_PATH"
echo "Script SQL utilisé: $SCHEMA_FILE"

# Vérifie que le fichier SQL de schéma existe
if [ ! -f "$SCHEMA_FILE" ]; then
    echo "❌ Fichier SQL introuvable: $SCHEMA_FILE"
    exit 1
fi

# Active les contraintes de Fkey
echo "PRAGMA foreign_keys = ON;" | sqlite3 "$DB_PATH"

# Exécute le script SQL de création du schéma
sqlite3 -batch -bail "$DB_PATH" < "$SCHEMA_FILE"

# Vérifie la création de la base
if [ -f "$DB_PATH" ]; then
    echo "✅ Base de données créée avec succès !"
    echo "Tables présentes :"
    sqlite3 "$DB_PATH" ".tables"

    echo "Structure de la table Ventes :"
    sqlite3 "$DB_PATH" ".schema Ventes"
else
    echo "❌ Erreur lors de la création de la base de données !"
    exit 1
fi

echo "======================================"
echo "Le service est prêt à exécuter les analyses de ventes."
echo "======================================"