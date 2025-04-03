-- ========================================================================
-- 1. ANALYSE DU CHIFFRE D'AFFAIRES TOTAL
-- ========================================================================

-- Requête pour calculer le chiffre d'affaires total
CREATE TEMPORARY TABLE IF NOT EXISTS temp_ca_total AS
SELECT 
    SUM(montant_vente) AS chiffre_affaires_total,
    MIN(date) AS date_debut,
    MAX(date) AS date_fin,
    COUNT(DISTINCT id_vente) AS nombre_ventes,
    SUM(quantite) AS quantite_totale
FROM
    Vue_VentesCompletes;

-- Enregistrer l'analyse dans la table dédiée
INSERT INTO AnalysesCA (date_analyse, periode, ca_total)
SELECT 
    datetime('now'), 
    date_debut || ' au ' || date_fin,
    chiffre_affaires_total
FROM 
    temp_ca_total;

-- ========================================================================
-- 2. ANALYSE DES VENTES PAR PRODUIT
-- ========================================================================

-- Requête pour analyser les ventes par produit
CREATE TEMPORARY TABLE IF NOT EXISTS temp_ca_produits AS
SELECT 
    id_produit,
    nom_produit AS nom,
    SUM(quantite) AS quantite_totale,
    SUM(montant_vente) AS chiffre_affaires,
    ROUND(SUM(montant_vente) * 100.0 / (SELECT chiffre_affaires_total FROM temp_ca_total), 2) AS pourcentage_ca,
    COUNT(DISTINCT id_vente) AS nombre_ventes,
    ROUND(AVG(quantite), 2) AS quantite_moyenne_par_vente
FROM 
    Vue_VentesCompletes
GROUP BY 
    id_produit
ORDER BY 
    chiffre_affaires DESC;

-- Enregistrer l'analyse dans la table dédiée
INSERT INTO AnalysesParProduit (date_analyse, id_produit, quantite_totale, ca_produit)
SELECT 
    datetime('now'),
    id_produit,
    quantite_totale,
    chiffre_affaires
FROM 
    temp_ca_produits;

-- ========================================================================
-- 3. ANALYSE DES VENTES PAR RÉGION (VILLE)
-- ========================================================================

-- Requête pour analyser les ventes par ville
CREATE TEMPORARY TABLE IF NOT EXISTS temp_ca_villes AS
SELECT 
    ville,
    SUM(quantite) AS quantite_totale,
    SUM(montant_vente) AS chiffre_affaires,
    ROUND(SUM(montant_vente) * 100.0 / (SELECT chiffre_affaires_total FROM temp_ca_total), 2) AS pourcentage_ca,
    COUNT(DISTINCT id_vente) AS nombre_ventes,
    COUNT(DISTINCT id_produit) AS nombre_produits_differents,
    ROUND(SUM(montant_vente) / nombre_salaries, 2) AS ca_par_salarie
FROM 
    Vue_VentesCompletes
GROUP BY 
    ville
ORDER BY 
    chiffre_affaires DESC;

-- Enregistrer l'analyse dans la table dédiée
INSERT INTO AnalysesParVille (date_analyse, ville, quantite_totale, ca_ville)
SELECT 
    datetime('now'),
    ville,
    quantite_totale,
    chiffre_affaires
FROM 
    temp_ca_villes;