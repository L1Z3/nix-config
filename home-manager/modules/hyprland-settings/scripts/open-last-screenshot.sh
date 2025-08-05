#!/usr/bin/env bash

xdg-open $(\ls -Art $1 | tail -n 1)