#!/usr/bin/env bash

pushd ~/nix

if nix flake update; then
	echo "Flake update succeeded! Applying changes..."
	./home-manager/scripts/apply.sh
else
	echo "Flake update failed!"
fi


popd