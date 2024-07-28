#!/usr/bin/env bash

PINK="$(tput bold)$(tput setaf 201)"
RESET_COLOR="$(tput sgr0)"
echo_pink () {
	echo -e $PINK$1$RESET_COLOR
}

# check if any argument is provided
if [ $# -eq 0 ]; then
	echo_pink "No arguments provided. Only updating main flake lock..."
else
	# use first argument as commit message in secrets repo
	pushd ~/nix/secrets
	commit_message="$1"
	echo_pink "Committing secrets repo with message \"$commit_message\"..."
	git commit -am "$commit_message"
	popd
fi
pushd ~/nix
nix flake lock --update-input secrets
popd