# Fraîcheur des passages dans le simulateur macro

`PointDePassage` appartient à `DroneSystem-Macro`, le package de `MacroSimulatorDrone`.
Il contient l’abscisse curviligne sur la boucle, la date en secondes simulées et l’identifiant
du drone. Sur un parcours géoréférencé, `step realPositionFrom: passage position`
donne ses coordonnées.

## Activer le suivi

```smalltalk
| parameters simulator step |
parameters := MacroSimulatorParameters example1.
parameters maxDate: 75; secondsPerTick: 1.
simulator := parameters initializeSimulator.
simulator run: 50.
step := simulator current.
step freshnessGapAheadOfDrone: step drones first.
```

`maxDate` est l’âge maximal en secondes. Le seuil est inclus dans la fenêtre.
Avec `maxDate: nil`, on obtient l’exécution legacy. Le suivi enregistre le tik initial puis
une position par drone actif après chaque déplacement, aussi bien avec `run:` qu’avec
`runSingleUpdate:`. Les observations d’un drone retiré vieillissent jusqu’à expiration.
La fenêtre active libère les lots périmés. Pour relire un état ancien, `freshPassages` peut
reconstituer sa fenêtre à partir de `history`.

Dans l’atelier, coche **Suivre la fraîcheur des passages** dans **Affichage**.
L’âge maximal reprend la valeur d’**Effacement · s** au lancement de la simulation.
Les exemples `WithFreshness` activent aussi ce suivi. En lot, mets `maxDate` dans le bloc
`simulation` du JSON. Les métriques de passage sont ajoutées au CSV quand le suivi est actif.

## Lire les résultats

`freshnessGapAheadOfDrone:` calcule la distance en mètres au premier passage encore valide
strictement devant le drone. Le parcours reboucle par l’origine. Si un tour complet
ne rencontre aucun point distinct, le résultat est `Float infinity`.

Les points sont échantillonnés aux tiks. L’écart mesure une distance entre ces échantillons.
Le rayon de capture sert de portée avant pour qualifier une rupture locale.

| Champ CSV | Interprétation |
| --- | --- |
| `minFreshness` | Minimum, entre drones, du temps restant avant expiration du premier passage frais situé dans leur portée avant. La valeur est 0 quand le passage utile est absent. |
| `maxFreshnessGap` | Plus grand écart avant parmi les drones, en mètres. |
| `freshnessRuptureCount` | Nombre de drones dont la fraîcheur locale vaut 0 au tik. Avec une flotte vide, le compte vaut 0. |
| `freshnessRupture` | Vrai quand le minimum vaut 0, y compris avec une flotte vide. |

Les métriques optiques du MNT continuent à utiliser les empreintes et les cellules.
Le CSV de l’atelier peut réunir les métriques des passages et de la couverture optique.

## Rejouer les exemples et composer les agrégations

`MacroSimulatorExample example5WithFreshness` reprend les paramètres et événements de
`example5`. Les autres variantes reprennent la même convention, comme
`example2WithFreshness`, `example8WithFreshness` et `exampleISSEBaselineWithFreshness`.
En lançant la variante depuis Pharo, le seuil par défaut est 75 s. Pour utiliser un autre
seuil avec les mêmes exemples, enveloppe l’appel.

```smalltalk
MacroSimulatorFreshnessScope value: 30 during: [
    MacroSimulatorExample example5WithFreshness ].
```

Les blocs suffisaient déjà pour composer des calculs. `label:chain:` rend le chaînage
explicite, et `addExtractor:` continue à accepter les associations existantes.

```smalltalk
series addExtractor: (MacroSimulatorExtractor label: 'ticksEnRupture' chain: {
    [ :history | history collect: #minFreshness ].
    [ :values | values collect: [ :value | value <= 0 ] ].
    [ :flags | flags count: #yourself ] }).
```

L’exporteur legacy produit un CSV `*-freshness.csv` avec le nombre de **tiks en rupture**
et le nombre d’**épisodes**. Un épisode est une série contiguë de tiks en rupture.
