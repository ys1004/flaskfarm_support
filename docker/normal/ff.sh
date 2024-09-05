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



###########################################
# 공통
###########################################
download_shell_script() {
    curl -Lo $DIR_BIN/$SCRIPT_BIN_NAME "$SCRIPT_URL"
    chmod +x $DIR_BIN/$SCRIPT_BIN_NAME
}

stop() {
    $PS_COMMAND | grep main.py | grep -v grep | awk '{print $1}' | xargs -r kill -9
    $PS_COMMAND | grep celery | grep -v grep | awk '{print $1}' | xargs -r kill -9
}

install_ffmpeg() {
    $PACKAGE_CMD install ffmpeg
}

install_filebrowser() {
    FILEBROWSER_PATH="$DIR_BIN/filebrowser"
    TMP_PATH=$APP_HOME/tmp
    mkdir -p $TMP_PATH
    $PS_COMMAND | grep filebrowser | grep -v grep | awk '{print $1}' | xargs -r kill -9
    if [ -e $FILEBROWSER_PATH ]; then
      rm $FILEBROWSER_PATH
    fi
    case "$(uname -m)" in
        aarch64) ARCH="arm64";;
        x86_64) ARCH="amd64";;
        amd64) ARCH="amd64";;
        *) ARCH="armv7";;
    esac
    curl -Lo $TMP_PATH/file.tar.gz "https://github.com/filebrowser/filebrowser/releases/download/v2.22.4/linux-$ARCH-filebrowser.tar.gz"
    tar -zxvf $TMP_PATH/file.tar.gz -C $TMP_PATH
    mv "$TMP_PATH/filebrowser" "$FILEBROWSER_PATH"
    chmod +x $FILEBROWSER_PATH
    echo 'nohup bash -c "cd / && filebrowser -a 0.0.0.0 -p 9996 -d /data/db/filebrowser.db" > /dev/null 2>&1 &' >> $APP_HOME/pre_start.sh
    rm -rf $TMP_PATH
}

install_rclone() {
    curl -fsSL https://raw.githubusercontent.com/wiserain/rclone/mod/install.sh | bash
}
###########################################


install_code_server() {
    curl -fsSL https://code-server.dev/install.sh | sh
    echo -e "\n\n"
    #read -r -p "사용할 암호를 입력하세요 > " new
    new="admin"
    config="$DIR_DATA/code-server/config.yaml"
    mkdir -p $DIR_DATA/code-server
    #old=`sed -n '3p' $config | awk '{print $2}'`
    #sed -i "s/$old/$new/" $config
    cat <<EOF >$config
bind-addr: 127.0.0.1:9997
auth: password
password: $new
cert: false
EOF
    mkdir -p $DIR_DATA/code-server
    echo "nohup code-server --bind-addr 0.0.0.0:9997 --user-data-dir $DIR_DATA/code-server --config $config > /dev/null 2>&1 &" >> $APP_HOME/pre_start.sh
    rm -rf $HOME/.cache/code-server
}


install_tool() {
    $PACKAGE_CMD update
    install_nginx
    install_code_server
    install_filebrowser
    install_rclone
    install_ffmpeg
    install_vim
    rm -rf /var/lib/apt/lists/*
}


install_vim() {
    $PACKAGE_CMD install vim
    cat <<EOF >~/.vimrc
set encoding=utf-8
set fileencodings=utf-8,euc-kr
EOF
}



install_ssh() {
    $PACKAGE_CMD install ssh
}




menu() {
    clear
    if [ -e $APP_HOME/export.sh ]; then
        . $APP_HOME/export.sh
    fi
    echo $LINE
    echo -e "스크립트 v$SCRIPT_VERSION - $SCRIPT_TYPE"
    echo $LINE
    echo -e "<설치>"
    echo "0. 설치 : 일반"
    echo "1. 설치 : 최소"
    echo $LINE
    echo -e "<실행>"
    echo "2. 시작 - Foreground (UI)"
    echo "3. 시작 - Foreground (celery)"
    echo "4. 중지"
    echo $LINE   
    echo -e "<권장 툴>" 
    echo "5. nginx 설치"
    echo "6. code-server 설치"
    echo "7. Filebrowser 설치"
    echo "8. rclone 설치 (이치로님 버전)"
    echo "9. ffmpeg 설치" 
    echo "a. 권장 툴 전체 설치"
    echo $LINE   
    echo -e "<기타>"
    echo "b. apt update"
    echo "c. vi 설치"
    echo "d. ssh 설치"
    echo "e. App 설치"
    echo "w. cat pre_start.sh"
    echo "x. cat export.sh"
    echo "y. ps -ef"
    echo "z. 스크립트 업데이트"
    echo $LINE
}

app_menu() {
    clear
    echo $LINE
    echo -e "스크립트 v$SCRIPT_VERSION - $SCRIPT_TYPE"
    echo $LINE
    echo -e "<App 설치>"
    echo "1. imueRoid님의 mycomix 설치"
    echo "2. 재키님의 웹툰뷰어 설치"
    echo "3. Kod Explorer 설치"
    echo "4. transmission 설치"
    echo "5. squid 설치 - proxy (기본포트:9994)"    
    echo $LINE
    read -n 1 -s -p "메뉴 선택 > " cmd
    case $cmd in
        1) install_mycomix;;
        2) install_webtoon_viewer;;
        3) install_kodexplorer;;
        4) install_transmission;;
        5) install_squid;;
    esac
    echo -e "\n"
}


while true; do
    if [ $# -eq 0 ]; then
        menu
        read -n 1 -s -p "메뉴 선택 > " cmd
    else
        cmd=$1
    fi

    case $cmd in
        0)  install;;
        2)  stop && foreground_start;;
        3)  $PS_COMMAND | grep main.celery | grep -v grep | awk '{print $1}' | xargs -r kill -9
            /usr/bin/python -m celery --app=main.celery --workdir=/root/flaskfarm worker --loglevel=INFO -c $CELERY_WORKER_COUNT --executable=/usr/bin/python --config_filepath=/data/config.yaml --running_type=native;;
        4)  stop;;
        5)  install_nginx;;
        6)  install_code_server;; 
        7)  install_filebrowser;;
        8)  install_rclone;;
        9)  install_ffmpeg;;
        a)  install_tool;;
        b)  $PACKAGE_CMD update;;
        c)  install_vim;;
        d)  install_ssh;;
        e)  app_menu;;
        w)  echo -e "\n\n$LINE" && cat "$APP_HOME/pre_start.sh" && echo -e "\n$LINE";;
        x)  echo -e "\n\n$LINE" && cat "$APP_HOME/export.sh" && echo -e "\n$LINE";;
        y)  echo "`ps -ef`";;
        z)  echo -e "\n\n업데이트를 시작합니다." && download_shell_script && echo -e "\n\n재실행하세요." && exit;;
        prepare) prepare;;
        install) install;;
        install_tool) install_tool;;
        start) start;;
        stop) stop;;
        restart) stop && start;;
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
