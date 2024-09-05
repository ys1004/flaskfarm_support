#!/bin/bash
source /root/export.sh
/usr/bin/ff first

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
    sleep 1000d
else
    echo 'FalskFarm container has stopped!!'
fi
