#!/bin/bash
LINE="==========================================="
APP_HOME="$HOME/flaskfarm"
APP_NAME="flaskfarm"
DIR_DATA="/data"
DIR_BIN="/usr/bin"
GIT="https://github.com/flaskfarm/flaskfarm.git"

SCRIPT_TYPE="docker"
SCRIPT_VERSION="1.3.0"
SCRIPT_NAME="ff.sh"
SCRIPT_BIN_NAME="ff"
SCRIPT_URL="https://raw.githubusercontent.com/flaskfarm/flaskfarm_support/main/docker/normal/ff.sh"

PYTHON="python"
PIP="pip"
PACKAGE_CMD="apt-get -y --no-install-recommends"
PS_COMMAND="ps -eo pid,args"


download_shell_script() {
    curl -Lo $DIR_BIN/$SCRIPT_BIN_NAME "$SCRIPT_URL"
    chmod +x $DIR_BIN/$SCRIPT_BIN_NAME
}

export_env() {
    source /root/export.sh
}

stop_web() {
    $PS_COMMAND | grep flaskfarm.main | grep -v grep | awk '{print $1}' | xargs -r kill -9
    $PS_COMMAND | grep main.py | grep -v grep | awk '{print $1}' | xargs -r kill -9
}
stop_celery() {
    $PS_COMMAND | grep celery | grep -v grep | awk '{print $1}' | xargs -r kill -9
}

stop() {
    stop_web
    stop_celery
}

container_stop() {
    stop
    $PS_COMMAND | grep sleep | grep -v grep | awk '{print $1}' | xargs -r kill -9
}

start_web_module() {
    export_env
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
}

start_web_source() {
    export_env
    COUNT=0
    while true;
    do
        python /data/flaskfarm/main.py --repeat ${COUNT} --config "/data/config.yaml"
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
}

start_celery_module() {
    export_env
    celery -A flaskfarm.main.celery worker --loglevel=info --pool=gevent --concurrency=10 --config_filepath=/data/config.yaml --running_type=docker
}

start_celery_source() {
    export_env
    cd /data/flaskfarm && celery -A main.celery worker --loglevel=info --pool=gevent --concurrency=10 --config_filepath=/data/config.yaml --running_type=docker
}

install_rclone() {
    curl -fsSL https://raw.githubusercontent.com/wiserain/rclone/mod/install.sh | bash
}

install_ffmpeg() {
    $PACKAGE_CMD install ffmpeg aria2 mkvtoolnix
}


menu() {
    clear
    if [ -e $APP_HOME/export.sh ]; then
        . $APP_HOME/export.sh
    fi
    echo $LINE
    echo -e "스크립트 v$SCRIPT_VERSION - $SCRIPT_TYPE"
    echo $LINE
    echo -e "<실행>"
    echo "1. Start Web (Module)"
    echo "2. Start Celery (Module)"
    echo "3. Start Web (Source)"
    echo "4. Start Celery (Source)"
    echo "5. Stop"
    echo $LINE   
    echo -e "<권장 툴>" 
    echo "a. rclone 설치 (이치로님 버전)"    
    echo "b. apt update"
    echo "c. ffmpeg, mkvtoolnix, aria2 설치" 
    echo "w. Container 계속실행 (export DOCKER_NONSTOP=true)"
    echo "x. Container Stop"
    echo "y. ps -ef"
    echo "z. 스크립트 업데이트"
    echo $LINE
}

first() {
    source /root/export.sh
    if [ "$DOCKER_FIRSTRUN" = "false" ]; then
        echo ""
    else
        #echo -e "export DOCKER_FIRSTRUN=false" >> /root/export.sh
        echo -e ""
        echo $LINE
        echo -e "Run setup.sh"
        echo $LINE
        $PIP install lxml xmltodict sqlitedict
        cat <<EOF > /root/export.sh
export RUNNING_TYPE=docker
export C_FORCE_ROOT=true
export CELERYD_HIJACK_ROOT_LOGGER=false
export GEVENT_SUPPORT=true
export DOCKER_FIRSTRUN=false
EOF
        /data/setup.sh
    fi
}


while true; do
    if [ $# -eq 0 ]; then
        menu
        read -n 1 -s -p "메뉴 선택 > " cmd
    else
        cmd=$1
    fi

    case $cmd in
        1)  stop_web && start_web_module;;
        2)  stop_celery && start_celery_module;;
        3)  stop_web && start_web_source;;
        4)  stop_celery && start_celery_source;;
        5)  stop;;
        a)  install_rclone;;
        b)  $PACKAGE_CMD update;;
        c)  install_ffmpeg;;
        v)  echo -e "export DOCKER_NONSTOP=true" >> /root/export.sh;;
        w)  cat <<EOF > /root/export.sh
export RUNNING_TYPE=docker
export C_FORCE_ROOT=true
export CELERYD_HIJACK_ROOT_LOGGER=false
export GEVENT_SUPPORT=true
export DOCKER_FIRSTRUN=false
export DOCKER_NONSTOP=true
EOF
            ;;
        x)  container_stop;;
        y)  echo "`ps -ef`";;
        z)  echo -e "\n\n업데이트를 시작합니다." && download_shell_script && echo -e "\n\n재실행하세요." && exit;;
        first) first;;
        [\s\n]) ;;
        *)
            exit
    esac
    echo -e "\n"
    if [ $# -eq 0 ]; then
        read -n 1 -s -r -p "아무키나 누르세요.."
    else
        exit 0
    fi
done
exit
