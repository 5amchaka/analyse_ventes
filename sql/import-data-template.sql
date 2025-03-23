-- Script SQL pour l'importation des données CSV dans la base de données SQLite
-- Ce script gère l'importation des produits, magasins et ventes avec gestion des doublons

-- IMPORTANT: Ce fichier est un template qui sera préprocessé par le script shell
-- pour remplacer les chemins par leurs valeurs réelles

-- Importation des produits
.mode csv
.headers on
.import '${DATA_DIR}/${PRODUITS_FILE}' temp_produits

-- Supprimer la table temporaire si elle existe déjà
DROP TABLE IF EXISTS temp_produits_clean;

-- Créer une table temporaire avec les bons noms de colonnes
CREATE TEMPORARY TABLE temp_produits_clean AS
SELECT 
    "ID Référence produit" AS id_produit, 
    Nom AS nom, 
    Prix AS prix, 
    Stock AS stock
FROM temp_produits;

-- Insérer ou mettre à jour les données dans la table principale
INSERT OR REPLACE INTO Produits (id_produit, nom, prix, stock)
SELECT id_produit, nom, prix, stock FROM temp_produits_clean;

-- Supprimer les tables temporaires
DROP TABLE temp_produits;
DROP TABLE temp_produits_clean;

-- Importation des magasins
.mode csv
.headers on
.import '${DATA_DIR}/${MAGASINS_FILE}' temp_magasins

-- Supprimer la table temporaire si elle existe déjà
DROP TABLE IF EXISTS temp_magasins_clean;

-- Créer une table temporaire avec les bons noms de colonnes
CREATE TEMPORARY TABLE temp_magasins_clean AS
SELECT 
    "ID Magasin" AS id_magasin, 
    Ville AS ville, 
    "Nombre de salariés" AS nombre_salaries
FROM temp_magasins;

-- Insérer ou mettre à jour les données dans la table principale
INSERT OR REPLACE INTO Magasins (id_magasin, ville, nombre_salaries)
SELECT id_magasin, ville, nombre_salaries FROM temp_magasins_clean;

-- Supprimer les tables temporaires
DROP TABLE temp_magasins;
DROP TABLE temp_magasins_clean;

-- Importation des ventes avec gestion des doublons
.mode csv
.headers on
.import '${DATA_DIR}/${VENTES_FILE}' temp_ventes

-- Supprimer la table temporaire si elle existe déjà
DROP TABLE IF EXISTS temp_ventes_clean;

-- Créer une table temporaire avec les bons noms de colonnes
CREATE TEMPORARY TABLE temp_ventes_clean AS
SELECT 
    Date AS date, 
    "ID Référence produit" AS id_produit, 
    Quantité AS quantite, 
    "ID Magasin" AS id_magasin
FROM temp_ventes;

-- Insérer uniquement les nouvelles ventes 
-- (celles qui n'existent pas déjà dans la base)
INSERT INTO Ventes (date, id_produit, id_magasin, quantite)
SELECT t.date, t.id_produit, t.id_magasin, t.quantite
FROM temp_ventes_clean t
WHERE NOT EXISTS (
    SELECT 1 FROM Ventes v 
    WHERE v.date = t.date 
      AND v.id_produit = t.id_produit 
      AND v.id_magasin = t.id_magasin 
      AND v.quantite = t.quantite
);

-- Supprimer les tables temporaires
DROP TABLE temp_ventes;
DROP TABLE temp_ventes_clean;