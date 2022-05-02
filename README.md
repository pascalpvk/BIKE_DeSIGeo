# BIKE_DeSIGeo
Projet BIKE pour le Mastère DeSIGeo ENSG CNAM

[Rapport final](Etude_qualitative_des_pistes_cyclables_de_France.pdf) : [Etude qualitative des pistes cyclables de France ](Etude_qualitative_des_pistes_cyclables_de_France.pdf)

## Rep sql : Scripts SQL
- ETL SQL principal : L'ensemble des instructions de création des tables : 
  - [exploreDataBIKE.sql](sql/exploreDataBIKE.sql)


## Fichiers de résultat sur git, Dropbox et GDrive
- Calculs simples réalisés sous l'application Calca
  - [controleQualite.calca](controleQualite.calca)  
- [Tableaux des résultats principaux](https://docs.google.com/spreadsheets/d/1_bZ3a8YPmeFRE1WyjljdxPkhcoufJF49F1G6NZglBw0/edit?usp=sharing) sous GoogleSheet
- 3 [Expériences intéractives réalisées sous le logiciel Tableau](https://www.dropbox.com/sh/csbe5md0hy5x34t/AAB0_zvNTDqOSJ99PfrVt4p4a?dl=0)
  - [Présentation Principale, avec deux dashboards](https://www.dropbox.com/s/bf2nbxcp8r3tlvz/BIKE-Tableau.twbx?dl=0)
  - [Diagramme de Parreto des segments exportés](https://www.dropbox.com/s/95nhwscq490ev3c/BIKE-Tableau-geovelo-length.twbx?dl=0)
  - [Carte de France avec largeur des aménagements proportionnelle à leur Qualité](https://www.dropbox.com/s/hfwha35xzf1wjd4/BIKE-Tableau-geovelo-carteDeFrance.twbx?dl=0)


## Rep etl : Fichiers Intermédiaires de Transformation
- Table des longueurs de segment, pour export et traitement dans Tableau (réécriture en CSV du fichier BNAC / Geovelo) : 
  - [france-20211201.csv](etl/france-20211201.csv) (SQL_2.1.1)
- Table des points extrémités, pour export et traitement dans Tableau : 
  - [etl/france-20211201-ext-points.csv](france-20211201-ext-points.csv)

# [Bookmarkographie](https://raindrop.io/PascalVuylsteker/projet-pistes-cyclables-bike-21436758)
- Liste de [liens récoltés durant ce projet](https://raindrop.io/PascalVuylsteker/projet-pistes-cyclables-bike-21436758)


## Rep src : Fichiers Sources
- Fichier principal : export BNAC / Geovelo datant de décembre 2021 : 
  - [france-20211201.geojson](src/france-20211201.geojson)
- Fichier exporté sous QGIS pour convertir en LAMBERT 93 : 
  - [france-20211201_Lamber-93.geojson](src/france-20211201_Lamber-93.geojson)
- Budget des communes telechargée de impot.gouv. Compilation réalisée par Christian Quest :
  - [2018.csv](src/2018.csv)
  - [https://www.data.gouv.fr/fr/datasets/comptes-individuels-des-communes](https://www.data.gouv.fr/fr/datasets/comptes-individuels-des-communes)
  - [http://data.cquest.org/dgfip_comptes_collectivites/communes/](http://data.cquest.org/dgfip_comptes_collectivites/communes/)
  - Dernière année disponible : 2018
  - SQL_3.1.1
- Proposition de Poids attribués par type d'aménagement
  - Ce fichier CSV est un export de l'onglet ponderation du [document "Conbinaisons type d'aménagement"](https://docs.google.com/spreadsheets/d/1_bZ3a8YPmeFRE1WyjljdxPkhcoufJF49F1G6NZglBw0/edit?usp=sharing)
  - [ame_poids.csv](src/ame_poids.csv)
- Pour info, le git des exports SQL réalisés par Geovelo pour convertir les information OpenStreetMap vers la classification BNAC
  - [Requêtes Aménagements cyclables](https://gitlab.com/geovelo-public/requetes_amenagements_cyclables) 

Ces fichiers ont été intégré dans git via l'outil "[Git Large File Storage](https://docs.github.com/en/repositories/working-with-files/managing-large-files)"

### Rep src/insee [Fichiers INSEE](https://www.insee.fr/fr/information/5057840)
- Ensemble des différents niveaux
  - [src/insee/cog_ensemble_2021_csv/](src/insee/cog_ensemble_2021_csv/)
- Départements
  - [src/insee/cog_ensemble_2021_csv/departement2021.csv](src/insee/cog_ensemble_2021_csv/departement2021.csv) 

## Rep Rstudio : Script Rstudio et principaux résultats
- Script Rstudio
  - [SCRIPT](https://github.com/pascalpvk/BIKE_DeSIGeo/blob/main/Rstudio/projet_continuite.R)
- Principaux plots obtenus
  - [PLOT](https://github.com/pascalpvk/BIKE_DeSIGeo/tree/main/Rstudio/Plot_resultats)
- Principales ACP obtenues
  - [ACP](https://github.com/pascalpvk/BIKE_DeSIGeo/tree/main/Rstudio/ACP_resultats)




