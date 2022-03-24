# BIKE_DeSIGeo
Projet BIKE pour le Mastère DeSIGeo ENSG CNAM

# Rep src : Fichiers Sources
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

Ces fichiers ont été intégré dans git via l'outil "[Git Large File Storage](https://docs.github.com/en/repositories/working-with-files/managing-large-files)"


# Rep sql : Scripts SQL
- ETL SQL principal : L'ensemble des instructions de création des tables : 
  - [exploreDataBIKE.sql](sql/exploreDataBIKE.sql)

# Rep etl : Fichiers Intermédiaires de Transformation
- Table des longueurs de segment, pour export et traitement dans Tableau (réécriture en CSV du fichier BNAC / Geovelo) : 
  - [france-20211201.csv](etl/france-20211201.csv) (SQL_2.1.1)
- Table des points extrémités, pour export et traitement dans Tableau : 
  - [etl/france-20211201-ext-points.csv](etl/france-20211201-ext-points.csv)

# Rep out : Fichiers de résultat
