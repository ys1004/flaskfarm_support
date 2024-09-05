#!/bin/bash
export RUNNING_TYPE=docker
export C_FORCE_ROOT=true
export CELERYD_HIJACK_ROOT_LOGGER=false
export GEVENT_SUPPORT=true
#export DOCKER_NONSTOP=true

redis-server --daemonize yes
COUNT=0
while true;
do
    pip install --upgrade flaskfarm
    python -m flaskfarm.main --repeat ${COUNT} --config "/data/config.yaml"
    RESULT=$?
    echo "PYTHON EXIT CODE : ${RESULT}.............."
    if [ "$RESULT" = "1" ]; then
        echo 'REPEAT....'
    else
        echo 'FINISH....'
        break
    fi
    COUNT=`expr $COUNT + 1`
done

if [ "$DOCKER_NONSTOP" = "true" ]; then
    while true;
    do
        sleep 1d
    done
else
    echo 'FalskFarm container has stopped!!'
fi
