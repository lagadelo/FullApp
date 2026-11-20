# Perception sur le Vercors

Le parcours forme une boucle de 11,3 km entre la combe de Vassieux, le col de la Chau et les crêtes des Gagères. Ses 14 sommets placent les changements de direction dans la montée au col, le long du rebord occidental et dans la descente vers la combe. Les 20 drones sont répartis à environ 564 m les uns des autres au départ.

`parcours-vercors.geojson` contient les sommets en longitude et latitude WGS 84, dans l’ordre du parcours. Le premier sommet est répété à la fin de l’anneau GeoJSON.

`terrain-vercors` contient le MNT prêt à charger dans Pharo (`terrain.json` et `mnt.csv)) et le même raster en GeoTIFF (`mnt-vercors.tif`). La grille IGN comprend 245 colonnes et 329 lignes au pas de 25 m en Lambert-93 (EPSG:2154). Les altitudes de l’extrait vont de 655 à 1 648 m. Source IGN, RGE ALTI®, service WMS de la Géoplateforme, couche `ELEVATION.ELEVATIONGRIDCOVERAGE.HIGHRES`. [RGE ALTI®](https://www.data.gouv.fr/datasets/rge-alti-r/) · [Les Gagères par le col de la Chau](https://www.drome-cestmanature.com/fiches/le-puy-de-la-gagere-depuis-vassieux-en-vercors/) · [Lieux de mémoire du Vercors](https://www.vercors-resistance.fr/mediatheque/expos-monuments/)

## Rejouer la scène dans Pharo

Décompresse l’archive. Charge `vercors-perception.st` dans ton image avec SoSe, Roassal et `couplage-perception.st` déjà chargés. Dans le Playground, donne le chemin du dossier décompressé. L’exemple ci-dessous suppose qu’il se trouve dans ton dossier personnel.

```smalltalk
| bundle |
bundle := FileLocator home / 'vercors-perception'.
(VercorsPerceptionExample
    replayFrom: bundle
    heightAboveGround: 180
    secondsPerTick: 10) open
```

`heightAboveGround:` donne la hauteur en mètres au-dessus du terrain sous le drone. Essaie 180 et 330 m pour retrouver les deux aperçus. L’exemple initialise 20 drones, puis rejoue 90 tiks avec un `pacingRate` de 1,0 pour comparer les hauteurs à espacement régulier. Les deux aperçus représentent le tik 90, à 900 secondes simulées.

## Raccorder le Vercors à ton scénario

Utilise le bloc ci-dessous à la place de la construction de l’observateur. Le bloc `heightAt:` reçoit l’état du simulateur et le drone. Cet exemple passe de 180 à 330 m au tik 45. Appelle ensuite l’observateur avec l’état et l’instant cumulé comme pour Valence.

```smalltalk
wayPoints := VercorsPerceptionExample wayPointsFrom: bundle.
observer := VercorsPerceptionExample
    observerOver: bundle / 'terrain-vercors'
    wayPoints: wayPoints
    heightAt: [ :step :drone | step timeStep < 45
        ifTrue: [ 180 ] ifFalse: [ 330 ] ]
    fadeAfterSeconds: 300.
```

## Lire la carte

- Le fond ombré rend visibles les pentes et les crêtes.
- Les couleurs donnent la résolution estimée au sol, en mètres par pixel. Une valeur plus petite indique une image plus fine.
- Le blanc augmente avec le temps écoulé depuis le dernier relevé de la cellule.
- Les hachures roses indiquent les cellules qui entrent dans le champ d’au moins une caméra et que le relief masque à toutes les caméras pouvant les voir à ce tik. Une ancienne observation peut subsister sous les hachures.

Au tik 90, 594 cellules sont masquées à 180 m. Parmi elles, 312 deviennent visibles à 330 m. La surface observée à cet instant passe de 4 615 à 12 091 cellules et le champ élargi rencontre aussi d’autres masques.

## Vitesse et fraîcheur

La part de blanc vaut `min(1, secondes depuis le dernier relevé / 300)`. À 100 secondes par tik, une cellule blanchit complètement après trois tiks sans relevé. Une mesure faite par n’importe quel drone remet son âge à zéro.

À altitude, parcours et espacement fixés, une vitesse réelle deux fois plus faible double le délai de revisite approximatif. Pour un tour de longueur `L` avec `N` drones régulièrement espacés, le délai entre passages est d’environ `L / (N × vitesse)`. Le moment du nouveau relevé dépend aussi de la largeur de l’empreinte et du masque de relief. Une cellule arrivée au blanc y reste jusqu’à son prochain relevé.
