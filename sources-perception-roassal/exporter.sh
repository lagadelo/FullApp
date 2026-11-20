#!/usr/bin/env bash
set -euo pipefail

if (( $# != 2 )); then
    printf 'Usage : %s /chemin/vers/pharo /chemin/vers/Pharo.image\n' "$0" >&2
    exit 2
fi

pharo_vm=$(realpath "$(command -v -- "$1")")
pharo_image=$(realpath "$2")
sources=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
output="$PWD"

if [[ -n ${DRONE_DEMO_SURFACE:-} ]]; then
    DRONE_DEMO_SURFACE=$(realpath "$DRONE_DEMO_SURFACE")
    export DRONE_DEMO_SURFACE
fi

render_dir=$(mktemp -d)
trap 'rm -rf -- "$render_dir"' EXIT
cd -- "$render_dir"
"$pharo_vm" --headless "$pharo_image" st --quit "$sources/perception.st" "$sources/render.st"

for scene in frames/*; do
    ffmpeg -v error -n -framerate 20 -i "$scene/%04d.png" \
        -c:v libx264 -crf 19 -pix_fmt yuv420p -movflags +faststart \
        "$output/perception-${scene##*/}.mp4"
done
