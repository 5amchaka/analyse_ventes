#!/bin/sh

# Script d'initialisation pour vérifier l'accès à SQLite

echo "===================================="
echo "Test d'accès à SQLite"
echo "===================================="

# Vérifier la version de SQLite
echo "Version de SQLite: $(sqlite3 --version)"

# Créer une base de données test
sqlite3 /app/database/test.db <<EOF
CREATE TABLE IF NOT EXISTS test (
    id INTEGER PRIMARY KEY,
    message TEXT
);

INSERT INTO test (message) VALUES ('Test de fonctionnement SQLite réussi');

SELECT * FROM test;
EOF

echo "===================================="
echo "Hello service de stockage des données!"
echo "===================================="
echo "Base de données test créée avec succès"
echo "Pour accéder à SQLite dans le conteneur, utilisez:"
echo "docker exec -it data-storage sqlite3 /app/database/test.db"
echo "===================================="