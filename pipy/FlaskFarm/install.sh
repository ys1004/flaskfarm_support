#!/bin/bash
ENV_PATH=/data/flaskfarm_support/pipy/FlaskFarm/.env_ubuntu
rm -rf $ENV_PATH
virtualenv $ENV_PATH
source $ENV_PATH/bin/activate
pip install --upgrade flaskfarm

