#!/bin/bash

echo "======================================"
echo "Hello service d'exécution des scripts!"
echo "======================================"
echo "Informations système:"
echo "- Date et heure: $(date)"
echo "- SQLite version: $(sqlite3 --version)"
echo "- Python version: $(python3 --version)"
echo "======================================"
echo "Le service est prêt à exécuter les analyses de ventes."
echo "======================================"