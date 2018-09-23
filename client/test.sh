#!/bin/bash

#start testing server (conf in ../server/hot_seat.testing.conf)
../server/script/hot_seat daemon --mode testing &

#wait until server is ready
while ! curl -s http://localhost:3000/ > /dev/null; do
    sleep 1
done; echo "testing server ready!"

#save off pid to clean up later
pid=$(ps fauxww | grep hot_seat\ daemon | grep -v grep | awk '{print $2}')

success=0
#run the client tests
for f in  lib/games.rkt \
          lib/util.rkt \
          lib/network.rkt \
          lib/systems.rkt; do
    # Looping to control the order of tests, and to get better reporting on tests in each file
    if ! raco test $f; then
	success=255
    fi
done

kill $pid
exit $success
