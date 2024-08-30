#!/data/data/com.termux/files/usr/bin/bash
LINE="==========================================="
DIR_DATA="/storage/emulated/0/Download/flaskfarm"
CONFIGFILE=$DIR_DATA/config.yaml
DIR_BIN="$PREFIX/bin"
SCRIPT_TYPE="termux"
SCRIPT_VERSION="1.2.8"
SCRIPT_NAME="ff.sh"
SCRIPT_URL="https://raw.githubusercontent.com/flaskfarm/flaskfarm_support/main/files/termux/ff.sh"
PS_COMMAND="ps -eo pid,args"
 
 
###########################################
# 공통
###########################################
install_sh() {
    printf "\n다운로드 스크립트 from $SCRIPT_URL\n\n"
    if curl -fsSL -o $PREFIX/bin/$SCRIPT_NAME "$SCRIPT_URL"; then
        chmod +x $PREFIX/bin/$SCRIPT_NAME
        ln -sf $PREFIX/bin/$SCRIPT_NAME $PREFIX/bin/ff
        printf "성공! 이제 ff.sh 혹은 ff로 스크립트를 실행할 수 있습니다."
    else
        printf "\n실패하였습니다."
    fi
}
 
stop() {
    $PS_COMMAND | grep maiin.py | grep -v grep | awk '{print $1}' | xargs -r kill -9
    $PS_COMMAND | grep flaskfarm | grep -v grep | awk '{print $1}' | xargs -r kill -9
}

install_ffmpeg() {
    pkg in -y ffmpeg
}


install_filebrowser() {
    FILEBROWSER_PATH="$DIR_BIN/filebrowser"
    TMP_PATH=$HOME/tmp
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
    echo "nohup $FILEBROWSER_PATH -a 0.0.0.0 -p 9996 -d ~/filebrowser.db > /dev/null 2>&1 &" >> $HOME/.bashrc
    rm -rf $TMP_PATH
}
 
install_rclone() {
    printf "\n\nRclone 설치 중...\n\n"
    curl -fsSL https://raw.githubusercontent.com/wiserain/rclone/mod/install.sh | bash
}

###########################################
 
install_code_server() {
    pkg install -y proot-distro
    proot-distro install ubuntu
    proot-distro login ubuntu -- wget https://raw.githubusercontent.com/flaskfarm/flaskfarm_support/main/files/termux/ff.sh
    proot-distro login ubuntu -- sh code.sh

    config="$DIR_DATA/code-server/config.yaml"
    mkdir -p $DIR_DATA/code-server
    if [ ! -e $config ]; then
        cat <<EOF >$config
bind-addr: 127.0.0.1:9995
auth: password
password: admin
cert: false
EOF
    fi

    echo "nohup proot-distro login ubuntu --bind /storage/emulated/0:/storage --bind ~:/termux_home -- sh run.sh > /dev/null 2>&1 &" >> $HOME/.bashrc
    rm -rf $HOME/.cache/code-server
}

install_transmission() {
    echo -e "\n\ntransmission 설치를 시작합니다."
    pkg in -y transmission
    if [ ! -d $PREFIX/share/transmission/web_default ]; then
        mv $PREFIX/share/transmission/web $PREFIX/share/transmission/web_default
    else
        rm -rf $PREFIX/share/transmission/web
    fi
    git clone https://github.com/ronggang/transmission-web-control $HOME/twc
    mv $HOME/twc/src $PREFIX/share/transmission/web
    rm -rf $HOME/twc
    sv-enable transmission
}
 
install_sshd() {
    echo -e "\n\nsshd 설치를 시작합니다."
    pkg in -y openssh
    echo -e "\n암호를 입력하세요\n"
    passwd
    echo "IP   : "$(ifconfig wlan0 | grep inet | awk '{print $2}')
    echo "PORT : 8022"
    echo "USER : $(whoami)"
    echo "sshd" >> $HOME/.bashrc
}
 
install_vim() {
    pkg in -y vim-python
    cat <<EOF >~/.vimrc
set encoding=utf-8
set fileencodings=utf-8,euc-kr
EOF
}
 
###########################################

prepare() {
    termux-setup-storage
    pkg update -y
    pkg upgrade -y
    pkg install -y termux-services
}


install() {
    stop
    mkdir -p $DIR_DATA    
    pkg in -y git wget python3.10
    git config --global --add safe.directory '*'
    python -m pip install --upgrade pip wheel setuptools
    pkg in -y binutils libjpeg-turbo libpng libxml2 libxslt 
    pkg in -y python-cryptography python-lxml python-pillow
    pip install --upgrade FlaskFarm
    pip install redis tzdata lxml pathlib

    if [ ! -e $CONFIGFILE ]; then
        cat <<EOF >$CONFIGFILE
path_data: "$DIR_DATA"
use_celery: false
running_type: termux
EOF
    fi
    echo "nohup ff start > /dev/null 2>&1 &" >> $HOME/.bashrc
    echo "Restart termux!"
}
 
 
start() {
    printf "\n\nApp을 시작합니다.\n\n"
    stop()
    # 외장 USB를 sdcard로 쓰면 재부팅 시에 스토리지가 올라올때까지 기다려야 한다.
    while [ ! -d "$(dirname "$DIR_DATA")" ]; do sleep 1; done
 
    COUNT=0
    while true; 
    do
        pip install --upgrade FlaskFarm
        python -m flaskfarm.main --repeat ${COUNT} --config ${CONFIGFILE}
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
 
 
menu() {
    clear
    echo $LINE
    echo -e "스크립트 v$SCRIPT_VERSION - $SCRIPT_TYPE"
    echo $LINE
    echo -e "<설치>"
    echo "0. 저장소 접근 허용 & 서비스 준비 (필수)"
    echo "1. APP 설치"
    echo $LINE
    echo -e "<실행>"
    echo "2. 시작 - Foreground"
    echo "3. 중지 - stop"
    echo $LINE   
    echo -e "<권장 툴>" 
    echo "6. code-server 설치"
    echo "7. Filebrowser 설치"
    echo "8. rclone 설치 (이치로님 버전)"
    echo "9. ffmpeg 설치" 
    echo $LINE   
    echo -e "<기타>"
    echo "c. vi 설치"
    echo "d. sshd 설치"
    echo "e. transmission 설치"
    echo "x. .bashrc 확인"
    echo "y. ps -ef"
    echo "z. 스크립트 업데이트"
    echo $LINE
}
 
 
 
while true; do
    if [ $# -eq 0 ]; then
        menu
        read -n 1 -p "메뉴 선택 > " cmd
    else
        cmd=$1
    fi
    case $cmd in
        0)  prepare;;
        1)  install;;
        2)  start;;
        3)  stop;;
        6)  install_code_server;; 
        7)  install_filebrowser;;
        8)  install_rclone;;
        9)  install_ffmpeg;;
        c)  install_vim;;
        d)  install_sshd;;
        e)  install_transmission;;
        x)  echo -e "\n\n$LINE" && cat "$HOME/.bashrc" && echo -e "\n$LINE";;
        y)  echo "`ps -ef`";;
        z)  echo -e "\n\n업데이트를 시작합니다." && install_sh && echo -e "\n\n재실행하세요.\n" && exit;;
        install_sh) install_sh;;
        q) install_sh;;
        prepare) prepare;;
        install) install;;
        start) start;;
        stop) stop;;
        [\s\n]) ;;
        *) echo -e "\n" && exit
    esac
    echo -e "\n"
    if [ $# -eq 0 ]; then
        read -n 1 -s -r -p "아무키나 누르세요.."
    else
        exit 0
    fi
done

exit
