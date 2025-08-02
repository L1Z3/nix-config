#!/usr/bin/env bash

xdg-open $1/$(\ls -Art $1 | tail -n 1)