#!/bin/sh
# try-lots.sh install 15 - install 15 deployments 
for i in $(seq 0 $2); do 
    helm $1 test-pvcdep-$i ./.. 
done 


