# Données des terrains

Les trois terrains utilisent les tuiles publiques Copernicus DEM GLO-30. Les GeoTIFF ont été découpés et reprojetés en UTM. Les grilles `mnt.csv` contiennent les altitudes en mètres. `relief-carte.png` est un aperçu ombré et projeté pour la carte. Les points de passage ont été choisis pour les exemples.

Les polygones d’eau et les routes proviennent d’OpenStreetMap, via les tuiles vectorielles OpenMapTiles servies par OpenFreeMap. Ils ont été projetés sur la grille UTM du MNT pour `cartographie-grille.png` et dans le repère Web Mercator pour `relief-carte.png`. Le modèle d’altitude Copernicus fournit l’ombrage du terrain. Le fichier `terrain.json` indique la grille UTM et la version des tuiles du fond. [© OpenStreetMap contributors](https://www.openstreetmap.org/copyright) · [© OpenMapTiles](https://openmaptiles.org/) · [OpenFreeMap](https://openfreemap.org/)

| Site | Dalle source | Projection et maille |
| --- | --- | --- |
| Manhattan | [N40 W074](https://copernicus-dem-30m.s3.amazonaws.com/Copernicus_DSM_COG_10_N40_00_W074_00_DEM/Copernicus_DSM_COG_10_N40_00_W074_00_DEM.tif) | EPSG:32618 · 30 m |
| Crozon | [N48 W005](https://copernicus-dem-30m.s3.amazonaws.com/Copernicus_DSM_COG_10_N48_00_W005_00_DEM/Copernicus_DSM_COG_10_N48_00_W005_00_DEM.tif) | EPSG:32630 · 50 m |
| Détroit d’Ormuz | [Six dalles N25 à N27, E055 à E056](ormuz/terrain.json) | EPSG:32640 · 250 m |

Le modèle de surface représente le relief avec les bâtiments et la végétation à la résolution de la grille. [Catalogue des données](https://registry.opendata.aws/copernicus-dem/) · [Licence COP-DEM-GLO-30-F](https://dataspace.copernicus.eu/sites/default/files/media/files/2025-06/copernicus_contributing_mission_data_access_v2_cop_dem_licenses.pdf)

> Produced using Copernicus WorldDEM-30 © DLR e.V. 2010-2014 and © Airbus Defence and Space GmbH 2014-2018 provided under COPERNICUS by the European Union and ESA; all rights reserved.
>
> The organisations in charge of the Copernicus programme by law or by delegation do not incur any liability for any use of the Copernicus WorldDEM-30.

## Fonds du navigateur et des vidéos

Les fonds d’affichage se choisissent indépendamment de la source d’altitude. Dans le navigateur, Leaflet charge les tuiles des fournisseurs. Dans Pharo, `SoSeAtelierBasemap` reprojette le fond sur l’emprise du MNT, à la résolution de la vidéo, et le réemploie pendant toute la lecture et l’export. GDAL et une connexion au service sont requis pour les emprises sans extrait livré.

Les dossiers `fonds/` livrent des extraits remaillés pour le rendu hors ligne. Chaque fichier JSON associé indique le service, la date de récupération, la licence, la grille d’altitude de référence et les dimensions du fond. Un changement de grille demande une nouvelle reprojection.

| Fond | Extraits livrés | Source et crédit |
| --- | --- | --- |
| Plan IGN | Crozon et Vercors | © IGN · Plan IGN, Licence Ouverte 2.0. [Catalogue du Plan IGN](https://www.data.gouv.fr/datasets/plan-ign) |
| USGS Topo | Manhattan (`nyc/fonds/usgsTopo.png`) | Map services and data available from U.S. Geological Survey, National Geospatial Program. [The National Map](https://basemap.nationalmap.gov/arcgis/rest/services/USGSTopo/MapServer) · [Conditions](https://www.usgs.gov/faqs/what-are-terms-uselicensing-map-services-and-data-national-map) |
| Sentinel-2 | Crozon et Vercors | EOxCloudless by EOX IT Services GmbH (Contains modified Copernicus Sentinel data 2016 & 2017). [EOxCloudless](https://cloudless.eox.at/) · [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/) |

Les extraits de Crozon sont dans [crozon/fonds](crozon/fonds/). Les extraits du Vercors accompagnent le [terrain installé par défaut](../installation/rejeu-vercors/terrain-vercors/fonds/).
