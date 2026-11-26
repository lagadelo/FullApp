#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 4 || $# -gt 5 ]]; then
    printf 'Usage : %s pharo Pharo.image parametres.json dossier-sortie [run|compare|video|terrain|publication]\n' "$0" >&2
    exit 2
fi

case "${5:-run}" in
    run|compare|video|terrain|publication) export SOSE_BATCH_MODE="${5:-run}" ;;
    *) printf 'Mode inconnu : %s\n' "$5" >&2; exit 2 ;;
esac

export SOSE_BATCH_SETTINGS="$3"
export SOSE_BATCH_OUTPUT="$4"
export SOSE_ATELIER_RESOURCES
SOSE_ATELIER_RESOURCES=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)

if [[ ${SOSE_LOAD_ATELIER_SOURCE:-0} == 1 ]]; then
    exec "$1" --headless "$2" --no-default-preferences st --quit \
        "$SOSE_ATELIER_RESOURCES/charger-publications.st" "$SOSE_ATELIER_RESOURCES/lancer-lot.st"
fi
exec "$1" --headless "$2" --no-default-preferences st --quit "$SOSE_ATELIER_RESOURCES/lancer-lot.st"
