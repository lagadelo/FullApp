# Installation propre de l’atelier SoSe sous Pharo 14

Crée une image vierge Pharo 14 dans le Launcher, puis ferme-la avant l’installation. Repère le fichier `.image`, le `.changes` qui porte le même nom et l’exécutable de la VM. Le profil utilise Spec et Roassal présents dans l’image de départ. Git et Bash doivent être accessibles dans le terminal.

Depuis le dossier du kit, donne les trois chemins à l’installateur. Garde les guillemets pour les chemins contenant des espaces.

```bash
bash installer.sh \
  '/chemin/vers/Pharo.app/Contents/MacOS/Pharo' \
  '/chemin/vers/Pharo 14.0 - 64bit (stable).image' \
  "$HOME/SoSe/Atelier-14"

"$HOME/SoSe/Atelier-14/lancer.sh"
```

L’installation charge l’instantané FullApp inclus et NeoCSV en local. Elle contrôle le rejeu Vercors, SoSe et ISSe, l’export PNG et CSV, ainsi que la présence de l’interface et des ressources. Les couches cartographiques distantes sont chargées à la demande. Le dossier de sortie doit être neuf. L’image de départ reste disponible dans le Launcher.

| Élément installé | Usage |
| --- | --- |
| `SoSe-Atelier.image` et `.changes` | Image prête à ouvrir et journal Pharo |
| `lancer.sh` | Atelier graphique sans argument, VM en mode headless si une commande est fournie |
| `atelier/` | Dépôt Git local sur `main` avec le code, les exemples, les terrains fournis et le profil de dépendances |
| `terrains/`, `rejeu-vercors/`, `cartographie/` et `visualisation-3d/` | Ressources trouvées à côté de l’image par des liens relatifs |
| `provenance.txt` et `verification.txt` | Révisions des sources et résultats des contrôles |
| `sources-avant/`, `sources-apres/` et `reprise-locale.txt` | Définitions Tonel et rapport de compatibilité du socle FullApp |

Pour lancer un script headless, donne son chemin absolu au lanceur. Les chemins relatifs utilisés par le script sont résolus dans le dossier courant du terminal.

```bash
"$HOME/SoSe/Atelier-14/lancer.sh" st --quit /chemin/vers/scenario.st
```

Pour exécuter le fichier de paramètres d’un exemple livré et comparer les hypothèses de perception, utilise la commande `lot`.

```bash
atelier="$HOME/SoSe/Atelier-14"
"$atelier/lancer.sh" lot "$atelier/exemples/comparaison-synthetique.json" "$HOME/SoSe/comparaison" compare
```

Déplace le dossier d’installation entier pour conserver les liens vers les ressources. Si la VM a aussi changé d’emplacement, lance avec `SOSE_PHARO_VM=/nouveau/chemin/Pharo` ou mets à jour `.pharo-vm`.

## Sélectionner et publier les sources

L’installation standard reprend le commit FullApp `43fff5d2de62f9a53040726f3f9a272c301091a9`. Pour partir d’un autre commit disponible dans ton clone, ajoute les options suivantes à la commande d’installation.

```bash
--fullapp-clone "$HOME/Projets/FullApp" --ref master
```

`--fullapp-url URL` permet de fournir un dépôt Git distant à la place du clone local. En l’absence de `--ref`, l’installateur utilise son `HEAD`. Le commit doit contenir les paquets Tonel FullApp attendus et passer les mêmes vérifications. Les modifications en cours dans le clone ne sont chargées qu’après leur commit.

Ajoute `--clone-publication URL` si tu veux préparer un clone de publication en plus du dépôt local. Le clone apparaît dans `publication/`. Sa branche locale `atelier-sose` repart de la branche du même nom si elle existe sur le distant. Les sources du kit remplacent le contenu de `atelier-sose/` dans ce clone et figurent dans l’index. Vérifie le diff puis utilise tes identifiants Git habituels pour publier.

```bash
cd "$HOME/SoSe/Atelier-14/publication"
git status
git diff --cached --stat
git commit -m 'Ajouter le kit reproductible de l’atelier SoSe'
git push -u origin atelier-sose
```

Pour faire évoluer le paquet `SoSe-Atelier-UI` depuis Pharo, ouvre le dépôt `atelier/` dans Iceberg et configure `src` comme dossier des paquets. Sauvegarde tes modifications Pharo dans le dépôt et commite-les. Les missions exportées, parcours et terrains redistribuables peuvent être ajoutés depuis le terminal. Garde les images Pharo, vidéos et sorties de travail à côté du dépôt. Depuis un kit à jour, relance `installer.sh` vers un nouveau dossier pour vérifier le chargement depuis une image vierge.

## Outils de terrain et de vidéo

Le kit fournit des terrains prêts à ouvrir. Pour créer un MNT ou produire des fonds géoréférencés, le terminal qui lance Pharo doit exposer GDAL. Pour encoder les vidéos, il doit exposer FFmpeg avec `libx264`. La récupération Copernicus utilise aussi `curl`. Exemple avec Conda, lorsque le canal propose des paquets pour ta version de macOS.

```bash
conda create -n sose-geo -c conda-forge gdal ffmpeg
conda activate sose-geo
command -v gdalinfo gdalwarp gdal_translate gdalbuildvrt gdalsrsinfo gdaltransform ffmpeg curl
ffmpeg -hide_banner -encoders 2>/dev/null | grep libx264
"$HOME/SoSe/Atelier-14/lancer.sh"
```

Le fond relief rend le maillage et les altitudes du fichier `mnt.csv`. Les couches en ligne demandent l’accès aux services de leur fournisseur. L’installation Pharo et le rejeu des grilles incluses utilisent les fichiers livrés.

## Sources du profil

Le répertoire `fullapp/src` reprend les paquets utiles du commit indiqué dans `fullapp/REVISION`. `charger-depuis-git.st` sélectionne les classes macro, utilitaires, MNT et perception, avec les corrections de syntaxe nécessaires à Pharo 14. `installer.st` applique la reprise SoSe–ISSe et les extensions de perception. `charger-atelier.st` charge la migration macro, les commandes GDAL portables et le paquet atelier. Les fichiers NeoCSV inclus portent la licence dans `dependances/LICENCE-NeoCSV.txt`.
