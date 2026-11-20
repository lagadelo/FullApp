# Empreinte optique au sol

Deux scènes synthétiques, une urbaine et une montagneuse, visualisent le mouvement d’un drone à caméra verticale. Les pointillés délimitent le carré de référence d’un kilomètre de côté. Les couleurs donnent une estimation de la résolution au sol en mètres par pixel. Les hachures signalent une surface dans le champ qui est masquée par un obstacle ou par le relief.

## Produire les vidéos

Sous Linux, installez Pharo avec Roassal et FFmpeg. Le prototype a été exécuté avec Pharo 13.1 et la version de Roassal incluse dans l’image Pharo. Placez-vous dans le dossier où vous souhaitez obtenir les deux MP4.

```sh
bash /chemin/vers/exporter.sh /chemin/vers/pharo /chemin/vers/Pharo.image
```

Chaque séquence comporte 160 images à 20 images par seconde. `DRONE_DEMO_FRAMES` permet de changer le nombre d’images. Pour générer une seule vidéo à partir d’une surface externe, définissez `DRONE_DEMO_SURFACE` avec le chemin d’un CSV.

```sh
DRONE_DEMO_SURFACE=ma-surface.csv bash /chemin/vers/exporter.sh /chemin/vers/pharo /chemin/vers/Pharo.image
```

La grille définit 180 colonnes par 130 lignes, sans en-tête. Chaque cellule représente 10 m de côté. Les valeurs sont en mètres, positives ou nulles et inférieures à 200 m, avec un point décimal et des virgules comme séparateurs. L’origine de la grille est en haut à gauche de la carte. Utilisez la même origine verticale pour la surface et pour la trajectoire. Une scène urbaine requiert les altitudes de toit, par exemple un modèle numérique de surface ou un modèle de terrain enrichi de hauteurs de bâtiments.

## Projection

À 200 m au-dessus de la référence, la largeur du champ sur une surface plane à l’altitude zéro est de 1 000 m. Une matrice carrée de 2 000 pixels de côté donne environ 0,50 m/px au sol et 0,35 m/px sur un toit horizontal à 60 m. Pour chaque centre de cellule dans le champ de la caméra, le modèle teste si le rayon descendant traverse une cellule qui coupe la ligne de visée. La grille représente les élévations comme des surfaces horizontales par cellule. La résolution des pentes, les façades et la distorsion optique demandent un modèle plus détaillé.

`perception.st` contient la géométrie et le rendu Roassal. `render.st` pilote les scènes image par image. `exporter.sh` assemble les images PNG en MP4 avec FFmpeg.
