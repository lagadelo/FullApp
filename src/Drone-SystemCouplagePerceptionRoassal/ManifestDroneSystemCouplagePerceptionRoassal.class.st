"
Example: 
| dossierTerrain geometrie sommets perception vue dossierImages nombreImages pasSimule
  departD01 arriveeD01 departD02 arriveeD02 |

dossierTerrain := 'terrain-valence' asFileReference.
geometrie := STONJSON fromString: ('exemple-valence.geojson' asFileReference) contents.
sommets := (geometrie at: 'coordinates') first collect: [ :paire |
    paire first @ paire second ].

perception := PerceptionAdapter fromDirectory: dossierTerrain.
vue := PerceptionRoassalView on: perception.
dossierImages := dossierTerrain / 'images'.
dossierImages ensureCreateDirectory.

nombreImages := 60.
pasSimule := 6.0.
departD01 := 4.8846 @ 44.9376.
arriveeD01 := 4.8898 @ 44.9391.
departD02 := 4.8894 @ 44.9376.
arriveeD02 := 4.8924 @ 44.9395.

0 to: nombreImages - 1 do: [ :index |
    | fraction poses image fichier |
    fraction := index / (nombreImages - 1).
    poses := {
        PerceptionDronePose
            id: #D01
            position: (departD01 interpolateTo: arriveeD01 at: fraction)
            heightAboveGround: 200.
        PerceptionDronePose
            id: #D02
            position: (departD02 interpolateTo: arriveeD02 at: fraction)
            heightAboveGround: 125 }.

    perception recordAt: index * pasSimule polygon: sommets drones: poses.
    image := vue asForm.
    fichier := dossierImages / ((index printString padLeftTo: 4 with: $0), '.png').
    fichier binaryWriteStreamDo: [ :flux |
        flux truncate.
        (PNGReadWriter on: flux) nextPutImage: image ] ].


Script example for video generation: 

#!/usr/bin/env bash
set -euo pipefail

if (( $# != 2 )); then
    printf 'Usage : %s /chemin/vers/pharo /chemin/vers/Pharo.image\n' ""$0"" >&2
    exit 2
fi

pharo_vm=$(realpath ""$(command -v -- ""$1"")"")
pharo_image=$(realpath ""$2"")
sources=$(cd -- ""$(dirname -- ""${BASH_SOURCE[0]}"")"" && pwd)
output=""$PWD""

if [[ -n ${DRONE_DEMO_SURFACE:-} ]]; then
    DRONE_DEMO_SURFACE=$(realpath ""$DRONE_DEMO_SURFACE"")
    export DRONE_DEMO_SURFACE
fi

render_dir=$(mktemp -d)
trap 'rm -rf -- ""$render_dir""' EXIT
cd -- ""$render_dir""
""$pharo_vm"" --headless ""$pharo_image"" st --quit ""$sources/perception.st"" ""$sources/render.st""

for scene in frames/*; do
    ffmpeg -v error -n -framerate 20 -i ""$scene/%04d.png"" \
        -c:v libx264 -crf 19 -pix_fmt yuv420p -movflags +faststart \
        ""$output/perception-${scene##*/}.mp4""
done

"
Class {
	#name : 'ManifestDroneSystemCouplagePerceptionRoassal',
	#superclass : 'PackageManifest',
	#category : 'Drone-SystemCouplagePerceptionRoassal-Manifest',
	#package : 'Drone-SystemCouplagePerceptionRoassal',
	#tag : 'Manifest'
}
