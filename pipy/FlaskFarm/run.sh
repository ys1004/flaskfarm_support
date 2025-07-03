#!/bin/bash
ENV_PATH=/data/flaskfarm_support/pipy/flaskfarm/.env_ubuntu
CONFIG=/data/flaskfarm_support/pipy/data_ubuntu/config.yaml
source $ENV_PATH/bin/activate

# redis execute
# redis-server 
COUNT=0
while true;
do
    pip install --upgrade FlaskFarm
    python -m flaskfarm --repeat ${COUNT} --config $CONFIG
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
