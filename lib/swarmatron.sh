#!/bin/sh
cd /home/we/dust/code/swarmatron/lib
pd -jack -nojackconnect -nogui -verbose swarmatron.pd &
sleep 2
jack_connect pure_data:output_1 crone:input_1
jack_connect pure_data:output_2 crone:input_2
