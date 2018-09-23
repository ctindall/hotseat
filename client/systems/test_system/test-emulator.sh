#!/bin/bash

echo -n "here's some bytes" > "$(cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )/post_play_state.sna"

sleep 1

if [[ "$@" == "-rom pokemon_yellow.rom -stateonexit post_play_state.sna" ]]; then
    exit 0
else
    exit 1
fi
