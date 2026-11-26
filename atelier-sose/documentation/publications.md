# Produire les figures d’un article avec l’atelier SoSe

Les sorties pour article s’appuient sur les états stockés par le simulateur. Elles associent des vues à des tiks choisis et des courbes à un drone d’identifiant explicite. Le PDF vectoriel vise la lecture en niveaux de gris. Les données et réglages livrés avec les figures permettent de refaire l’expérience et de changer la composition LaTeX.

## Exporter une série de figures

Depuis une image Pharo 14 à jour, la classe `SoSeAtelierParameters` garde la configuration de la simulation et celle du document. Le mode headless lit le même JSON et écrit un dossier `publication-UUID`. Il suffit de fournir le fichier de paramètres et une destination accessible.

```bash
atelier="$HOME/sose-propre"
"$atelier/lancer.sh" lot "$atelier/exemples/publication-comparaison.json" \
  "$HOME/resultats-article/boucle" publication
"$atelier/lancer.sh" lot "$atelier/exemples/publication-vercors.json" \
  "$HOME/resultats-article/relief" publication
```

Pour utiliser une image SoSe déjà installée avec le code d’un clone plus récent, lancez depuis la racine du clone. Cette commande charge les sources Tonel en mémoire pour ce lot.

```bash
SOSE_LOAD_ATELIER_SOURCE=1 bash lancer-lot.sh "$VM_PHARO" "$IMAGE_SOSE" \
  exemples/publication-comparaison.json "$HOME/resultats-article/boucle" publication
```

`publication-comparaison.json` demande les tiks 18, 35 et 75 par trois formes équivalentes de référence temporelle. Elle produit des cartes vitesse et accélération pour les trois lois, ainsi que le suivi des drones 0 et 5. Le plan combine un retrait fixé au tik 18, une indisponibilité temporaire de la distance et des retraits et arrivées tirés avec une graine.

`publication-anneaux.json` rejoue cette expérience et résume les trois lois sur une seule figure au tik 38. Un anneau correspond à une loi. L’angle est proportionnel à l’abscisse le long de la boucle, sur une origine et dans un sens communs. Le rayon sert à distinguer les lois. L’arc épaissi indique le plus grand écart entre deux drones actifs d’après leurs positions simulées. Les deux suivis individuels illustrent un drone présent jusqu’au tik 90 (n° 3) et un retrait au tik 38 (n° 5).

`publication-vercors.json` prend le même état de 12 drones au tik 12, soit à 24 s simulées, et produit trois cartes d’empreinte à 50, 150 et 250 m AGL. Le champ de caméra vaut 53,13°. Le cadrage conserve un carré de 900 m de côté autour du drone 9 et isole son empreinte. La vue à 50 m montre une cellule masquée, en gris foncé, à côté des cellules visibles. [Configurations publiées](../exemples/)

Pour intégrer ces figures dans un protocole existant, partez des paramètres du lot ou ouvrez un JSON avec `readFrom:`. Le bloc suivant reprend la boucle synthétique et ajoute les tiks et les drones à suivre.

```smalltalk
| p dossier |
p := SoSeAtelierParameters exampleComparison.
p
    publicationAt: #ticks put: #(0 20 60);
    publicationAt: #droneIds put: #(1 2);
    publicationAt: #modes put: #(state speed acceleration).
dossier := FileLocator home / 'resultats-article'.
p publicationInto: dossier.
```

Le dossier contient le document `figures.tex`, des fragments LaTeX, des CSV et `manifest.json`. Les fragments TikZ permettent d’insérer une figure dans un manuscrit avec `\input`. Le document utilise TikZ et PGFPlots.

Pour obtenir le PDF, ouvrez dans le Terminal le dossier `publication-UUID` affiché à la fin du lot. Lancez pdfLaTeX depuis ce dossier pour que les chemins relatifs des fragments soient résolus.

```bash
pdflatex -interaction=nonstopmode -halt-on-error figures.tex
```

Pour inclure un fragment dans un article, reprenez le préambule de `figures.tex` et faites pointer `\input{...}` vers le fragment voulu. Un export de comparaison laisse le premier dossier de série comme référence et place les courbes à la racine du dossier.


| Clés de `publication` | Réglage |
| --- | --- |
| `ticks`, `seconds`, `dates`, `origin` | Références d’états par tik, par secondes simulées ou par date ISO 8601 avec origine de l’horloge. |
| `droneIds`, `mapDroneIds` | Identifiants des drones à suivre dans les courbes et filtre des drones de la carte. Une liste de carte vide conserve la flotte entière. |
| `focusDrone`, `focusRadiusMeters` | Centre un zoom sur un drone présent au tik. Le rayon en mètres donne la moitié de la largeur du cadrage. |
| `widthCm`, `maxHeightCm` | Largeur et hauteur maximales de la carte TikZ en centimètres. |
| `policies` | Lois à appliquer au même scénario et avec le même plan d’événements. Les identifiants Pharo intégrés incluent `capingPolicy`, `revisedCapingPolicy` et `revisitCapingPolicy`. |
| `overview` | `maps` produit les cartes détaillées, `rings` produit une figure concentrique par tik choisi et `none` laisse les courbes et comparaisons. |
| `modes` | Vues par état (`state`), vitesse (`speed`) et accélération (`acceleration`). |
| `showRoute`, `showDrones`, `showDroneNames` | Active le tracé, les glyphes de flotte et les identifiants. |
| `showScale`, `showLegend` | Active l’échelle métrique et la légende locale. |
| `showLosses`, `lossMarkerSeconds`, `trailTicks` | Affiche les pertes, règle leur persistance en secondes simulées et la longueur de traîne en nombre de tiks. |
| `footprintHeights`, `showMasked` | Choisit les hauteurs AGL des vues d’empreinte et active les masques. |
| `camera` | Tangente du demi-angle de champ et nombre de pixels par côté du capteur, par défaut `[0.5, 2000]`. |
| `positionTolerance`, `speedTolerance`, `accelerationThreshold` | Tolérances de comparaison des positions en m et des vitesses en m/s. La tolérance de vitesse s’applique aussi aux classes de vitesse des cartes. Le seuil d’accélération est en m/s². |

Pour une simulation qui produit déjà son propre historique, l’objet de publication peut recevoir ce simulateur directement. Passez le terrain réellement utilisé pour les empreintes et la durée effective d’un tik.

```smalltalk
| publication |
publication := SoSeAtelierPublication new
    tickSeconds: 1;
    terrain: nil;
    options: { #ticks -> #(0 20 60). #droneIds -> #(1) } asDictionary;
    yourself.
publication addSimulation: simulateur named: 'Capping'.
publication writeInto: FileLocator home / 'resultats-article'.
```

Pour exporter seulement une carte, réutilisez le premier simulateur et appelez la classe de carte. Donnez le dictionnaire de réglages du mode et la destination du fragment.

```smalltalk
| carte |
carte := SoSeAtelierTikzMap
    history: simulateur history tickSeconds: 1 terrain: nil.
carte writeAtTick: 20 options: { #mode -> #speed } asDictionary
    to: FileLocator home / 'carte-tik-20.tex'.
```

## Choisir une expérience et une horloge

La boucle synthétique sert à comparer les lois sur les mêmes positions initiales, les mêmes vitesses bornes, le même horizon et la même graine. Elle permet d’étudier l’effet d’un retrait et d’une entrée sans projection cartographique. Gardez la même chronologie de perturbations dans chaque variante. L’expérience sur terrain utilise une grille d’altitude et un parcours projeté. Elle permet de comparer les empreintes optiques à 50, 150 et 250 m au-dessus du terrain.

Le tik est la valeur de `timeStep` portée par l’état simulé. L’état initial est au tik 0. Un pas de 2 s associe le tik 25 à 50 s simulées. L’export par date ajoute une origine explicite à cette horloge. Notez l’origine et son fuseau dans la légende si vous citez une date. En l’absence d’origine, utilisez le temps relatif en secondes. Les vues utilisent les tiks exacts de l’historique. Si les trois listes sont vides, le document prend le dernier état de la première série.

Pour les dates, ce bloc sélectionne les tiks 0 et 25 dans une exécution au pas de 2 s.

```json
"publication": {
  "origin": "2026-01-16T10:00:00+00:00",
  "dates": ["2026-01-16T10:00:00+00:00", "2026-01-16T10:00:50+00:00"]
}
```

Les sélections par tik, secondes et dates sont réunies, dédoublonnées et triées par tik. Les dates sont converties à partir de l’origine. Pour un état dont le tik vaut 25, les sélections `ticks: [25]`, `seconds: [50]` et la seconde date ci-dessus produisent la même géométrie. Si le temps demandé tombe entre deux tiks ou après l’horizon calculé, choisissez un état disponible.

Pour encadrer une rupture, demandez une vue avant l’événement, une au voisinage immédiat et une après rééquilibrage. Repérez le premier changement d’effectif dans l’historique exporté. Avec l’exécution historique ou un événement déclenché par une condition, la date programmée et le premier état montrant le changement peuvent différer. Citez le tik observé et, si nécessaire, le tik de la demande de retrait ou de renfort.

## Savoir ce que montre chaque figure

| Figure | Grandeurs | Indications de lecture |
| --- | --- | --- |
| Carte des positions | Tracé, positions de l’état exporté, repères de flotte et retraits | Conservez la même emprise et la même échelle pour comparer deux états ou politiques. |
| Suivi local | Vitesse, accélération et écarts auprès d’un drone choisi par son identifiant | L’export distingue les écarts avant et arrière, les valeurs estimées, les observations indisponibles et l’absence du drone. |
| Empreinte optique | Grille du relief, cellules évaluées et empreinte visible | Le masque de relief signale une obstruction sur une cellule évaluée. Une cellule hors champ ou hors données reste inconnue dans l’observation instantanée. |

Les ruptures du service ont des définitions mesurables. Pour étudier la couverture au cours du temps, utilisez la métrique optique du rejeu. Citez l’indicateur et son seuil, par exemple une chute de la fraction fraîche sous 75 % dans la zone évaluée, avec une limite d’âge de 40 s. Le retrait d’un drone est un événement de scénario. Un intervalle d’observation indisponible traduit l’état du capteur ou l’ambiguïté de la géométrie. La comparaison moteur identifie le premier état où positions, vitesses ou membres de la flotte diffèrent entre deux variantes. Ces chronologies peuvent se recouvrir. Pour donner un temps de restauration, mesurez entre le début observé et le premier retour durable au seuil annoncé. Un état final encore au-delà du seuil indique que la restauration dépasse l’horizon étudié.

La largeur du champ d’une caméra verticale sur terrain horizontal vaut $2h\tan(\theta/2)$, pour une hauteur AGL $h$ et un champ total $\theta$. À caméra identique, 50 m donne un champ théorique plus étroit et une finesse locale généralement plus élevée. À 150 m, l’exemple du Vercors donne une vue intermédiaire. À 250 m, le champ théorique grandit, la finesse au sol diminue généralement et certains obstacles peuvent moins masquer le terrain. Les surfaces observées dépendent des lignes de visée. Pour comparer les figures, gardez la même projection, la même emprise, la même maille et le même champ optique. Faites figurer séparément la maille du MNT en m/cellule et la finesse optique en m/px.

Pour le champ de 53,13° et un capteur de 2 000 pixels par côté, les ordres de grandeur sur terrain plan sont les suivants. La grille de l’exemple Vercors échantillonne le relief sur une maille de 25 m.

| Hauteur AGL | Largeur théorique du champ | Finesse théorique |
| ---: | ---: | ---: |
| 50 m | 50 m | 0,025 m/px |
| 150 m | 150 m | 0,075 m/px |
| 250 m | 250 m | 0,125 m/px |

Une maille de 25 m ne décrit les obstacles que dans la mesure où ils sont représentés dans le MNT ou le modèle de surface fourni. Le rendu TikZ dessine les cellules évaluées et leurs masques à cette échelle.

## Lire les symboles en niveaux de gris

Les cartes de positions utilisent un cercle pour un drone actif et une croix pour la dernière position d’un drone retiré. En mode vitesse, une barre marque le minimum. Une, deux ou trois pointes pleines indiquent une vitesse en dessous, au niveau ou au-dessus de la nominale, avec orientation le long du parcours. Les flèches ouvertes du mode accélération distinguent l’accélération du freinage par leur sens. Un losange repère une vitesse stable au seuil choisi. Au premier état du drone, le cercle reste visible et le sens d’accélération est indéterminé.

En vue optique, le gris clair indique l’union des cellules visibles. Le gris foncé indique une obstruction par le relief lorsqu’on affiche les masques. Une cellule vue par un drone reste claire même si un autre drone est occulté sur cette cellule. Quand les masques sont affichés, le blanc dans l’emprise signale une cellule hors champ ou sans données suffisantes. La carte donne une empreinte instantanée. Pour mesurer une fraîcheur accumulée, utilisez l’historique de couverture du rejeu.

Dans le suivi local, le signe distingue les deux directions. L’avant apparaît au-dessus de zéro et l’arrière en dessous. Un cercle creux repère un gisement estimé. Une croix diagonale à zéro marque une observation avant indisponible. Une croix droite signale le même statut à l’arrière. Un point plein à zéro correspond à une mesure directe nulle. L’absence du drone interrompt les trois courbes. Dans le CSV, `ahead_gap_m` et `behind_gap_m` contiennent les écarts disponibles, et `ahead_plot_m` et `behind_plot_m` les ordonnées de la figure. Consultez le statut avant d’interpréter un zéro de tracé. L’accélération est une différence de vitesses entre deux états consécutifs où l’identifiant est présent.

## Comparer les trajectoires et les événements

La première série sert de référence. Le CSV `comparaison-trajectoires.csv` donne par tik les tailles et les listes d’identifiants des deux flottes, les écarts maximums et moyens sur les identifiants communs et le drone qui atteint chaque maximum. Les positions sont comparées sur le plus court arc de la même boucle. Les vitesses sont en m/s. Le fragment `comparaison-trajectoires.tex` montre les deux écarts maximaux au fil du temps et marque la première divergence moteur d’un trait vertical pointillé.

Dans `divergence.json`, `firstDivergence` donne le premier tik où un écart dépasse sa tolérance ou où une variante présente un tik ou des identifiants différents. Les motifs sont `position`, `speed`, `missingTick` et `fleetIds`. Un premier écart au tik 0 concerne l’état initial. `null` indique que ces critères restent satisfaits sur les historiques. `final` et `finalCommon` décrivent respectivement le dernier tik et le dernier tik commun.

`firstObservationDivergence` suit les observations sur les mêmes liens dirigés entre voisins. Il distingue les changements de statut, de disponibilité et de valeur estimée. Une panne ou une estimation différente peut précéder le premier écart de trajectoire.

Dans le lot livré, les trois lois ont le même effectif de 12 drones jusqu’au tik 17. Dès le tik 1, Capping diffère de la référence révisée de 1,00 m et 1,00 m/s au maximum. Pour la loi avec revisite, les écarts maximaux correspondants sont de 0,375 m et 0,375 m/s. Le premier retrait survient au tik 18 à l’identique dans les trois séries. Les écarts estimés entre voisins diffèrent pour la première fois à ce tik. Le point de divergence moteur précède donc le retrait suivi dans le scénario.

Pour documenter les événements, conservez le bloc `fleetSchedule` du JSON de paramètres et les sorties `evenements-realises.json` et `evenements-realises.csv`. Le plan exige une graine propre. Chaque règle utilise `tick` ou une plage inclusive `fromTick`–`toTick` et un `count` de tirages, avec répétition possible d’un même tik. Les tiks doivent se trouver dans l’horizon exécuté. Le scénario `geometry` reçoit ce plan quand `sensorOutages`, `fleetWithdrawalTick` et `fleetArrivalTick` sont désactivés.

| Type | Paramètres et réalisation |
| --- | --- |
| `withdrawal` | `drone` fixe l’identifiant retiré. Sinon, un drone actif est tiré au sort. |
| `arrival` | `position` fixe l’abscisse en mètres dans la boucle. Sinon, elle est tirée uniformément sur la boucle. Le journal donne le nouvel identifiant. |
| `distance` et `vision` | `available` règle la disponibilité de la mesure directe ou du gisement. `drone` permet de cibler un identifiant. Par défaut, le réglage concerne la flotte active. |

À tik égal, le retrait est traité avant l’arrivée, puis la disponibilité des capteurs est appliquée. Le journal permet de distinguer une divergence dans les flottes d’un écart de commande à effectif égal. [Exemple de plan](../exemples/plan-evenements.json)

## Préparer les légendes et le dépôt de l’article

Indiquez l’expérience, la loi, le mode de perception, les tiks, la durée d’un tik, le terrain ou la longueur de boucle, ainsi que l’identifiant lorsqu’un drone est suivi. Pour les empreintes, indiquez en plus les hauteurs, le champ optique et les classes de la légende. Si le terrain provient d’un service externe, placez le fournisseur et la licence près de la figure. [Sources des terrains livrés](../terrains/SOURCES.md)

Insérez les figures à la taille finale de la publication et vérifiez les légendes, traits et niveaux de gris sur une épreuve papier. Le suivi local peut être composé en pleine largeur pour de longues séries ou plusieurs variantes. Dans une série comparée, gardez les mêmes axes, limites de carte et unités. Réunissez le document auteur, ses dépendances LaTeX, les réglages JSON et les résultats CSV pour relier les figures à une révision du code. [Guide d’utilisation](guide-atelier.pdf)
