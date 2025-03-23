#!/bin/sh
set -e

# Afficher la version de SQLite
echo "=== Service SQLite démarré ==="
echo "Version: $(sqlite3 --version)"
echo "=============================="
echo "Volume monté dans: /app/database"
echo "Pour accéder au shell: docker exec -it data-storage sh"
echo "=============================="

# Rester en arrière-plan
exec tail -f /dev/null