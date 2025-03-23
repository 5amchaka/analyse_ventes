-- Script de création de la base de données pour l'analyse des ventes
-- Ce script crée les tables nécessaires pour stocker les données de ventes
-- et les résultats des analyses

-- Création de la table Produits
CREATE TABLE IF NOT EXISTS Produits (
    id_produit TEXT PRIMARY KEY,
    nom TEXT NOT NULL,
    prix REAL NOT NULL,
    stock INTEGER NOT NULL
);

-- Création de la table Magasins
CREATE TABLE IF NOT EXISTS Magasins (
    id_magasin INTEGER PRIMARY KEY,
    ville TEXT NOT NULL,
    nombre_salaries INTEGER NOT NULL
);

-- Création de la table Ventes
CREATE TABLE IF NOT EXISTS Ventes (
    id_vente INTEGER PRIMARY KEY AUTOINCREMENT,
    date TEXT NOT NULL,
    id_produit TEXT NOT NULL,
    id_magasin INTEGER NOT NULL,
    quantite INTEGER NOT NULL,
    FOREIGN KEY (id_produit) REFERENCES Produits(id_produit),
    FOREIGN KEY (id_magasin) REFERENCES Magasins(id_magasin)
);

-- Création d'un index sur la date des ventes pour accélérer les requêtes temporelles
CREATE INDEX IF NOT EXISTS idx_ventes_date ON Ventes(date);

-- Création d'index individuels sur id_produit et id_magasin pour indexage sur jointures
CREATE INDEX IF NOT EXISTS idx_ventes_id_produit ON Ventes(id_produit);
CREATE INDEX IF NOT EXISTS idx_ventes_id_magasin ON Ventes(id_magasin);

-- Création d'un index composite sur id_produit et id_magasin pour les analyses
CREATE INDEX IF NOT EXISTS idx_ventes_prod_mag ON Ventes(id_produit, id_magasin);

-- Table pour stocker les analyses de CA total
CREATE TABLE IF NOT EXISTS AnalysesCA (
    id_analyse INTEGER PRIMARY KEY AUTOINCREMENT,
    date_analyse TEXT NOT NULL,
    periode TEXT NOT NULL,
    ca_total REAL NOT NULL
);

-- Table pour stocker les analyses par produit
CREATE TABLE IF NOT EXISTS AnalysesParProduit (
    id_analyse INTEGER PRIMARY KEY AUTOINCREMENT,
    date_analyse TEXT NOT NULL,
    id_produit TEXT NOT NULL,
    quantite_totale INTEGER NOT NULL,
    ca_produit REAL NOT NULL,
    FOREIGN KEY (id_produit) REFERENCES Produits(id_produit)
);

-- Table pour stocker les analyses par ville
CREATE TABLE IF NOT EXISTS AnalysesParVille (
    id_analyse INTEGER PRIMARY KEY AUTOINCREMENT,
    date_analyse TEXT NOT NULL,
    ville TEXT NOT NULL,
    quantite_totale INTEGER NOT NULL,
    ca_ville REAL NOT NULL
);

-- Création d'une vue pour faciliter les analyses
CREATE VIEW IF NOT EXISTS Vue_VentesCompletes AS
SELECT 
    v.id_vente,
    v.date,
    v.quantite,
    p.id_produit,
    p.nom AS nom_produit,
    p.prix AS prix_unitaire,
    (v.quantite * p.prix) AS montant_vente,
    m.id_magasin,
    m.ville,
    m.nombre_salaries
FROM 
    Ventes v
JOIN 
    Produits p USING(id_produit)
JOIN 
    Magasins m USING(id_magasin);