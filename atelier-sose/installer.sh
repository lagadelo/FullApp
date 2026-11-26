#!/usr/bin/env bash
set -euo pipefail

usage() {
    printf '%s\n' 'Usage  bash installer.sh VM_PHARO IMAGE_PHARO14 DOSSIER_NEUF' \
        '       [--fullapp-clone CHEMIN | --fullapp-url URL] [--ref REF]' \
        '       [--clone-publication URL]' >&2
}

fail() { printf '%s\n' "$1" >&2; exit 1; }

absolute_file() {
    local directory
    directory=$(cd -- "$(dirname -- "$1")" && pwd -P) || return 1
    printf '%s/%s\n' "$directory" "$(basename -- "$1")"
}

if [[ ${1:-} == --help ]]; then usage; exit 0; fi
if (( $# < 3 )); then usage; exit 2; fi
vm_command=$(command -v -- "$1") || fail "VM Pharo introuvable  $1"
vm=$(absolute_file "$vm_command")
base=$(absolute_file "$2")
destination_arg=$3
shift 3

fullapp_clone=
fullapp_url=
revision_ref=
publication_url=
while (( $# > 0 )); do
    if (( $# < 2 )) || [[ -z $2 || $2 == --* ]]; then usage; exit 2; fi
    case $1 in
        --fullapp-clone) fullapp_clone=$2 ;;
        --fullapp-url) fullapp_url=$2 ;;
        --ref) revision_ref=$2 ;;
        --clone-publication) publication_url=$2 ;;
        *) usage; exit 2 ;;
    esac
    shift 2
done
if [[ -n $fullapp_clone && -n $fullapp_url ]]; then usage; exit 2; fi
if [[ -n $revision_ref && -z $fullapp_clone && -z $fullapp_url ]]; then
    fail 'Le choix d’une révision demande --fullapp-clone ou --fullapp-url.'
fi
command -v git >/dev/null || fail 'Git est requis pour créer le dépôt de l’atelier.'
if [[ ! -f $vm || ! -x $vm || $base != *.image || ! -f $base || ! -f ${base%.image}.changes ]]; then
    fail 'Indiquer la VM Pharo et une image vierge accompagnée de son fichier .changes.'
fi

bundle=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)
if [[ ! -f $bundle/installation/fullapp/REVISION ]]; then
    fail 'Le dossier installation/fullapp est absent ou incomplet.'
fi
mkdir -p -- "$(dirname -- "$destination_arg")"
destination=$(absolute_file "$destination_arg")
if [[ -e $destination || -L $destination ]]; then fail 'Choisir un dossier de sortie neuf.'; fi
stage=$(mktemp -d "$(dirname -- "$destination")/.sose-install.XXXXXX")
trap 'if [[ -d $stage ]]; then rm -rf -- "$stage"; fi' EXIT

checkout="$stage/atelier"
mkdir -- "$checkout"
for name in .project .gitignore LISEZ-MOI.md installer.sh lancer-lot.sh lancer-lot.st charger-publications.st migrer-macro.st macro-revisite.patch \
    src installation terrains cartographie visualisation-3d exemples docs documentation outils tests; do
    if [[ -e $bundle/$name ]]; then cp -R -- "$bundle/$name" "$checkout/"; fi
done

if [[ -n $fullapp_url ]]; then
    git clone --quiet --no-checkout -- "$fullapp_url" "$stage/fullapp-source"
    fullapp_clone="$stage/fullapp-source"
elif [[ -n $fullapp_clone ]]; then
    fullapp_clone=$(cd -- "$fullapp_clone" && pwd -P)
fi

profile="$checkout/installation/fullapp"
if [[ -n $fullapp_clone ]]; then
    revision_ref=${revision_ref:-HEAD}
    if ! fullapp_revision=$(git -C "$fullapp_clone" rev-parse --verify --quiet --end-of-options "$revision_ref^{commit}"); then
        fullapp_revision=$(git -C "$fullapp_clone" rev-parse --verify --quiet --end-of-options "origin/$revision_ref^{commit}") ||
            fail "Révision FullApp introuvable  $revision_ref"
    fi
    fullapp_packages=(DroneSystem-Core DroneSystem-Utils DroneSystem-Macro DroneSystem-Installation
        Drone-SystemCouplagePerceptionRoassal PerceptionMission MNT-Generation)
    fullapp_paths=()
    for package in "${fullapp_packages[@]}"; do
        path="src/$package"
        git -C "$fullapp_clone" cat-file -e "$fullapp_revision:$path/package.st" ||
            fail "Paquet manquant dans le commit FullApp  $path"
        fullapp_paths+=("$path")
    done
    rm -rf -- "$profile/src"
    git -C "$fullapp_clone" archive "$fullapp_revision" "${fullapp_paths[@]}" | tar -xf - -C "$profile"
    printf '%s\n' "$fullapp_revision" > "$profile/REVISION"
    printf '%s\n' 'FullApp, commit choisi lors de l’installation' > "$profile/ORIGINE"
    if [[ -n $fullapp_url ]]; then rm -rf -- "$stage/fullapp-source"; fi
else
    fullapp_revision=$(cat "$profile/REVISION")
fi

git init -q --template= "$checkout"
git -C "$checkout" symbolic-ref HEAD refs/heads/main
git -C "$checkout" -c core.excludesFile=/dev/null add -- .
git -C "$checkout" -c user.name='Atelier SoSe' -c user.email='atelier-sose@localhost' -c commit.gpgSign=false \
    -c core.hooksPath=/dev/null \
    commit --quiet -m 'Sources de l’atelier SoSe'
kit_revision=$(git -C "$checkout" rev-parse HEAD)
kit_tree=$(git -C "$checkout" rev-parse 'HEAD^{tree}')

candidate="$stage/SoSe-Atelier.image"
cp -- "$base" "$candidate"
cp -- "${base%.image}.changes" "${candidate%.image}.changes"
for sources in "$(dirname -- "$base")"/*.sources; do
    if [[ -f $sources ]]; then cp -- "$sources" "$stage/"; fi
done

ln -s atelier/installation/rejeu-vercors "$stage/rejeu-vercors"
for name in terrains cartographie visualisation-3d exemples; do
    if [[ -d $checkout/$name ]]; then ln -s "atelier/$name" "$stage/$name"; fi
done
cp -- "$checkout/installation/lancer.sh" "$stage/lancer.sh"
chmod +x "$stage/lancer.sh"
printf '%s\n' "$vm" > "$stage/.pharo-vm"

export SOSE_ATELIER_BUNDLE="$checkout/installation" SOSE_ATELIER_OUTPUT="$stage"
export SOSE_ATELIER_GIT="$profile" SOSE_ATELIER_ACTION=depuis-git

run_pharo() {
    (cd -- "$stage" && "$vm" --headless "$candidate" --no-default-preferences st "$@")
}

printf 'Installation dans une image Pharo neuve\n'
{
    run_pharo --save --quit "$SOSE_ATELIER_BUNDLE/charger-depuis-git.st" &&
    run_pharo --save --quit "$SOSE_ATELIER_BUNDLE/installer.st" &&
    run_pharo --save --quit "$SOSE_ATELIER_BUNDLE/charger-atelier.st" &&
    run_pharo --quit "$SOSE_ATELIER_BUNDLE/verifier.st" &&
    run_pharo --quit "$SOSE_ATELIER_BUNDLE/verifier-atelier.st"
} > "$stage/verification.txt" 2>&1 || { cat "$stage/verification.txt" >&2; exit 1; }

if [[ -n $publication_url ]]; then
    publication="$stage/publication"
    publication_kit="$publication/atelier-sose"
    git clone --quiet -- "$publication_url" "$publication"
    if [[ $(git -C "$publication" symbolic-ref --short HEAD) != atelier-sose ]]; then
        if git -C "$publication" show-ref --verify --quiet refs/remotes/origin/atelier-sose; then
            git -C "$publication" switch --quiet --track -c atelier-sose origin/atelier-sose
        else
            git -C "$publication" switch --quiet -c atelier-sose
        fi
    fi
    if [[ -e $publication_kit || -L $publication_kit ]]; then
        if [[ -L $publication_kit || ! -f $publication_kit/installation/fullapp/REVISION ]]; then
            fail 'Le dossier atelier-sose existe dans le dépôt de publication et ne contient pas le profil attendu.'
        fi
        git -C "$publication" rm --quiet -r -- atelier-sose
    fi
    mkdir -- "$publication_kit"
    git -C "$checkout" archive "$kit_revision" | tar -xf - -C "$publication_kit"
    git -C "$publication" add --force -- atelier-sose
fi

{
    printf 'Image de départ  %s\n' "$(basename -- "$base")"
    printf 'FullApp          %s\n' "$fullapp_revision"
    printf 'Atelier          %s\n' "$kit_revision"
    printf 'Arbre atelier    %s\n' "$kit_tree"
    if [[ -n $publication_url ]]; then printf 'Branche de publication locale  atelier-sose\n'; fi
} > "$stage/provenance.txt"

if [[ -e $destination || -L $destination ]]; then fail 'Le dossier de sortie existe déjà.'; fi
mv -- "$stage" "$destination"
cat "$destination/verification.txt"
printf 'Image vérifiée  %s\n' "$destination/SoSe-Atelier.image"
printf 'Ouverture       %s\n' "$destination/lancer.sh"
