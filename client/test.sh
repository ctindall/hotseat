#!/bin/bash

#start testing server (conf in ../server/hot_seat.testing.conf)
../server/script/hot_seat daemon --mode testing &

#wait until server is ready
while ! curl -s http://localhost:3000/ > /dev/null; do
    sleep 1
done; echo "testing server ready!"

#save off pid to clean up later
pid=$(ps fauxww | grep hot_seat\ daemon | grep -v grep | awk '{print $2}')

#run the client tests
raco test lib/*.rkt
success=$?

kill $pid
exit $success
