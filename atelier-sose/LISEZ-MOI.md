# Atelier SoSe pour Pharo 14

L’atelier simule la flotte, exporte les métriques et rejoue l’historique sur un terrain. Le guide détaille l’usage, les scénarios reproductibles et les interfaces des classes. [Guide PDF](documentation/guide-atelier.pdf) · [Sources LaTeX et TikZ](documentation/guide-atelier.tex)

## Reconstruire une image Pharo 14

Depuis le dossier du kit, avec une VM adaptée à l’architecture de la machine, donne le chemin d’une image Pharo 14 vierge et celui d’un dossier de destination neuf.

```bash
bash installer.sh "/chemin/vers/pharo" \
  "/chemin/vers/Pharo 14.image" "$HOME/sose-propre"
"$HOME/sose-propre/lancer.sh"
```

Le socle FullApp figé et NeoCSV sont embarqués. L’installation crée un dépôt Git local dans `sose-propre/atelier` et enregistre la version chargée ainsi que les vérifications. `--fullapp-clone CHEMIN` ou `--fullapp-url URL`, avec `--ref REF`, permettent de choisir un autre socle compatible. `--clone-publication URL` prépare un clone distinct pour la publication. [Options et mise à jour](installation/LISEZ-MOI.md)

Les exemples de terrain embarqués s’ouvrent directement. FFmpeg avec `libx264` sert à l’export MP4. GDAL sert à produire un MNT et à préparer les fonds externes sur une nouvelle emprise. Pour Copernicus, il faut aussi `curl` et `gdalbuildvrt`. Si ces commandes sont dans un environnement Conda, lance l’atelier depuis le Terminal où cet environnement est actif.

## Simuler en ligne de commande

```bash
bash lancer-lot.sh "$VM_PHARO" "$IMAGE_PHARO" \
  exemples/legacy-sose.json ./resultats/legacy run

bash lancer-lot.sh "$VM_PHARO" "$IMAGE_PHARO" \
  exemples/comparaison-synthetique.json ./resultats/comparaison compare
```

`SoSeAtelierParameters` propose aussi `exampleLegacySoSe`, `exampleComparison`, `readFrom:`, `writeTo:`, `run`, `exportInto:`, `runComparisonInto:`, `videoInto:` et `prepareTerrainInto:`. Le jeu de comparaison utilise une boucle métrique indépendante du terrain, une graine fixe et le même horizon pour les variantes. Le mode `terrain` génère un MNT à partir des paramètres. Le mode `video` utilise un terrain préparé et son parcours. `exemples/crozon-video.json` teste le rendu et FFmpeg. `exemples/revisite-equilibre.json` compare les trois lois avec des voisins observables et un espacement initial uniforme.

## Produire des figures d’article

Le mode `publication` et la méthode `publicationInto:` écrivent des fragments TikZ, un document LaTeX et les séries CSV. Les exemples comparent trois lois avec les mêmes événements et montrent les empreintes optiques sur le relief à trois hauteurs. [Fiche auteur et exemples](documentation/publications.md)

Les variantes `WithFreshness` des exemples legacy suivent les passages datés sur la boucle et exportent les ruptures par tik. [Réglages et calcul de la fraîcheur macro](documentation/fraicheur-macro.md)

## Préparer une démonstration

1. Charge un terrain, puis choisis **Parcours cartographié**. **Vercors** est aussi disponible avec ses événements d’exemple. Modifie le nombre de drones, les vitesses ou la durée du tik. **Simuler** calcule l’historique et affiche les métriques du dernier état.
2. Dans **Affichage**, choisis le fond, les couches, la hauteur au-dessus du sol, le champ optique et le code couleur par vitesse ou accélération. Sélectionne un drone pour son incrustation. Les durées de blanchiment, d’effacement et de marquage du retrait sont en secondes simulées.
3. Dans **Lecture**, règle la vitesse nominale de lecture, le pas d’images et le ralenti. Par défaut, Vercors ralentit des tiks 45 à 70 autour du retrait au tik 55. Tu peux aussi cibler un rectangle GPS et sélectionner le drone qui déclenche le ralenti. Quand les deux critères sont actifs, l’un ou l’autre suffit. À `20×`, vingt secondes simulées occupent une seconde de vidéo. Les transitions de vitesse sont conservées même si elles tombent entre deux images échantillonnées.
4. Utilise **Lire la carte** pour voir le rendu, puis **Exporter MP4…**. Le dossier créé contient `demonstration.mp4`, les PNG et `lecture.ffconcat`. Le journal `ffmpeg.log` donne le diagnostic si l’encodage échoue.
5. Dans **CSV**, coche les colonnes à exporter. Les métriques macro suivent les unités du modèle, dont `avgSpeed` en mètres par tik. La couverture optique instantanée et la fraction de cases fraîches sont calculées à chaque tik sur toute l’emprise du MNT ou sur le rectangle GPS choisi. La case **Mesurer dans la zone GPS de Lecture** est indépendante du ralenti. La limite d’âge de la fraîcheur est le délai **Blanc complet**. La **Cible fraîcheur** sert au **Verdict de fraîcheur** dans le CSV. Ce verdict est un résultat de mesure.

Les valeurs de simulation et le terrain sont pris au clic sur **Simuler**. Les choix d’affichage, de lecture et de colonnes sont pris au démarrage de chaque lecture ou export. Les changements de vitesse de lecture n’affectent ni les tiks ni le vieillissement simulé.

## Régler et comparer la revisite

**Simulation → Objectif revisite** est le délai demandé en secondes. Il démarre à 180 s. Il est copié dans `revisitTargetSeconds` de chaque drone initial et des drones entrants, avec la durée du tik dans `secondsPerTick`. Ce champ figure aussi dans les drones des scénarios paramétrables exécutés avec les lois historiques et dans ceux du modèle ISSe. Un état historique enregistré avant l’ajout du champ a un objectif absent.

| Loi de commande | Quand les deux écarts sont presque égaux |
| --- | --- |
| **Capping** | Applique le facteur `pacingRate` à la vitesse courante, avec arrondi et bornes. |
| **Capping révisé** | Rapproche la vitesse courante de la nominale par le facteur `pacingRate`. |
| **Capping avec revisite** | Rapproche la vitesse courante de la plus grande valeur entre la nominale et `max(écart avant, écart arrière) / délai`, dans les bornes. |

La nouvelle loi utilise les deux écarts observés ou estimés le long du parcours et les réglages embarqués du drone. La correction d’espacement s’applique en dehors de la bande d’équilibre. Un écart indisponible déclenche le maintien de la vitesse. Un délai absent donne la référence nominale. Les consignes sont converties en déplacement par tik.

- **Avant simulation**, va dans **Revisite → Estimer le réglage courant**. L’atelier affiche l’écart à l’équilibre `longueur / effectif`, le délai à vitesse nominale et la vitesse requise. Les courbes montrent les consignes des lois du catalogue pour un drone à vitesse nominale autour de l’équilibre. Elles utilisent `sensibility = 0,01` et `pacingRate = 0,9`, les valeurs des modèles paramétrables. Deux courbes peuvent coïncider selon le délai et la nominale.
- **Après simulation**, change **Délai évalué** puis clique **Évaluer les historiques**. Le tableau compare les deux derniers historiques terminés. Il affiche le pire délai estimé à chaque état à partir des écarts et des vitesses de commande, le nombre de tiks au-delà du délai testé et les proportions de perception. Le délai évalué s’applique à l’analyse. L’**objectif embarqué** reste visible pour identifier le réglage exécuté.
- Pour voir la contrainte agir sur Vercors, essaie neuf drones, 10 m/s nominal, 15 m/s maximum, des tiks de 2 s et un délai de 100 s. À l’équilibre, l’estimation demande environ 12,5 m/s. La troisième loi vise cette référence dans sa zone d’équilibre. Le scénario utilise le délai pour modéliser la revisite d’un point sur l’anneau dont chaque passage renouvelle l’observation.

## Choisir l’hypothèse de perception

Dans **Parcours cartographié** et **Vercors**, le champ **Simulation → Perception des voisins** pilote les écarts transmis à la loi. Il suit le parcours choisi. La comparaison en lot dispose aussi d’une boucle géométrique synthétique. Le modèle SoSe en anneau et les méthodes historiques utilisent leur modèle de perception propre. Dans un scénario Vercors édité, l’appel `atelier configurerPerceptionDe: simulateur` applique le menu avant le premier tik.

| Hypothèse | Entrée de la loi de commande |
| --- | --- |
| **Selon le scénario** | Modèle installé par le scénario. Vercors utilise la distance puis le gisement. |
| **Distance seule** | Écart direct quand la mesure est disponible et le voisin dans la portée. |
| **Gisement seul** | Écart estimé par l’intersection de la direction du voisin avec le parcours. L’estimation est exploitable quand une seule intersection valide permet de retrouver l’écart. |
| **Distance puis gisement** | Mesure directe si disponible, puis estimation angulaire quand la vision fournit un gisement exploitable. |

La **portée voisins** borne la distance directe entre deux drones. Le demi-angle borne l’écart entre la direction du gisement et l’axe attendu du voisin avant ou arrière. Les événements du scénario commandent la disponibilité des mesures et du gisement. Pour comparer deux hypothèses, garde le parcours, la graine, la loi et les événements, simule une fois par hypothèse et ouvre **Revisite**. Les proportions moyennes sont calculées sur les tiks. Le CSV permet aussi de suivre la perception directe, angulaire, indisponible, hors portée et l’erreur d’écart.

## Combiner les réglages de couverture

| Cas | Réglages et lecture |
| --- | --- |
| **Couverture macro** | `Capture macro` compte les mètres le long de l’anneau devant et derrière chaque drone. Le CSV donne la fraction de boucle couverte. |
| **Optique** | Hauteur au-dessus du sol et champ optique déterminent l’empreinte sur le MNT. Les masques viennent du relief. Avec `Capture macro = 0`, lis la couverture optique instantanée et les cases fraîches. |
| **Macro et optique** | Une capture macro positive et les colonnes optiques donnent les deux mesures sur le même historique. La portée voisins et la capture macro sont exprimées en mètres selon leurs géométries respectives. |
| **Commande avec revisite** | L’objectif en secondes oriente la commande locale près de l’équilibre. Le délai macro du panneau **Revisite** et la fraîcheur optique du CSV donnent deux lectures de l’historique. |

Le blanc complet et l’effacement règlent la représentation. Le CSV optique utilise le délai de blanc complet comme limite d’âge de l’observation, sur le MNT ou la zone choisie. Le délai embarqué et le délai d’évaluation du panneau **Revisite** sont deux champs en secondes pour le modèle macro.

## Utiliser un autre site ou un exemple historique

### Charger un terrain fourni

Dans **Terrain et parcours**, choisis un site puis clique **Charger l’exemple**. Le choix renseigne le terrain, son emprise et ses points de passage. Les nouvelles grilles proviennent du modèle de surface Copernicus GLO-30 Public. Le catalogue donne la maille retenue pour la simulation. [Sources des données](terrains/SOURCES.md)

| Exemple | Maille | Relief à comparer |
| --- | ---: | --- |
| New York · Manhattan | 30 m | Îlot urbain entre Hudson et East River |
| Finistère · Crozon | 50 m | Versants et falaises littorales |
| Détroit d’Ormuz · Les deux rives | 250 m | Îles, côtes iranienne et omanaise, entrée du golfe Persique et débouché vers le golfe d’Oman |

L’exemple d’Ormuz utilise une boucle de démonstration de douze points à l’échelle du détroit. La carte de relief couvre environ 107 km d’ouest en est et 137 km du sud au nord. [Grille et provenance](terrains/ormuz/terrain.json)

### Dessiner sa zone

1. Clique **Dessiner sur la carte…**. Pharo ouvre une page locale dans le navigateur avec OpenStreetMap comme fond initial. Choisis **Relief et littoral** pour afficher l’aperçu hors ligne livré pour Manhattan, Crozon ou Ormuz. **Plan IGN**, **USGS Topo** et **Sentinel-2 (mosaïque 2016)** utilisent les services cartographiques dans le navigateur.
2. Déplace et zoome la carte ou centre-la par longitude et latitude. Pour partir d’une page sans points, clique **Nouveau tracé**. Choisis **Emprise** et clique sur deux coins opposés. Choisis **Point** puis clique dans l’ordre du parcours. Tu peux déplacer les points ou les réordonner dans la liste. Le rejeu ferme la boucle à partir de trois sommets distincts. L’option **Enveloppe convexe** calcule le parcours à partir des sommets extérieurs lors de la simulation.
3. Clique **Enregistrer le terrain…** et renseigne le nom du dossier, la maille, la marge et la source. Choisis **Copernicus GLO-30** pour lire les dalles publiques en ligne, **IGN** ou **USGS** dans leurs zones de couverture, ou un GeoTIFF couvrant l’emprise et la marge. La génération utilise le rectangle dessiné ou celui qui englobe les points. Un rectangle explicite suffit pour préparer le terrain avant de tracer le parcours.
4. Clique **Choisir le dossier dans Pharo** et passe dans la fenêtre Pharo pour choisir la destination. L’atelier crée un dossier réutilisable contenant `terrain.json`, `mnt.csv`, `emprise.geojson` et `trace-sose.json`, puis le charge. **Ouvrir un MNT…** recharge ce dossier avec son tracé.

Les fonds de Manhattan, Crozon et Ormuz combinent le relief Copernicus et les géométries d’OpenStreetMap pour l’eau et les routes. Roassal superpose cette cartographie à **Relief ombré** et **Altitude** sur la grille du MNT. Dans **Affichage → Fond de carte**, **Plan IGN**, **USGS Topo** et **Sentinel-2 (mosaïque 2016)** sélectionnent aussi le fond du rejeu et du MP4. Le rendu inclut Plan IGN et Sentinel-2 hors ligne pour Crozon et le Vercors, et USGS Topo pour Manhattan. Pour les autres emprises, GDAL et le service cartographique permettent de calculer le fond dans la projection du MNT. Si tu enregistres une découpe avec **GeoTIFF de l’exemple**, le fond local est reprojeté pour le dossier de sortie. [Sources des fonds](terrains/SOURCES.md)

**Appliquer dans Pharo** transfère le tracé dans l’atelier. **Enregistrer le tracé** dans le navigateur produit un fichier JSON avec l’emprise, les points et l’option de calcul d’enveloppe. **Ouvrir un tracé…** relit ce fichier. **Enregistrer…** dans Pharo sauvegarde aussi le scénario, son code, le catalogue de lois, le MNT choisi, la maille et les options de simulation, d’affichage, de lecture et de CSV. **Ouvrir mission…** recharge la configuration. Clique ensuite **Simuler** pour recalculer l’historique. Pour déplacer une mission qui pointe vers un terrain de ton disque, transporte aussi le dossier MNT et sélectionne son nouvel emplacement si nécessaire.

### Rejouer un modèle

**Parcours cartographié** initialise un scénario sans événement particulier sur le tracé choisi. **Vercors** initialise l’exemple hybride avec ses événements sur le parcours chargé. **SoSe historique** appelle le rejeu de référence. Les appels à la configuration et les événements sont visibles dans l’éditeur. **SoSe paramétrable** conserve l’anneau de 10 km du modèle macro. Le rejeu place la flotte sur le parcours choisi par fraction de tour. **ISSe historique** reprend les paramètres de `generateScenario:` et expose l’indice de graine et la durée de simulation en tiks.

Le modèle Vercors utilise `runSingleUpdate:` pour un mouvement par tik. Le modèle SoSe paramétrable utilise aussi cette cadence avec la loi de revisite et avec les lois éditées. Pour les lois historiques de SoSe, il passe par `run:` afin de reproduire l’avance du scénario historique.

Les méthodes sans argument dont le nom commence par `example` dans `MacroSimulatorExample class` sont listées dans le sélecteur. Leur code complet est éditable dans l’atelier et exécuté dans le contexte de la classe. **Source d’origine** affiche le code publié dans l’image. Pour que l’atelier puisse exploiter la carte et ses exports, la méthode ou le bloc `[ :atelier | … ]` doit renvoyer un `MacroSimulator`. Dans `example1`, par exemple, utilise `^ simulator` à la dernière ligne. Un exemple qui exécute une campagne garde ses propres exports.

## Modifier le catalogue de lois

L’onglet **Commande** affiche les trois lois de départ et leur code Pharo. **Nouvelle** crée un bloc, **Dupliquer** part d’une loi existante, **Retirer** enlève l’entrée sélectionnée, et **Préréglages** réinsère les lois de départ retirées. **Utiliser** vérifie que la source est un bloc à un seul argument et sélectionne la loi dans **Simulation**. Les scénarios Vercors et SoSe paramétrable utilisent cette sélection.

Le bloc reçoit une `SoSeAtelierLocalInput` par drone et par tik. `gapAhead` et `gapBehind` donnent les écarts en mètres quand ils sont observables. Les vitesses de la structure et la consigne renvoyée sont en mètres par tik. `secondsPerTick` et `revisitTargetSeconds` sont en secondes. Le résultat est borné par les vitesses minimale et maximale du drone. Les paramètres de réglage de la commande sont accessibles par `pacingRate` et `sensibility`.

```smalltalk
[ :local |
    local hasBothGaps
        ifTrue: [ local currentSpeed + (local relativeGapError * local secondsPerTick) ]
        ifFalse: [ local currentSpeed ] ]
```

`SoSeAtelierCommandLaw` conserve le nom et la source. `SoSeAtelierLocalInput` définit les valeurs de chaque décision. Un futur compilateur d’équations pourra produire un bloc respectant ce contrat.

## Intégrer le paquet à FullApp

Applique `macro-revisite.patch` dans ton clone FullApp sur une branche de travail. Il ajoute les champs et les méthodes à `DroneSystem-Macro`. Copie ensuite `src/SoSe-Atelier-UI` dans le `src` du clone, ainsi que `cartographie` et `terrains` à sa racine. Le patch a été préparé pour FullApp `43fff5d`. Pour une image reconstruite depuis des sources qui contiennent le patch, charge le profil SoSe puis le paquet `SoSe-Atelier-UI` et configure `SoSeAtelierResources directory:` avec la racine du clone. Le script `migrer-macro.st` permet la mise à jour directe de l’image déjà installée.

| Classe | Rôle |
| --- | --- |
| `SoSeAtelierPresenter` | Fenêtre Spec et lancement des actions |
| `SoSeAtelierMissionPresenter` | Formulaires de simulation, terrain et parcours |
| `SoSeAtelierOptionsPresenter` | Formulaires d’affichage, de lecture et de métriques |
| `SoSeAtelierRevisitPresenter` | Estimation, courbes de commande et comparaison des deux derniers historiques |
| `SoSeAtelierRevisitRun` | Indicateurs de revisite et de perception d’une simulation |
| `SoSeAtelierLawPresenter`, `SoSeAtelierCommandLaw` | Catalogue et code des lois en Pharo |
| `SoSeAtelierLocalInput`, `SoSeAtelierLocalBehavior` | Entrées locales et évaluation de la commande |
| `SoSeAtelierMapPlan`, `SoSeAtelierMapServer` | Tracé WGS84 et liaison avec le navigateur |
| `SoSeAtelierCopernicusSource` | Sélection et assemblage des dalles publiques pour une nouvelle emprise |
| `SoSeAtelierMissionFile` | Lecture et écriture des fichiers JSON de mission |
| `SoSeAtelierSimulation` | Exécution du scénario et raccord à `MacroSimulator` |
| `SoSeAtelierTerrain` | `GeoPoint`, emprise, génération du MNT et raccord au rejeu |
| `SoSeAtelierLecture` | Rejeu Roassal, chronologie et mesures optiques |
| `SoSeAtelierExport` | Exporteur macro CSV et encodage FFmpeg |
| `SoSeAtelierParameters` | Paramètres versionnés, génération, simulation et exports en lot |
| `SoSeAtelierBasemap` | Choix des fonds et reprojection vers l’emprise d’affichage |
| `SoSeAtelierRenderScene`, `SoSeAtelierRenderServer` | Scène JSON et serveur local de rejeu Web 3D |
