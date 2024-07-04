#!/usr/bin/env bash

pushd ~/nix

PINK="$(tput bold)$(tput setaf 201)"
RESET_COLOR="$(tput sgr0)"
echo_pink () {
	$PINK$1$RESET_COLOR
}

if nix flake update; then
	echo_pink "Flake update succeeded! Applying changes..."
	./home-manager/scripts/apply.sh
else
	echo_pink "Flake update failed!"
fi


pop