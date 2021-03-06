-------------------------------------------
--    Projet BIKE / DeSIGeo / ENSG        -
--    2021-2022   --  Février-Mai 2022    -
--    Pascal Vuylsteker et David Delord   -
-------------------------------------------
-- Analyse des amaganements cyclable décrit dans la BNAC
-- Base Nationale des Aménagements Cyclables
-- Exportée à partir de openstreetmap par Geovelo

-- ATTENTION
-- Suite aux tests réalisés en mars 2022, nous avons découvert des erreur dans les champs ame
-- du fichier produit par Geovelo.
-- Nous avons alors décidé de revenir au fichier source france-20211201.geojson de décembre 2021
-- et de réaliser l'ensemble de nos opérations à partir de ce fichier
-- les valeurs correctes estimées sont prefixées de 'was' (quand les données de mars sont affichée) 
-- ou '-- new_dec_2021' quand il s'agit de nouveau calcul, non encore réalisé en Décembre

-- Alimentation de PostgreSQL par QGIS, après export pour conversion de SRID
-- BDD de départ : france-20220301_Lambert93.geojson (was france-20211201.geojson) passé par QGis pour être stocké dans bike.geovelo
-- Source: https://transport.data.gouv.fr/datasets/amenagements-cyclables-france-metropolitaine/


-- Exploration initial du jeu de donnée
SELECT postgis_full_version();  -- Travail réalisé avec POSTGIS="3.1.3 008d2db" [EXTENSION] PGSQL="140" GEOS="3.9.1-CAPI-1.14.2" PROJ="8.0.0" LIBXML="2.9.10" LIBJSON="0.15"
SELECT version(); -- PostgreSQL 14.0 on x86_64-apple-darwin20.6.0, compiled by Apple clang version 12.0.0 (clang-1200.0.32.29), 64-bit
-- SQL_1.1
SELECT COUNT(*) FROM bike.geovelo; -- 303880 (was 318852 segements : GeoVelo a ajouté certainnes contraintes sur l'export qui a réduit la quantité de segment)
-- SQL_1.2
SELECT SUM(ST_length(geom)) FROM bike.geovelo;  -- 62 651 601.08 (was 61 862 994.64188122 devrait être 73 406 000 m)
SELECT ST_length(geom) FROM bike.geovelo;
-- SQL_1.3
SELECT ST_length(geom), id_osm FROM bike.geovelo ORDER BY ST_length(geom) DESC LIMIT 100;

SELECT COUNT(DISTINCT(code_com_d)) FROM bike.geovelo -- 12521 (was 13159)  -- new_dec_2021 13158
SELECT COUNT(DISTINCT(code_com_g)) FROM bike.geovelo  -- 12505 (was 13153) -- new_dec_2021 13152


-- Au 1er janvier 2022 , la France compte 34 954 communes dont 34 825 en France métropolitaine et 129 dans les DOM
-- https://fr.wikipedia.org/wiki/Liste_des_communes_nouvelles_cr%C3%A9%C3%A9es_en_2022
-- Nombre total de communes en contact avec des aménagements cyclables : 12609 sur 34954 (34825  hors DOM): 36% de communes ont des aménagement cyclables
-- new_dec_2021 
-- ATTENTION Cf SQL_6.4.4  : le nombre correct est 12957 après nettoyage des aménagement 'AUCUN' du coté de certaine communes
-- Nombre total de communes en contact avec des aménagements cyclables : 13230 sur 34954 (34825  hors DOM): 38% de communes ont des aménagement cyclables
-- SQL_1.4
SELECT COUNT(DISTINCT(code_com2)) FROM (
	SELECT code_com_d AS code_com 
	FROM bike.geovelo 		
UNION
	SELECT code_com_g AS code_com 
	FROM bike.geovelo 	
) AS code_com2;        -- 12609     -- new_dec_2021 13230

SELECT COUNT(DISTINCT(code_com2)) FROM (
	SELECT code_com_d AS code_com 
	FROM bike.geovelo 	
	WHERE (ame_d = 'AUCUN')
UNION
	SELECT code_com_g AS code_com 
	FROM bike.geovelo 	
	WHERE (ame_g = 'AUCUN')
) AS code_com2;       -- new_dec_2021 3809  => 13230 est surestimé !!!!
-- le bon nombre de commune est donné en SQL_6.4.4  : 12957
-- 13 230-12 957 => 273
-- Hypothèse: 273 communes sont adjacentes à une chaussée équipée d'un aménagement cyclable du coté 
-- de la commune voisine, mais ne sont pas elle  équipé du moindre aménagement cyclable
--- -- new_dec_2021 12957

-- Table des longueurs de segment, pour export et traitement dans Tableau
-- SQL_2.1.1
DROP TABLE IF EXISTS bike.geovelo_with_length;
CREATE TABLE bike.geovelo_with_length AS (
	SELECT *, round((ST_length(geom)*100))/100 AS longueur
	FROM bike.geovelo gg 
);
-- COPY bike.geovelo_with_length TO '/Users/pascalvuylsteker/DESIGEO_HOME/ProjetBIKE/france-20220301.csv' DELIMITER ',' CSV HEADER; 
-- COPY bike.geovelo_with_length TO '/Users/pascalvuylsteker/DESIGEO_HOME/ProjetBIKE/france-20211201.csv' DELIMITER ',' CSV HEADER; 
COPY bike.geovelo_with_length TO '/Users/pascalvuylsteker/DESIGEO_HOME/ProjetBIKE/BIKE_DeSIGeo_git/etl/france-20211201.csv' DELIMITER ',' CSV HEADER; 

-- Table des points extrémités, pour export et traitement dans Tableau
-- SQL_2.1.2
DROP TABLE IF EXISTS bike.geovelo_ext_points;
CREATE TABLE bike.geovelo_ext_points AS (
	SELECT 	id, id_osm, round((ST_length(geom)*100))/100 AS longueur,
		code_com_d, ame_d, sens_d, code_com_g, ame_g, sens_g,
-- 		ST_AsText(ST_StartPoint(geom)) AS startpoint, ST_AsText(ST_EndPoint(geom)) AS endtpoint
		ST_StartPoint(geom) AS startpoint, 
		ST_EndPoint(geom) AS endtpoint
	FROM bike.geovelo gg 
);
-- COPY bike.geovelo_ext_points TO '/Users/pascalvuylsteker/DESIGEO_HOME/ProjetBIKE/france-20220301-ext-points.csv' DELIMITER ',' CSV HEADER; 
COPY bike.geovelo_ext_points TO '/Users/pascalvuylsteker/DESIGEO_HOME/ProjetBIKE/BIKE_DeSIGeo_git/etl/france-20211201-ext-points.csv' DELIMITER ',' CSV HEADER; 

 
-- SQL_2.2
--- Question sur la longueur des segments
-- Line de longueur mal évaluées (moins de 0.1 m)  -- 4 (was 337 segments sont concernés en decembre)
SELECT ST_length(geom), id_osm, geom FROM bike.geovelo 
WHERE ST_length(geom) <0.1
ORDER BY ST_length(geom) ASC;
-- Line de longueur mal évaluées (moins de 1 m)  -- 140 (was 1348 segments sont concernés en decembre)
SELECT ST_length(geom), id_osm, geom FROM bike.geovelo 
WHERE ST_length(geom) <1
ORDER BY ST_length(geom) ASC;
-- Line de longueur mal évaluées (entre 1 et 2 m)  -- 703 (1488 segments sont concernés en decembre)
SELECT ST_length(geom), id_osm, geom FROM bike.geovelo 
WHERE (ST_length(geom) <2) AND (ST_length(geom) >=1)
ORDER BY ST_length(geom) ASC;
-- Line de longueur mal évaluées (entre 2 et 3 m)  -- 1475 (2099 segments sont concernés  en decembre)
SELECT ST_length(geom), id_osm, geom FROM bike.geovelo 
WHERE (ST_length(geom) <3) AND (ST_length(geom) >=2)
ORDER BY ST_length(geom) ASC;
-- Line de longueur >= 10km  -- 35 (3 segments sont concernés en decembre)
SELECT ST_length(geom), id_osm, geom FROM bike.geovelo 
WHERE  (ST_length(geom) >=10000)
ORDER BY ST_length(geom) ASC;

--- End Partie exploratoire préliminaire


-- Budget des communes telechargée de impot.gouv. Compilation réalisée par Christian Quest
-- https://www.data.gouv.fr/fr/datasets/comptes-individuels-des-communes
-- http://data.cquest.org/dgfip_comptes_collectivites/communes/
-- Dernière année disponible : 2018
-- SQL_3.1.1
DROP TABLE IF EXISTS bike.budget;
CREATE TABLE bike.budget 
(annee INTEGER, dep varchar(3), depcom varchar(5), commune varchar(64), population INTEGER, 
produits_total INTEGER, prod_impots_locaux INTEGER, prod_autres_impots_taxes INTEGER, prod_dotation INTEGER, charges_total INTEGER, 
charges_personnel INTEGER, charges_achats INTEGER, charges_financieres INTEGER, charges_contingents INTEGER, charges_subventions INTEGER, 
resultat_comptable INTEGER, invest_ressources_total INTEGER, invest_ress_emprunts INTEGER, invest_ress_subventions INTEGER, 
invest_ress_fctva INTEGER, invest_ress_retours INTEGER, invest_emplois_total INTEGER, invest_empl_equipements INTEGER, 
invest_empl_remboursement_emprunts INTEGER, invest_empl_charges INTEGER, invest_empl_immobilisations INTEGER, 
excedent_brut INTEGER, cap_autofinancement INTEGER, cap_autofinancement_nette INTEGER, dette_encours_total INTEGER, dette_encours_bancaire INTEGER, 
avance_tresor INTEGER, dette_annuite INTEGER, fond_de_roulement INTEGER, taxe_habitation INTEGER, taxe_habitation_base INTEGER, 
taxe_foncier_bati INTEGER, taxe_foncier_bati_base INTEGER, taxe_non_bati INTEGER, taxe_non_bati_base INTEGER, taxe_add_non_bati INTEGER, 
taxe_add_non_bati_base INTEGER, cotis_fonciere_entreprises INTEGER, cotis_fonciere_entreprises_base INTEGER, cotisation_valeur_ajoutee_entreprises INTEGER, 
impot_forfait_entreprise_reseau INTEGER, taxe_surf_commerciales INTEGER, compensation_relais_2010 INTEGER, taxe_professionnelle INTEGER, 
taxe_professionnelle_base INTEGER, produits_fonctionnement_caf INTEGER, charges_fonctionnement_caf INTEGER, encours_bancaire_net_solde_fonds_toxiques INTEGER)

-- COPY bike.budget FROM '/Users/pascalvuylsteker/DESIGEO_HOME/ProjetBIKE/2018.csv' DELIMITER ',' CSV HEADER; 
COPY bike.budget FROM '/Users/pascalvuylsteker/DESIGEO_HOME/ProjetBIKE/BIKE_DeSIGeo_git/src/2018.csv' DELIMITER ',' CSV HEADER; 

-- SQL_3.1.2
SELECT COUNT(*) FROM bike.budget; -- 35595 communes en 2018
-- Au 1er janvier 2022 , la France compte 34 954 communes dont 34 825 en France métropolitaine et 129 dans les DOM
SELECT annee, dep, depcom, commune, population, produits_total FROM bike.budget;
-- communes par département
SELECT b.dep, COUNT(*) FROM bike.budget b GROUP BY b.dep ORDER BY  b.dep;  -- vérification 101 départments

-- SQL_3.2.1 Budget Total par habitant
ALTER TABLE bike.budget ADD COLUMN produit_population bigint;  -- budget total par habitant
SELECT annee, dep, depcom, commune, population, produits_total, cast(1000 as bigint)*produits_total/population AS produit_population
FROM bike.budget WHERE population>0 ORDER BY produit_population;

-- produits_total est en millier d'euro d ou la multiplication. 'produit_population' est le budget par habitant (en euro/habitant)
UPDATE bike.budget SET produit_population = cast(1000 as bigint)*produits_total/population WHERE population>0;

SELECT annee, dep, depcom, commune, population, produits_total, produit_population 
FROM bike.budget WHERE population>0 AND commune = 'ORSAY' ORDER BY produit_population;
-- Vérification : 2018	"91"	"91471"	"ORSAY"	16856	25537	1515 à comparer avec https://www.impots.gouv.fr/cll/zf1/communegfp/flux.ex

---- Fin de la partie Budget

----  DEPARTEMENT (Source INSEE : https://www.insee.fr/fr/information/5057840)
-- SQL_4.1
DROP TABLE IF EXISTS bike.departement;
CREATE TABLE IF NOT EXISTS bike.departement
(
    dep char(3) NOT NULL,
    region char(2),
    cheflieu char(5),
    tncc INTEGER,
    nom_maj character varying(200),
    nom character varying(200),
    nom_long character varying(200),
	CONSTRAINT dep PRIMARY KEY (dep)
) TABLESPACE pg_default;
ALTER TABLE bike.departement
    OWNER to postgres;
COPY bike.departement 
	FROM '/Users/pascalvuylsteker/DESIGEO_HOME/ProjetBIKE/BIKE_DeSIGeo_git/src/insee/cog_ensemble_2021_csv/departement2021.csv' 
	DELIMITER ',' CSV HEADER; 

SELECT * FROM bike.departement;
-- SELECT * FROM bike.departement WHERE nom != nom_long;


---------------------------------------------------
-- Analyse de l'export complet France de Geovelo
-- Stockage dans bike.resultats
-- Table de résultats
-- SQL_5.1
CREATE TABLE IF NOT EXISTS bike.resultats
(
    nom character(255) COLLATE pg_catalog."default" NOT NULL,
    valeur numeric,
    comment text COLLATE pg_catalog."default",
    ref character varying(16) COLLATE pg_catalog."default" NOT NULL,
    dep character(5) COLLATE pg_catalog."default"
);

DELETE FROM bike.resultats WHERE ref = 'fr_total_seg';
INSERT INTO bike.resultats (nom, valeur, comment, ref, dep)
VALUES ('France Total Segments', 
			( 	SELECT COUNT(*) FROM bike.geovelo ),  -- 303880 segments
			'Nombre Total de Segments comptés pour tout type d amenagement, sur la France entière, source Geovelo',
			'fr_total_seg',
			'fr');
			
DELETE FROM bike.resultats WHERE ref = 'fr_total_km';
DELETE FROM bike.resultats WHERE ref = 'fr_total_m';
INSERT INTO bike.resultats (nom, valeur, comment, ref, dep)
VALUES ('France Total Segments', 
			( 	SELECT SUM(ST_length(geom)) FROM bike.geovelo ),  -- 62651601.08358008 m
			'Longueur Total de Segments comptés pour tout type d amenagement, sur la France entiere, source Geovelo',
			'fr_total_m',
			'fr');
SELECT COUNT(*) FROM bike.geovelo; -- 303880 segments (was 318 852)




	
-----------------------------------------------------------------------------------------	
-- Associations de AME / Groupement par couple d'amenagement dans table geovelo_two_sides
-- 
-- SQL_6.1.1
DROP TABLE IF EXISTS bike.geovelo_two_sides;
CREATE TABLE bike.geovelo_two_sides AS (
	SELECT COUNT(*) AS nombre, CAST(round(COUNT(*)*10000/(SELECT valeur FROM bike.resultats WHERE ref = 'fr_total_seg'))/100 AS DOUBLE PRECISION) AS pourcent_seg,
		round(SUM(ST_length(geom))) AS longueur, 
		round(SUM(ST_length(geom))*10000/(SELECT valeur FROM bike.resultats WHERE ref = 'fr_total_m'))/100 AS pourcent_m,
		gg.ame_g, gg.ame_d 
	FROM bike.geovelo gg 
	GROUP BY gg.ame_g, gg.ame_d
	ORDER BY SUM(ST_length(geom)) DESC
);
SELECT * FROM bike.geovelo_two_sides ORDER BY longueur DESC;
SELECT * FROM bike.geovelo gg WHERE ((gg.ame_g = 'PISTE CYCLABLE') AND (gg.ame_d LIKE 'PISTE CYCLABLE'));
SELECT * FROM bike.geovelo gg WHERE ((gg.ame_g IS NULL) AND (gg.ame_d IS NULL));
SELECT * FROM bike.geovelo gg WHERE ((gg.ame_g IS NULL) OR (gg.ame_d IS NULL));






-- Association des AME G+D + GROUP BY sens_d et sens_g  dans table geovelo_two_sides_and_sens
-- Pour exploration data uniquement
-- SQL_6.1.2
DROP TABLE IF EXISTS bike.geovelo_two_sides_and_sens;
CREATE TABLE bike.geovelo_two_sides_and_sens AS (
	SELECT COUNT(*) AS nombre, CAST(round(COUNT(*)*10000/(SELECT valeur FROM bike.resultats WHERE ref = 'fr_total_seg'))/100 AS DOUBLE PRECISION) AS pourcent_seg,
		round(SUM(ST_length(geom))) AS longueur, 
		round(SUM(ST_length(geom))*10000/(SELECT valeur FROM bike.resultats WHERE ref = 'fr_total_m'))/100 AS pourcent_m,
		gg.ame_g, gg.sens_g, gg.ame_d, gg.sens_d, reseau_loc
	FROM bike.geovelo gg 
	GROUP BY gg.ame_g, gg.sens_g, gg.ame_d, gg.sens_d, reseau_loc
	ORDER BY SUM(ST_length(geom)) DESC
);
SELECT * FROM bike.geovelo_two_sides_and_sens b 
	WHERE ((b.sens_g NOT LIKE 'UNIDIRECTIONNEL') OR (b.sens_d NOT LIKE 'UNIDIRECTIONNEL')) 
	ORDER BY longueur DESC;
SELECT * FROM bike.geovelo_two_sides_and_sens b 
	ORDER BY longueur DESC;


-- Exploration un coté à la fois
-- Separation Gauche Droite
-- GGG junction ame, sens, code_com à gauche GAUCHE
-- SQL_6.2.1
DROP TABLE IF EXISTS bike.geovelo_simple_cote;
CREATE TABLE bike.geovelo_simple_cote AS (
	SELECT COUNT(*) AS nombre,
		round(SUM(ST_length(geom))) AS longueur, 
		gg.ame_g AS ame, gg.sens_g AS sens, gg.code_com_g AS code_com, 'G' AS cote
	FROM bike.geovelo gg 
	GROUP BY gg.ame_g, gg.sens_g, gg.code_com_g
	ORDER BY SUM(ST_length(geom)) DESC
);
-- Nombre de junction ame, sens, code_com à gauche
SELECT COUNT(*) FROM bike.geovelo_simple_cote; -- 33977 (was 33 718)

-- DDD junction ame, sens, code_com à droite DROITE PAR COMMUNE!
-- SQL_6.2.2
DROP TABLE IF EXISTS bike.geovelo_simple_cote;
CREATE TABLE bike.geovelo_simple_cote AS (
	SELECT COUNT(*) AS nombre,
		round(SUM(ST_length(geom))) AS longueur, 
		gg.ame_d AS ame, gg.sens_d AS sens, gg.code_com_d AS code_com, 'D' AS cote
	FROM bike.geovelo gg 
	GROUP BY gg.ame_d, gg.sens_d, gg.code_com_d
	ORDER BY SUM(ST_length(geom)) DESC
);
-- Nombre de junction ame, sens, code_com à droite
SELECT COUNT(*) FROM bike.geovelo_simple_cote; -- 30089 (was 29748)

-- UNION des deux cotés Ajout des deux cotés dans une table unique PAR COMMUNE
-- Dans cette table, les aménagements apparaissent potentiellement deux fois par commune
-- On les regroupera dans la table crée plus tard : geovelo_simple
-- SQL_6.2.3
DROP TABLE IF EXISTS bike.geovelo_simple_cote;
CREATE TABLE bike.geovelo_simple_cote AS (
	SELECT COUNT(*) AS nombre,
		round(SUM(ST_length(geom)*100))/100 AS longueur, 
		gg.ame_g AS ame, gg.sens_g AS sens, gg.code_com_g AS code_com, 'G' AS cote
	FROM bike.geovelo gg 
	GROUP BY gg.ame_g, gg.sens_g, gg.code_com_g
	UNION
	SELECT COUNT(*) AS nombre,
		round(SUM(ST_length(geom)*100))/100 AS longueur, 
		gg.ame_d AS ame, gg.sens_d AS sens, gg.code_com_d AS code_com, 'D' AS cote
	FROM bike.geovelo gg 
	GROUP BY gg.ame_d, gg.sens_d, gg.code_com_d
);
SELECT * FROM bike.geovelo_simple_cote;
SELECT COUNT(*) FROM bike.geovelo_simple_cote; -- 64066 (was 63466)  -- Type d'amenagement par commune (double parfois!)
-- verification : total = G + D 

-- SQL_6.2.4 -- Vérification des totaux (avant nettoyage, les linéaires sont le double des segments)
SELECT SUM(nombre) AS nb_lineaire, SUM(longueur) AS longueur_lineaire_total FROM bike.geovelo_simple_cote;
-- verification : nb_lineaire 637 704  / longueur_lineaire_total 123 725 990.0800002

-- linéaire (côté) sans aménagement
-- SQL_6.2.5 -- dimensions des linéaires qui vont être supprimés (ame = 'AUCUN')
-- 101696 linéaires supprimés représentant 13 386 728 m de segments dont un coté ne dispose d'AUCUN aménagement
SELECT SUM(nombre) AS nb_lineaire, SUM(longueur) AS longueur_lineaire_total 
	FROM bike.geovelo_simple_cote
	WHERE ame = 'AUCUN';

-- SQL_6.2.5.2 Mise de coté de ces segments pour Potentiellement en tirer une métrique par commune
DROP TABLE IF EXISTS bike.amenagement_sens_unique;
CREATE TABLE bike.amenagement_sens_unique AS (
SELECT * 
	FROM bike.geovelo_simple_cote
	WHERE ame = 'AUCUN'
);
	

-- Double vérification sur la table d'origine  :
-- nb de Segments avec au plus un amenagement : 101690 -- lineaire = 13 384 852.94 m
-- SQL_6.2.6
SELECT COUNT(*) AS nb_seg_un_ame, round(SUM(ST_length(geom)*100))/100 AS longueur_seg_un_ame 
	FROM bike.geovelo
	WHERE (ame_d = 'AUCUN') OR (ame_g = 'AUCUN');

-- SQL_6.2.7     --  6 segments, longueur linéaire = 1875.03 m, AUCUN à G et à Droite (Bug)
-- BUG des sans aménagements
SELECT COUNT(*) AS nb_seg_un_ame, round(SUM(ST_length(geom)*100))/100 AS longueur_seg_un_ame 
-- SELECT * 
	FROM bike.geovelo
	WHERE (ame_d = 'AUCUN') AND (ame_g = 'AUCUN');

-- SQL_6.2.8 Les Voies Vertes     XXXXXXXXXX. A EXPLORER. XXXXXXX
--  OR : 39234 segments, longueur linéaire = 9 142 429.3 m
-- AND : 37078 segments, longueur linéaire = 8 834 171.26 m
-- (ame_d = 'VOIE VERTE') AND (ame_g NOT LIKE 'VOIE VERTE'); -- 2156
-- 37078 + 2156 = 39234 ()
-- SELECT COUNT(*) AS nb_seg_un_ame, round(SUM(ST_length(geom)*100))/100 AS longueur_seg_un_ame 
-- 39234   -- AND 37078
SELECT * , round(ST_length(geom)*100)/100 AS longueur
	FROM bike.geovelo
--	WHERE (ame_d = 'VOIE VERTE') AND (ame_g = 'VOIE VERTE') -- 37078 segments, longueur linéaire = 8 834 171.26 m
	WHERE (ame_d = 'VOIE VERTE') AND (ame_g NOT LIKE 'VOIE VERTE') -- 2156 seg -- 308 258.04 m
--	WHERE (ame_d = 'VOIE VERTE') AND (ame_g = 'VOIE VERTE') 
--		AND ((sens_d = 'BIDIRECTIONNEL') OR (sens_g = 'BIDIRECTIONNEL')); -- 0 segments, longueur linéaire = 0 m
--	WHERE (ame_d = 'VOIE VERTE') AND (ame_g NOT LIKE 'VOIE VERTE') 
--		AND ((sens_d = 'BIDIRECTIONNEL') ); -- 0 segments, longueur linéaire = 0 m
--		AND ((sens_d = 'UNIDIRECTIONNEL') ); -- 2156 seg -- 308 258.04 m
	ORDER BY round(ST_length(geom)*100)/100   DESC;

-- SQL_6.2.9 -- 1664 segments de moins de 200m pour 91,635 km
SELECT COUNT(*) AS nb_seg_un_ame, round(SUM(ST_length(geom)*100))/100 AS longueur_seg_un_ame
	FROM bike.geovelo
	WHERE (ame_d = 'VOIE VERTE') AND (ame_g NOT LIKE 'VOIE VERTE') AND (round(ST_length(geom)*100)/100 < 200)
	
-- Pas VV : (bande cyclable unidirectionnelle ) https://www.openstreetmap.org/way/225454718 
	-- Pas VV : (passage pieton) https://www.openstreetmap.org/way/194345635
	-- Pas VV : Piste cyclable unidirectionnelle : https://www.openstreetmap.org/way/308765511  
	-- Pas VV : Permet d'accéder à la VV : https://www.openstreetmap.org/way/307415500  
	-- Pas VV : (passage pieton) : 568304223 : https://www.openstreetmap.org/way/568304223
	-- tip : le tag oneway:bicycle semble indiquer l'erreur
	-- Pas VV : (quelques picto au sol) : https://www.openstreetmap.org/way/33457163
	-- Pas VV : (quelques picto au sol) : https://www.openstreetmap.org/way/175324865
	
--	WHERE (ame_g = 'VOIE VERTE') AND (ame_d NOT LIKE 'VOIE VERTE');  -- Inexistant



-- SQL_6.3.1
-- nettoyage des linéaires de type "aucun" -- DELETE 6986  groupe de segment / commune
-- près de 7000 commune avec des aménagement avec un seul coté 
-- ERREUR corrigée : 7000 est le nombre de groupe de segment / commune, pas le nombre de segment
-- 7000 communes contenait au moins un segment de type "AUCUN"
DELETE FROM bike.geovelo_simple_cote WHERE ame = 'AUCUN';


--  Prise en compte des aménagement 'BIDIRECTIONNEL'
-- On ne parle pas ici des voies vertes, dont la bidirectionalité est reproduite artificillement par
-- un encodage (ame Gauche/ame Droite)
-- SQL_6.3.2
ALTER TABLE bike.geovelo_simple_cote ADD COLUMN lineaire double precision;
-- lineaire : compte deux fois la longueur de voie quand la voie est BIDIRECTIONNEL
UPDATE bike.geovelo_simple_cote SET lineaire = longueur WHERE sens='UNIDIRECTIONNEL';  -- 56179
UPDATE bike.geovelo_simple_cote SET lineaire = (longueur*2) WHERE sens='BIDIRECTIONNEL'; -- 301

SELECT count(*), ame_d, code_com_d, ame_g, code_com_g FROM bike.geovelo WHERE (sens_d='BIDIRECTIONNEL') OR (sens_g='BIDIRECTIONNEL') 
GROUP BY ame_d, code_com_d, ame_g, code_com_g ;  -- 309

SELECT * FROM bike.geovelo_simple_cote;
SELECT count(*) FROM bike.geovelo_simple_cote; -- mars22 : 57048   -- new_dec_2021 56480
-- Attention, ce décompte est sans doute double à ce stade
SELECT count(*) FROM bike.geovelo_simple_cote WHERE sens='BIDIRECTIONNEL'; --301

----   XXXXXXXXXXXXXXXXXXXXXXXXXXXXX

-- à comparer à https://randovelo.touteslatitudes.fr/lineaire-amecycl/
-- table des linéaires par amenagement et code commune
-- Le passage de geovelo_simple_cote a geovelo_simple revient à addtitionner les longueurs 
-- gauche et droite pour chaque couple commune/amenagement
-- (Dans geovelo_simple_cote, ils pouvaient occuper deux lignes)
-- SQL_6.4.1
DROP TABLE IF EXISTS bike.geovelo_simple;
CREATE TABLE bike.geovelo_simple AS (
	SELECT ROUND(SUM(gg.longueur)*100)/100 AS longueur_voie, ROUND(SUM(gg.lineaire)*100)/100 AS lineaire_cyclable, 
		gg.ame AS ame, gg.code_com AS code_com
	FROM bike.geovelo_simple_cote gg 
	GROUP BY gg.ame, gg.code_com
	ORDER BY code_com, SUM(gg.lineaire) DESC
);
SELECT * FROM bike.geovelo_simple;

-- SQL_6.4.2
-- Les chiffres brutes les plus objectifs:
-- Linéaire total d'aménagement en France métropolitaine (et en m)
-- Résultats présentés dans Onglet "linéaire France" de 
-- https://docs.google.com/spreadsheets/d/1_bZ3a8YPmeFRE1WyjljdxPkhcoufJF49F1G6NZglBw0/edit?usp=sharing
SELECT gg.ame AS amenagement, SUM(gg.lineaire_cyclable) FROM bike.geovelo_simple gg
GROUP BY gg.ame ORDER BY SUM(gg.lineaire_cyclable) DESC;


-- SQL_6.4.3
-- Verification debug -- 239 communes / 30251  on un linéaire cyclable  différent de la longueur des aménagements ()
-- Il s'agit des communes disposant d'aménagement bidirectionnel (hors VV)
-- à comparer avec les 301 du résultat SQL_6.3.2
-- La différence s'explique par le fait que dans SQL_6.3.2 des communes apparaissent encore deux fois.
-- Il y a donc 301-239 = 62 communes ayants au moins un segment présentant des linéaires cyclables bidirectionels
-- des deux cotés  -- XXXXXXX Pas convaincu de mes propores explications ici
	SELECT ROUND(SUM(gg.longueur)*100)/100 AS longueur_voie, ROUND(SUM(gg.lineaire)*100)/100 AS lineaire_cyclable, 
		gg.code_com AS code_com
	FROM bike.geovelo_simple_cote gg 
	GROUP BY gg.code_com
	HAVING ROUND(SUM(gg.longueur)*100000) != ROUND(SUM(gg.lineaire)*100000)
	ORDER BY code_com, SUM(gg.lineaire) DESC;

-- Nombre de Type d amenagement cyclable par commune (compté  deux fois dans geovelo_simple_cote )
-- total de 25 : 2 * (12 types + 1 NULL) + Diff Unidirectionnel / Bidirectionnel 
SELECT COUNT(*), gg.code_com FROM  bike.geovelo_simple_cote gg 
	GROUP BY gg.code_com ORDER BY  COUNT(*) DESC; -- Max : 25

-- SQL_6.4.4
-- Nombre de Type d amenagement cyclable par commune
-- “Le Saviez Vous?” Sur toute la France, seules 6 villes sont équipées des 12 types d’aménagement cyclables 
-- (Metz, Avignon, Strasbourg, Mulhouse, Toulouse, Nantes)
SELECT COUNT(*), gg.code_com, c.commune FROM  bike.geovelo_simple gg, (SELECT depcom, commune, dep  FROM bike.budget) c
	WHERE (c.depcom = gg.code_com) 
	GROUP BY gg.code_com,c.commune ORDER BY  COUNT(*) DESC; -- 12957 (<> 13230 ?? Regroupement de commune? Cf )

SELECT COUNT(*), c.commune FROM  bike.geovelo_simple gg, (SELECT depcom, commune, dep  FROM bike.budget) c
	WHERE (c.depcom = gg.code_com) 
	GROUP BY c.commune ORDER BY  COUNT(*) DESC; -- 12621 (<> 13230 ?? Regroupement de commune?)


SELECT * FROM bike.geovelo_simple;
SELECT * FROM bike.geovelo_simple WHERE (code_com='67482');
SELECT * FROM bike.geovelo_simple_cote WHERE (code_com='67482');

-- Total linéaire sans pondération / par commune
-- SQL_6.4.5
DROP TABLE IF EXISTS bike.geovelo_total;  
CREATE TABLE bike.geovelo_total AS (
	SELECT ROUND(SUM(gg.lineaire_cyclable)*100)/100 AS lineaire_total, 
		ROUND(SUM(gg.longueur_voie)*100)/100 AS longueur_total, 
		gg.code_com, c.commune, c.dep
	FROM bike.geovelo_simple gg, (SELECT depcom, commune, dep  FROM bike.budget) c
	WHERE (c.depcom = gg.code_com)
	GROUP BY gg.code_com, c.commune, c.dep
	ORDER BY SUM(gg.lineaire_cyclable) DESC
);

SELECT * FROM bike.geovelo_total;  -- mars22 : 12342 -- new_dec_2021 12957

-- Table: bike.poids
-- DROP TABLE bike.poids;
-- SQL_7
DROP TABLE IF EXISTS bike.poids;  
CREATE TABLE IF NOT EXISTS bike.poids
(
    ame character varying(60) COLLATE pg_catalog."default",
    poids bigint
);
COPY bike.poids FROM '/Users/pascalvuylsteker/DESIGEO_HOME/ProjetBIKE/ame_poids.csv' DELIMITER ',' CSV HEADER; 
SELECT * FROM bike.poids;

-- JUNCTION PRINCIPALE
-- junction geovelo_simple avec table commune et table poid et geovelo_total
-- CONSERVATION par AME pour l'instant
-- SQL_7.1
DROP TABLE IF EXISTS bike.geovelo_poids;
CREATE TABLE bike.geovelo_poids AS (
	SELECT a.ame, a.lineaire_cyclable, a.longueur_voie, t.lineaire_total, 
		a.code_com, c.commune, c.population, c.produit_population AS budget_par_habitant, 
		c.dep, d.nom, p.poids
	FROM bike.geovelo_simple a, bike.geovelo_total t, bike.departement d,
		(SELECT depcom, commune, dep, population, produit_population  FROM bike.budget) c, bike.poids p
	WHERE (a.code_com = t.code_com) AND (c.depcom = a.code_com) AND (p.ame = a.ame) AND (c.dep = d.dep)
	ORDER BY t.lineaire_total DESC, a.lineaire_cyclable DESC
);
-- SQL_7.1.1
SELECT * FROM bike.geovelo_poids;
SELECT COUNT(*) FROM bike.geovelo_poids GROUP BY code_com; -- 12895 -- Il y a de la perte 62 communes XXXXX
-- liée à la base commune / budget qui est un peu vielle : 2018

-- Petit control test sur les cas execeptionnels de budget par habitant
SELECT * FROM bike.departement;
SELECT * FROM bike.geovelo_poids WHERE commune LIKE 'VAU%' ORDER BY lineaire_total DESC, lineaire_cyclable DESC;
-- Découverte en phase de visualisation : VAUJANY - La ville de Vaujany a 322 habitants
-- La ville de France ayant le rapport budgt(produits_total/population le plus élevé)
-- https://www.ledauphine.com/isere-sud/2010/02/01/oisans-gros-endettement-mais-grosses-recettes
-- https://www.journaldunet.com/business/budget-ville/vaujany/ville-38527/budget

SELECT produit_population AS budgetParHabitant, * FROM bike.budget 
WHERE population > 1
--ORDER BY invest_ress_emprunts/population DESC;
ORDER BY produit_population DESC;
-- Fin de -- Petit control test


--- Ajout du LINEAIRE PONDÉRÉ (longueur de voie dans une direction pondérées par la qualité)
ALTER TABLE bike.geovelo_poids ADD COLUMN lineaire_pondere double precision;
UPDATE bike.geovelo_poids SET lineaire_pondere = ROUND(lineaire_cyclable * poids*10)/100;  -- Le poids est entre 1 et 10 
-- Linéaire et Linéaire Pondéré même échelle
DELETE FROM bike.geovelo_poids WHERE lineaire_pondere <0.01;  -- Deux (2) valeurs sont supprimées en Decembre

-- ALTER TABLE bike.geovelo_poids ADD COLUMN facteur_qualite double precision;
-- UPDATE bike.geovelo_poids SET facteur_qualite = ROUND(lineaire_cyclable * poid*10)/100;

-- Export contenant tous les type d'aménagement en mode linéaire
-- DANGER la valeur longueur voie n'est pas correcte ici!! (elle a été doublé )
-- et de toute façcon, elle n esert plus ici. Ce qui compte c'est les linéaires
COPY bike.geovelo_poids TO '/Users/pascalvuylsteker/DESIGEO_HOME/ProjetBIKE/geovelo_poids.csv' DELIMITER ',' CSV HEADER; 


--- total par ame
SELECT * FROM bike.geovelo_poids ORDER BY lineaire_total DESC, lineaire_cyclable DESC;

-- XXXXXXXXXXXXXXXXXXXXXXX.  A COMPARER AVEC SQL_7.1.1  XXXXXXXXXXXXXXXXXXXXXX
-- SQL_7.1.2
---   total pondere par ville (on regroupe les aménagement en un total pondéré par commune)
SELECT code_com, commune, dep, 
	ROUND(SUM(lineaire_pondere)*100)/100 AS lineaire_pondere_total,
	ROUND(SUM(lineaire_cyclable)*100)/100 AS lineaire_total,
	ROUND(AVG(lineaire_total)*100)/100 as lineaire_total2 -- lineaire_total et lineaire_total2 sont a peu près identiques, aux arrondis
FROM bike.geovelo_poids
GROUP BY code_com, commune, dep
ORDER BY SUM(lineaire_pondere) DESC;

--SQL_7.1.3 Classement par facteur_qualite 
-- Les petites structures s'en sorte très bien
SELECT code_com, commune, dep, 
	ROUND(SUM(lineaire_pondere)*100)/100 AS lineaire_pondere_total,
	ROUND(SUM(lineaire_cyclable)*100)/100 AS lineaire_total,
	ROUND(100*SUM(lineaire_pondere)/SUM(lineaire_cyclable)) AS facteur_qualite
FROM bike.geovelo_poids
GROUP BY code_com, commune, dep
ORDER BY ROUND(100*SUM(lineaire_pondere)/SUM(lineaire_cyclable)) DESC;

--SQL_7.1.4 Classement par facteur_qualite mis à l'échelle du rapport de la longueur linéaire pondéré la plus importante
-- le coeff de toulouse est multiplié par 1, alors que les petits linéaires sont multipliés par un faible coefficient
-- 
SELECT code_com, commune, dep, 
	ROUND(SUM(lineaire_pondere)*100)/100 AS lineaire_pondere_total,
	ROUND(SUM(lineaire_cyclable)*100)/100 AS lineaire_total,
	ROUND(100*SUM(lineaire_pondere)/674830) AS facteur_qualite_Biais
FROM bike.geovelo_poids
WHERE commune ILIKE '%PARIS%'
GROUP BY code_com, commune, dep
ORDER BY ROUND(100*SUM(lineaire_pondere)/674830) DESC;

---   total pondere par ville avec facteur qualité (rapport pondéré/non pondéré)
SELECT code_com, commune, dep, ROUND(SUM(lineaire_pondere)/SUM(lineaire_cyclable)*100) AS facteur_qualite, 
	ROUND(SUM(lineaire_pondere)*10)/100 AS lineaire_pondere_total, 
	ROUND(SUM(lineaire_cyclable)) AS total_lineaire_cyclable, ROUND(SUM(longueur_voie)) AS total_longueur_voie
FROM bike.geovelo_poids
-- GROUP BY code_com, dep
GROUP BY code_com, commune, dep
ORDER BY SUM(lineaire_pondere) DESC;

---   total pondere par departement
SELECT dep, ROUND(SUM(lineaire_pondere)/SUM(lineaire_cyclable)*100) AS facteur_qualite, 
	ROUND(SUM(lineaire_pondere)*10)/100 AS lineaire_pondere_total 
FROM bike.geovelo_poids
GROUP BY dep
ORDER BY SUM(lineaire_pondere) DESC;

SELECT c.depcom, c.commune FROM bike.budget c


