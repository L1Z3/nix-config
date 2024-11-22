#!/usr/bin/env bash

pushd ~/nix

PINK="$(tput bold)$(tput setaf 201)"
RESET_COLOR="$(tput sgr0)"
echo_pink () {
    echo -e $PINK$1$RESET_COLOR
}

get_home_gen_id () {
    # home-manager generations | head -n 1 | awk '{print $5}'
    ls -t1d $HOME/.local/state/nix/profiles/home-manager-*-link | head -1 | awk -F'-' '{print $(NF-1)}'
}

get_sys_gen_id () {
    # nixos-rebuild list-generations --json | jq -r '.[0]' | jq -r '.generation'
    ls -t1d /nix/var/nix/profiles/system-*-link | head -1 | awk -F'-' '{print $(NF-1)}'
}

apply-home () {
    echo_pink "Running nh home switch..."
    # if home-manager switch --flake .#$USER@$HOSTNAME ${@:2} ; then
    if nh home switch "$@" ; then
        git add ./home-manager ./flake.nix ./flake.lock ./pkgs ./overlays ./media
    else
        exit 1
    fi
    # TODO only show diff if this command created a new generation
    # echo_pink "Package changes in new home generation ($(get_home_gen_id)):"
    # nix store diff-closures $(ls -t1d $HOME/.local/state/nix/profiles/home-manager-*-link | head -2 | tac)
    echo -e "\n"
}

apply-system () {
    echo_pink "Running nh os switch..."
    if nh os switch "$@" ; then
        git add ./nixos ./flake.nix ./flake.lock ./pkgs ./overlays ./media
    else
        exit 1
    fi
    # TODO only show diff if this command created a new generation
    # echo_pink "Package changes in new system generation ($(get_sys_gen_id)):"
    # nix store diff-closures $(ls -t1d /nix/var/nix/profiles/system-*-link | head -2 | tac)
    echo -e "\n"
}

alejandra . &>/dev/null \
    || ( alejandra . ; echo "formatting failed!" && exit 1)

# Shows your changes 
# TODO make this work
git diff -U0 '*.(nix|sh)'

case $1 in
  sys | system)
     apply-system "${@:2}" ;;
  home)
     apply-home "${@:2}" ;;
  *)
     apply-system "${@}" || (popd && exit)
     apply-home "${@}" ;;
esac


# Extract latest home-manager generation ID
home_gen_id=$(get_home_gen_id)

# Extract latest nixos generation ID and version
system_gen=$(nixos-rebuild list-generations --json | jq -r '.[0]')
system_gen_id=$(echo "$system_gen" | jq -r '.generation')
nixos_version=$(echo "$system_gen" | jq -r '.nixosVersion')

# Construct commit message
commit_message="home: id $home_gen_id; system: id $system_gen_id, nixos $nixos_version"

git commit -m "$commit_message"

# copy changes to clean directory
# rsync -r --exclude="secret" --exclude=".git" --quiet ~/nix/* ~/nix_cleaned

popd