# Analyse de ventes - Architecture Docker
# Analyse de Ventes - Architecture Docker

## Description

Ce projet implémente un système d'analyse de ventes basé sur une architecture Docker. Il permet d'importer et d'analyser des données de ventes à partir de fichiers CSV, puis de générer des rapports d'analyse détaillés.

## Architecture

Le système est composé de deux services principaux :

1. **Service de stockage de données (data-storage)** :
   - Basé sur SQLite
   - Gère la persistance des données
   - S'exécute dans un conteneur Docker dédié

2. **Service d'exécution des scripts (script-executor)** :
   - Exécute les scripts d'analyse et de traitement des données
   - Génère les rapports d'analyse
   - Interagit avec le service de stockage de données

## Prérequis

- Docker
- Docker Compose

## Installation

1. Clonez ce dépôt :
   ```bash
   git clone https://github.com/5amchaka/analyse_ventes.git
   cd analyse-ventes-docker
   ```

2. Configurez les variables d'environnement (facultatif) :
   ```bash
   cp .env.example .env
   # Modifiez le fichier .env selon vos besoins
   ```

## Utilisation

### Démarrage des services

```bash
docker-compose up -d
```

### Exécution d'une analyse

Par défaut, le service `script-executor` exécute automatiquement les analyses au démarrage. Les résultats sont stockés dans le dossier `results/`.

### Visualisation des résultats

Vous pouvez visualiser les rapports générés dans le dossier `results/`. Chaque rapport est nommé selon le format `rapport_ventes_YYYYMMDD_HHMMSS.txt`.

### Arrêt des services

```bash
docker-compose down
```

## Structure des données

Le système analyse trois ensembles de données principaux :

1. **Produits** (produits.csv) :
   - ID Référence produit
   - Nom
   - Prix
   - Stock

2. **Magasins** (magasins.csv) :
   - ID Magasin
   - Ville
   - Nombre de salariés

3. **Ventes** (ventes.csv) :
   - Date
   - ID Référence produit
   - Quantité
   - ID Magasin

## Structure du projet

```
.
├── data/                   # Données CSV d'entrée
├── init-scripts/           # Scripts d'initialisation
├── results/                # Rapports d'analyse générés
├── services/               # Services Docker
│   ├── data-storage/       # Service de stockage de données
│   └── script-executor/    # Service d'exécution des scripts
├── sql/                    # Scripts SQL
├── .env                    # Variables d'environnement
├── docker-compose.yml      # Configuration Docker Compose
└── README.md               # Documentation du projet
```

## Types d'analyses

Le système génère trois types d'analyses :

1. **Synthèse du chiffre d'affaires** : CA total, période, nombre de ventes, quantité totale
2. **Analyse des ventes par produit** : CA par produit, part du CA, nombre de ventes, quantité moyenne par vente
3. **Analyse des ventes par ville** : CA par ville, part du CA, nombre de ventes, diversité de produits, CA par employé

## Développement

### Ajout de nouvelles analyses

Pour ajouter de nouvelles analyses, modifiez le fichier `sql/analyses-ventes.sql` et mettez à jour le script `services/script-executor/scripts/run-analyses.sh`.

### Personnalisation des rapports

Le format des rapports peut être personnalisé en modifiant le script `services/script-executor/scripts/run-analyses.sh`.