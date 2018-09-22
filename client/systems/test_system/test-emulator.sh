#!/bin/bash

sleep 1

if [[ "$@" == "-rom pokemon_yellow.rom -stateonexit post_play_state.sna" ]]; then
    exit 0
else
    exit 1
fi
