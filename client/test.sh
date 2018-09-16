#!/bin/bash

../server/script/hot_seat daemon &

while ! curl -s http://localhost:3000/ > /dev/null; do
    sleep 1
done

echo "all ready!";

pid=$(ps fauxww | grep hot_seat\ daemon | grep -v grep | awk '{print $2}')

raco test lib/*.rkt

kill $pid
