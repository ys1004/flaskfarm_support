#!/bin/bash
SCRIPT_URL="https://raw.githubusercontent.com/flaskfarm/flaskfarm_support/main/docker/normal/ff.sh"
DIR_BIN="/usr/bin"
SCRIPT_BIN_NAME="ff"

curl -Lo $DIR_BIN/$SCRIPT_BIN_NAME "$SCRIPT_URL"
chmod +x $DIR_BIN/$SCRIPT_BIN_NAME
