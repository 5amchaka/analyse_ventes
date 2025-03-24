-- ========================================================================
-- 1. ANALYSE DU CHIFFRE D'AFFAIRES TOTAL
-- ========================================================================

-- Requête pour calculer le chiffre d'affaires total
CREATE TEMPORARY TABLE IF NOT EXISTS temp_ca_total AS
SELECT 
    SUM(v.quantite * p.prix) AS chiffre_affaires_total,
    MIN(v.date) AS date_debut,
    MAX(v.date) AS date_fin,
    COUNT(DISTINCT v.id_vente) AS nombre_ventes,
    SUM(v.quantite) AS quantite_totale
FROM 
    Ventes v
JOIN 
    Produits p USING(id_produit);

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
    p.id_produit,
    p.nom,
    SUM(v.quantite) AS quantite_totale,
    SUM(v.quantite * p.prix) AS chiffre_affaires,
    ROUND(SUM(v.quantite * p.prix) * 100.0 / (SELECT chiffre_affaires_total FROM temp_ca_total), 2) AS pourcentage_ca,
    COUNT(DISTINCT v.id_vente) AS nombre_ventes,
    ROUND(AVG(v.quantite), 2) AS quantite_moyenne_par_vente
FROM 
    Ventes v
JOIN 
    Produits p USING(id_produit)
GROUP BY 
    p.id_produit
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
    m.ville,
    SUM(v.quantite) AS quantite_totale,
    SUM(v.quantite * p.prix) AS chiffre_affaires,
    ROUND(SUM(v.quantite * p.prix) * 100.0 / (SELECT chiffre_affaires_total FROM temp_ca_total), 2) AS pourcentage_ca,
    COUNT(DISTINCT v.id_vente) AS nombre_ventes,
    COUNT(DISTINCT p.id_produit) AS nombre_produits_differents,
    ROUND(SUM(v.quantite * p.prix) / m.nombre_salaries, 2) AS ca_par_salarie
FROM 
    Ventes v
JOIN 
    Produits p USING(id_produit)
JOIN 
    Magasins m USING(id_magasin)
GROUP BY 
    m.ville
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