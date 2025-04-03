# Documentation Complète - Projet Analyse de Ventes Docker

## Table des matières

1. [Vue d'ensemble](#vue-densemble)
   - [Description du projet](#description-du-projet)
   - [Architecture système](#architecture-système)
   - [Flux de données](#flux-de-données)

2. [Guide d'installation](#guide-dinstallation)
   - [Prérequis](#prérequis)
   - [Installation](#installation)
   - [Configuration](#configuration)

3. [Guide d'utilisation](#guide-dutilisation)
   - [Démarrage des services](#démarrage-des-services)
   - [Exécution d'analyses](#exécution-danalyses)
   - [Interprétation des rapports](#interprétation-des-rapports)
   - [Résolution des problèmes courants](#résolution-des-problèmes-courants)

4. [Documentation technique](#documentation-technique)
   - [Structure du projet](#structure-du-projet)
   - [Description des services](#description-des-services)
   - [Structure de la base de données](#structure-de-la-base-de-données)
   - [Scripts et processus](#scripts-et-processus)

5. [Guides d'extension](#guides-dextension)
   - [Ajout de nouvelles analyses](#ajout-de-nouvelles-analyses)
   - [Intégration de nouvelles sources de données](#intégration-de-nouvelles-sources-de-données)
   - [Personnalisation des rapports](#personnalisation-des-rapports)

6. [Glossaire et FAQ](#glossaire-et-faq)
   - [Termes techniques](#termes-techniques)
   - [FAQ](#faq)

7. [Annexes](#annexes)
   - [Variables d'environnement](#variables-denvironnement)
   - [Exemples de requêtes SQL](#exemples-de-requêtes-sql)
   - [Plan de développement futur](#plan-de-développement-futur)

---

## Vue d'ensemble

### Description du projet

Le projet **Analyse de Ventes Docker** est un système permettant l'importation, le stockage et l'analyse de données de ventes d'une entreprise. Basé sur une architecture Docker, il offre une solution portable et isolée pour traiter les données de ventes, générer des analyses et produire des rapports détaillés.

Le système s'articule autour de trois ensembles de données principaux :
- **Produits** : Informations sur les produits vendus (référence, nom, prix, stock)
- **Magasins** : Informations sur les points de vente (identifiant, ville, nombre d'employés)
- **Ventes** : Transactions enregistrées (date, produit, quantité, magasin)

Pour plus de détails, consultez le [rapport d'analyse complet](documents/analyse.md).

### Architecture système

L'architecture du système repose sur deux services Docker distincts mais complémentaires :

1. **Service de stockage de données (`data-storage`)** :
   - Basé sur SQLite pour une solution légère et sans serveur
   - Gère la persistance des données dans un volume Docker dédié
   - Offre un stockage fiable avec vérification d'intégrité

2. **Service d'exécution des scripts (`script-executor`)** :
   - Exécute l'ensemble du pipeline de traitement des données
   - Importe les données CSV depuis des sources externes
   - Exécute les requêtes d'analyse SQL
   - Génère les rapports formatés

#### Diagramme d'architecture

![Architecture du projet](documents/architecture.svg)

### Flux de données

Le système suit un flux de données séquentiel :

1. **Acquisition des données** : Téléchargement des fichiers CSV depuis des sources externes
2. **Importation** : Prétraitement et chargement des données dans la base SQLite
3. **Analyse** : Exécution des requêtes SQL d'analyse sur les données importées
4. **Génération des rapports** : Formatage des résultats dans des rapports lisibles

---

## Guide d'installation

### Prérequis

Pour installer et exécuter ce projet, vous aurez besoin de :

- **Docker** (version 20.10.0 ou supérieure)
- **Docker Compose** (version 2.0.0 ou supérieure)
- Accès Internet pour télécharger les images Docker et les données CSV
- 50 Mo d'espace disque minimum pour l'installation de base
- Espace supplémentaire en fonction du volume de données à traiter

### Installation

1. **Clonage du dépôt** :
   ```bash
   git clone https://github.com/5amchaka/analyse_ventes.git
   cd analyse-ventes-docker
   ```

2. **Configuration de l'environnement** :
   ```bash
   cp .env.example .env
   # Éditez le fichier .env selon vos besoins
   ```

3. **Construction des images Docker** :
   ```bash
   docker-compose build
   ```

### Configuration

Les principales variables de configuration se trouvent dans le fichier `.env` :

- **Paramètres de base de données** :
  - `SQLITE_DB_NAME` : Nom du fichier de base de données SQLite
  - `DB_PATH` : Chemin complet vers le fichier de base de données

- **Chemins des fichiers et répertoires** :
  - `SQL_DIR` : Répertoire des scripts SQL
  - `DATA_DIR` : Répertoire pour les données téléchargées
  - `RESULTS_DIR` : Répertoire pour les rapports générés

- **Sources de données** :
  - `URL_PRODUITS` : URL du fichier CSV des produits
  - `URL_MAGASINS` : URL du fichier CSV des magasins
  - `URL_VENTES` : URL du fichier CSV des ventes

- **Options de logging** :
  - `LOG_LEVEL` : Niveau de détail des logs (0: minimal, 1: normal, 2: verbose, 3: debug)
  - `USE_COLORS` : Activation des couleurs dans les logs (0: désactivé, 1: activé)

---

## Guide d'utilisation

### Démarrage des services

Pour démarrer l'ensemble des services :

```bash
docker-compose up -d
```

Cette commande lance les conteneurs en mode détaché (background). Le service `script-executor` démarrera automatiquement le pipeline d'analyse.

Pour suivre les logs en temps réel :

```bash
docker-compose logs -f
```

### Exécution d'analyses

Par défaut, le service `script-executor` exécute automatiquement l'ensemble du pipeline d'analyse au démarrage :

1. Initialisation de la base de données
2. Téléchargement et importation des données
3. Exécution des analyses
4. Génération des rapports

Pour exécuter manuellement le pipeline après modification des fichiers sources :

```bash
docker-compose restart script-executor
```

Pour exécuter une étape spécifique du pipeline (par exemple, uniquement l'analyse) :

```bash
docker-compose exec script-executor /app/scripts/run-analyses.sh
```

### Interprétation des rapports

Les rapports générés sont stockés dans le dossier `results/` avec un nom de fichier au format `rapport_ventes_YYYYMMDD_HHMMSS.txt`.

Chaque rapport contient plusieurs sections :

1. **SYNTHÈSE DU CHIFFRE D'AFFAIRES** :
   - CA total sur la période
   - Période analysée
   - Nombre total de ventes
   - Quantité totale vendue

2. **ANALYSE PAR PRODUIT** :
   - Référence et nom du produit
   - Quantité vendue par produit
   - Chiffre d'affaires par produit
   - Part du CA total
   - Nombre de ventes
   - Quantité moyenne par vente

3. **ANALYSE PAR VILLE** :
   - Nom de la ville
   - Chiffre d'affaires par ville
   - Part du CA total
   - Nombre de ventes
   - Quantité totale vendue
   - Diversité des produits
   - CA par employé

### Résolution des problèmes courants

#### Problème : Les services ne démarrent pas correctement

**Solution** :
1. Vérifiez les logs pour identifier l'erreur : `docker-compose logs`
2. Assurez-vous que les ports nécessaires sont disponibles
3. Vérifiez les permissions des répertoires montés

#### Problème : Les données ne sont pas téléchargées

**Solution** :
1. Vérifiez votre connexion Internet
2. Vérifiez les URLs dans le fichier `.env`
3. Consultez les logs détaillés : `docker-compose logs script-executor`

#### Problème : Les rapports ne sont pas générés

**Solution** :
1. Vérifiez que le répertoire `results/` existe et est accessible en écriture
2. Vérifiez que les données ont été correctement importées
3. Vérifiez les logs pour identifier des erreurs SQL : `docker-compose logs script-executor`

---

## Documentation technique

### Structure du projet

```
.
├── data/                   # Données CSV téléchargées
├── init-scripts/           # Scripts d'initialisation
│   └── init-db.sh          # Initialisation de la base de données
├── results/                # Rapports d'analyse générés
├── services/               # Services Docker
│   ├── data-storage/       # Service de stockage SQLite
│   │   ├── Dockerfile      # Image du service de stockage
│   │   └── entrypoint.sh   # Point d'entrée du service
│   └── script-executor/    # Service d'exécution des scripts
│       ├── Dockerfile      # Image du service d'exécution
│       └── scripts/        # Scripts d'analyse
│           ├── env-loader.sh    # Chargement des variables d'environnement
│           ├── import-data.sh   # Importation des données
│           ├── logging.sh       # Fonctions de logging
│           ├── preprocess-sql.sh # Prétraitement des fichiers SQL
│           ├── run-analyses.sh  # Exécution des analyses
│           └── run-pipeline.sh  # Script principal du pipeline
├── sql/                    # Scripts SQL
│   ├── analyses-ventes.sql # Requêtes d'analyse
│   ├── import-data-template.sql # Template d'importation
│   └── schema.sql          # Schéma de la base de données
├── .env                    # Variables d'environnement
├── docker-compose.yml      # Configuration Docker Compose
├── docker-compose.override.yml # Surcharge pour développement
└── docker-compose.prod.yml # Configuration de production
```

### Description des services

![Modèle conceptuel de données](documents/mcd-schema.svg)

#### Service data-storage

Le service `data-storage` est responsable du stockage persistant des données :

- **Technologie** : SQLite 3
- **Conteneur** : Basé sur Alpine Linux pour une empreinte minimale
- **Persistance** : Volume Docker dédié (`db-data`)
- **Sécurité** : Exécution avec un utilisateur non-root dédié
- **Santé** : Healthcheck vérifiant l'intégrité de la base toutes les 10 secondes

#### Service script-executor

Le service `script-executor` orchestre le pipeline de traitement des données :

- **Technologie** : Scripts Bash avec SQLite pour les requêtes
- **Conteneur** : Basé sur Alpine Linux
- **Dépendances** : SQLite, curl, gettext, bash, tini
- **Montages** : Accès au volume de la base de données et aux répertoires data/ et results/
- **Workflow** : Pipeline séquentiel (initialisation → importation → analyse → rapport)

### Structure de la base de données

La base de données SQLite comporte plusieurs tables organisées selon un modèle relationnel :

#### Tables principales

1. **Produits** :
   - `id_produit` (TEXT) : Identifiant unique du produit (ex: REF001)
   - `nom` (TEXT) : Nom du produit
   - `prix` (REAL) : Prix unitaire du produit
   - `stock` (INTEGER) : Quantité en stock

2. **Magasins** :
   - `id_magasin` (INTEGER) : Identifiant unique du magasin
   - `ville` (TEXT) : Ville où se situe le magasin
   - `nombre_salaries` (INTEGER) : Nombre d'employés du magasin

3. **Ventes** :
   - `id_vente` (INTEGER) : Identifiant auto-incrémenté de la vente
   - `date` (TEXT) : Date de la vente
   - `id_produit` (TEXT) : Référence au produit vendu
   - `id_magasin` (INTEGER) : Référence au magasin où a eu lieu la vente
   - `quantite` (INTEGER) : Quantité vendue

#### Tables d'analyse

1. **AnalysesCA** :
   - `id_analyse` (INTEGER) : Identifiant auto-incrémenté de l'analyse
   - `date_analyse` (TEXT) : Date de réalisation de l'analyse
   - `periode` (TEXT) : Période couverte par l'analyse
   - `ca_total` (REAL) : Chiffre d'affaires total calculé

2. **AnalysesParProduit** :
   - `id_analyse` (INTEGER) : Identifiant auto-incrémenté de l'analyse
   - `date_analyse` (TEXT) : Date de réalisation de l'analyse
   - `id_produit` (TEXT) : Référence au produit analysé
   - `quantite_totale` (INTEGER) : Quantité totale vendue
   - `ca_produit` (REAL) : Chiffre d'affaires du produit

3. **AnalysesParVille** :
   - `id_analyse` (INTEGER) : Identifiant auto-incrémenté de l'analyse
   - `date_analyse` (TEXT) : Date de réalisation de l'analyse
   - `ville` (TEXT) : Ville analysée
   - `quantite_totale` (INTEGER) : Quantité totale vendue
   - `ca_ville` (REAL) : Chiffre d'affaires de la ville

#### Vue

- **Vue_VentesCompletes** : Vue joignant les tables Ventes, Produits et Magasins pour faciliter les analyses

#### Diagramme de la base de données



### Scripts et processus

Le pipeline d'analyse est composé de plusieurs scripts exécutés séquentiellement :

1. **init-db.sh** :
   - Initialise la base de données SQLite
   - Applique le schéma de base de données
   - Configure les paramètres SQLite pour des performances optimales

2. **preprocess-sql.sh** :
   - Prétraite les templates SQL en substituant les variables d'environnement
   - Génère le script d'importation final

3. **import-data.sh** :
   - Télécharge les fichiers CSV depuis les URLs configurées
   - Importe les données dans la base de données
   - Gère les erreurs de téléchargement et d'importation

4. **run-analyses.sh** :
   - Exécute les requêtes SQL d'analyse
   - Génère les rapports formatés dans le dossier results/
   - Affiche les résultats à la fois dans le terminal et dans les fichiers

5. **run-pipeline.sh** :
   - Script principal orchestrant l'ensemble du processus
   - Gère la progression et les erreurs
   - Exécute séquentiellement les étapes du pipeline

---

## Guides d'extension

### Ajout de nouvelles analyses

Pour ajouter une nouvelle analyse au système, suivez ces étapes :

1. **Modification du script SQL d'analyse** (`sql/analyses-ventes.sql`) :

   Ajoutez votre nouvelle requête d'analyse en suivant le modèle existant :

   ```sql
   -- ========================================================================
   -- NOUVELLE ANALYSE: [NOM DE L'ANALYSE]
   -- ========================================================================

   -- Créer une table temporaire pour stocker les résultats
   CREATE TEMPORARY TABLE IF NOT EXISTS temp_nouvelle_analyse AS
   SELECT 
       -- Vos colonnes et calculs ici
   FROM 
       -- Tables et jointures
   WHERE 
       -- Conditions
   GROUP BY 
       -- Groupement
   ORDER BY 
       -- Tri
   ;

   -- Optionnel: Enregistrer l'analyse dans une table dédiée
   INSERT INTO [TableAnalyse] (date_analyse, autres_colonnes)
   SELECT 
       datetime('now'),
       -- Autres colonnes
   FROM 
       temp_nouvelle_analyse;
   ```

2. **Mise à jour du script de génération de rapport** (`services/script-executor/scripts/run-analyses.sh`) :

   Ajoutez une nouvelle section pour afficher les résultats de votre analyse :

   ```bash
   echo ""
   generate_section_terminal "TITRE DE VOTRE ANALYSE" \
       "SELECT 
           colonne1 AS 'LIBELLÉ 1', 
           colonne2 AS 'LIBELLÉ 2',
           -- Autres colonnes
       FROM temp_nouvelle_analyse;"

   generate_section_file "TITRE DE VOTRE ANALYSE" \
       "SELECT 
           colonne1 AS 'LIBELLÉ 1', 
           colonne2 AS 'LIBELLÉ 2',
           -- Autres colonnes
       FROM temp_nouvelle_analyse;" \
       "$RESULTS_FILE"
   ```

3. **Tester votre nouvelle analyse** :

   ```bash
   docker-compose restart script-executor
   ```

### Intégration de nouvelles sources de données

Pour ajouter une nouvelle source de données (par exemple, un nouveau fichier CSV) :

1. **Ajout des variables d'environnement** dans le fichier `.env` :

   ```
   URL_NOUVELLE_SOURCE=https://example.com/nouvelle_source.csv
   NOUVELLE_SOURCE_FILE=nouvelle_source.csv
   ```

2. **Modification du script de prétraitement SQL** (`sql/import-data-template.sql`) :

   Ajoutez une nouvelle section pour l'importation de vos données :

   ```sql
   -- Importation de la nouvelle source
   .mode csv
   .headers on
   .import '${DATA_DIR}/${NOUVELLE_SOURCE_FILE}' temp_nouvelle_source

   -- Créer une table temporaire avec les bons noms de colonnes
   CREATE TEMPORARY TABLE temp_nouvelle_source_clean AS
   SELECT 
       "Colonne 1" AS colonne1,
       "Colonne 2" AS colonne2
   FROM temp_nouvelle_source;

   -- Insérer dans la table principale
   INSERT OR REPLACE INTO VotreTable (colonne1, colonne2)
   SELECT colonne1, colonne2 FROM temp_nouvelle_source_clean;

   -- Supprimer les tables temporaires
   DROP TABLE temp_nouvelle_source;
   DROP TABLE temp_nouvelle_source_clean;
   ```

3. **Mise à jour du script d'importation** (`services/script-executor/scripts/import-data.sh`) :

   Ajoutez votre nouvelle source à la liste des téléchargements :

   ```bash
   downloads=(
       "$URL_PRODUITS:$DATA_DIR/$PRODUITS_FILE:produits"
       "$URL_MAGASINS:$DATA_DIR/$MAGASINS_FILE:magasins"
       "$URL_VENTES:$DATA_DIR/$VENTES_FILE:ventes"
       "$URL_NOUVELLE_SOURCE:$DATA_DIR/$NOUVELLE_SOURCE_FILE:nouvelle_source"
   )
   ```

### Personnalisation des rapports

Pour personnaliser le format des rapports générés :

1. **Modification du script de génération** (`services/script-executor/scripts/run-analyses.sh`) :

   - Modifiez la fonction `add_report_header` pour changer l'en-tête du rapport
   - Modifiez la fonction `separator` pour changer les séparateurs visuels
   - Ajustez les requêtes SQL dans les fonctions `generate_section_terminal` et `generate_section_file`

2. **Création d'un format de sortie alternatif** (par exemple, CSV ou HTML) :

   Créez une nouvelle fonction de génération dans `run-analyses.sh` :

   ```bash
   generate_section_csv() {
       local title=$1
       local query=$2
       local output_file=$3
       local csv_file="${output_file%.txt}.csv"
       
       # En-tête du fichier CSV
       echo "# $title" > "$csv_file"
       
       # Exécution SQL avec sortie CSV
       sqlite3 -batch -csv -header "$DB_PATH" <<EOF >> "$csv_file"
       .read $ANALYSES_SQL
       $query
   EOF
   }
   ```

   Appelez ensuite cette fonction pour chaque section que vous souhaitez exporter en CSV.

---

## Glossaire et FAQ

### Termes techniques

- **Docker** : Plateforme de conteneurisation permettant d'empaqueter une application et ses dépendances
- **Docker Compose** : Outil pour définir et exécuter des applications Docker multi-conteneurs
- **SQLite** : Système de gestion de base de données relationnelle léger et autonome
- **CSV** : Format de fichier texte représentant des données tabulaires (Comma-Separated Values)
- **Chiffre d'affaires (CA)** : Somme des ventes réalisées
- **Pipeline** : Séquence d'étapes de traitement des données

### FAQ

#### Comment modifier les sources de données ?

Vous pouvez modifier les URLs des sources dans le fichier `.env` en ajustant les variables `URL_PRODUITS`, `URL_MAGASINS` et `URL_VENTES`.

#### Est-il possible d'ajouter de nouveaux types d'analyses ?

Oui, vous pouvez ajouter de nouvelles requêtes SQL dans le fichier `sql/analyses-ventes.sql` et mettre à jour le script `run-analyses.sh` pour afficher les résultats.

#### Comment augmenter le niveau de détail des logs ?

Modifiez la variable `LOG_LEVEL` dans le fichier `.env` :
- 0 : Minimal (erreurs et succès uniquement)
- 1 : Normal (informations standard)
- 2 : Verbose (informations détaillées)
- 3 : Debug (toutes les informations)

#### Comment configurer le système pour la production ?

Utilisez le fichier `docker-compose.prod.yml` :
```bash
docker-compose -f docker-compose.yml -f docker-compose.prod.yml up -d
```

#### Est-il possible d'exporter les données vers d'autres formats ?

Actuellement, le système génère des rapports au format texte, mais vous pouvez facilement étendre le script `run-analyses.sh` pour exporter vers d'autres formats comme CSV, HTML ou JSON.

---

## Annexes

### Variables d'environnement

Toutes les variables configurables du système sont définies dans le fichier `.env` :

| Variable | Description | Valeur par défaut |
|----------|-------------|-------------------|
| `SQLITE_DB_NAME` | Nom du fichier de base de données | ventes.db |
| `DB_PATH` | Chemin complet vers la base de données | /app/database/${SQLITE_DB_NAME} |
| `SQL_DIR` | Répertoire des scripts SQL | /app/sql |
| `DATA_DIR` | Répertoire des données CSV | /app/data |
| `RESULTS_DIR` | Répertoire des rapports | /app/results |
| `URL_PRODUITS` | URL du fichier CSV des produits | docs.google.com/... |
| `URL_MAGASINS` | URL du fichier CSV des magasins | docs.google.com/... |
| `URL_VENTES` | URL du fichier CSV des ventes | docs.google.com/... |
| `LOG_LEVEL` | Niveau de détail des logs | 2 (verbose) |
| `USE_COLORS` | Activation des couleurs dans les logs | 1 (activé) |

### Exemples de requêtes SQL

Voici quelques exemples de requêtes SQL utiles pour explorer manuellement les données :

```sql
-- Liste des produits les plus vendus
SELECT 
    p.id_produit, 
    p.nom, 
    SUM(v.quantite) AS quantite_totale
FROM 
    Ventes v
JOIN 
    Produits p USING(id_produit)
GROUP BY 
    p.id_produit
ORDER BY 
    quantite_totale DESC;

-- Chiffre d'affaires par jour
SELECT 
    v.date, 
    SUM(v.quantite * p.prix) AS chiffre_affaires
FROM 
    Ventes v
JOIN 
    Produits p USING(id_produit)
GROUP BY 
    v.date
ORDER BY 
    v.date;

-- Performance des magasins par rapport à leur taille
SELECT 
    m.ville,
    m.nombre_salaries,
    COUNT(DISTINCT v.id_vente) AS nombre_ventes,
    SUM(v.quantite * p.prix) AS chiffre_affaires,
    ROUND(SUM(v.quantite * p.prix) / m.nombre_salaries, 2) AS ca_par_salarie
FROM 
    Ventes v
JOIN 
    Produits p USING(id_produit)
JOIN 
    Magasins m USING(id_magasin)
GROUP BY 
    m.id_magasin
ORDER BY 
    ca_par_salarie DESC;
```

### Plan de développement futur

Voici les axes d'amélioration envisagés pour les prochaines versions du système :

1. **Enrichissement des analyses** :
   - Analyse temporelle (variations par jour de la semaine, tendances)
   - Analyses croisées produits/magasins
   - Prévisions de ventes

2. **Amélioration de l'interface** :
   - Ajout d'une interface web pour visualiser les rapports
   - Tableaux de bord interactifs
   - Graphiques et visualisations

3. **Optimisations techniques** :
   - Mise en place d'une API REST pour accéder aux données
   - Support de bases de données alternatives (PostgreSQL, MySQL)
   - Automatisation des analyses périodiques

4. **Extensions fonctionnelles** :
   - Support de l'export vers différents formats (Excel, PDF, CSV)
   - Alertes sur des seuils définis
   - Intégration avec des outils de BI