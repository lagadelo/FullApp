#!/usr/bin/env bash
set -euo pipefail

dossier=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
IFS= read -r vm < "$dossier/.pharo-vm"
vm=${SOSE_PHARO_VM:-$vm}
image="$dossier/SoSe-Atelier.image"

if [[ ${1:-} == lot ]]; then
    shift
    exec bash "$dossier/atelier/lancer-lot.sh" "$vm" "$image" "$@"
fi

if (( $# > 0 )); then
    exec "$vm" --headless "$image" --no-default-preferences "$@"
fi

exec "$vm" "$image" --no-default-preferences st "$dossier/atelier/installation/ouvrir.st"
