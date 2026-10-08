#!/data/data/com.termux/files/usr/bin/bash
LINE="==========================================="
DIR_DATA="/storage/emulated/0/Download/flaskfarm"
CONFIGFILE="$DIR_DATA/config.yaml"
DIR_BIN="$PREFIX/bin"
SCRIPT_TYPE="termux"
SCRIPT_VERSION="1.4.1"
SCRIPT_NAME="ff.sh"
SCRIPT_URL="https://raw.githubusercontent.com/ys1004/flaskfarm_support/refs/heads/main/termux/ff.sh"
PS_COMMAND="ps -eo pid,args"

###########################################
# 공통 유틸리티
###########################################
# .bashrc 중복 등록 방지
add_to_bashrc() {
    local cmd="$1"
    if ! grep -Fxq "$cmd" "$HOME/.bashrc" 2>/dev/null; then
        echo "$cmd" >> "$HOME/.bashrc"
    fi
}

# 32/64비트 환경 자동 판별
detect_so() {
    if [ -z "$SO" ]; then
        local BIT
        BIT=$(python -c "import struct; print(struct.calcsize('P') * 8)" 2>/dev/null)
        if [ "$BIT" = "64" ] || [ "$BIT" = "32" ]; then
            export SO="$BIT"
        else
            case "$(uname -m)" in
                aarch64|x86_64) export SO="64" ;;
                *) export SO="32" ;;
            esac
        fi
    fi
}

install_sh() {
    printf "\n다운로드 스크립트 from %s\n\n" "$SCRIPT_URL"
    if curl -fsSL -o "$PREFIX/bin/$SCRIPT_NAME" "$SCRIPT_URL"; then
        chmod +x "$PREFIX/bin/$SCRIPT_NAME"
        ln -sf "$PREFIX/bin/$SCRIPT_NAME" "$PREFIX/bin/ff"
        printf "성공! 이제 ff.sh 혹은 ff로 스크립트를 실행할 수 있습니다.\n"
    else
        printf "\n실패하였습니다.\n"
    fi
}

stop() {
    $PS_COMMAND | grep main.py | grep -v grep | awk '{print $1}' | xargs -r kill -9
    $PS_COMMAND | grep flaskfarm | grep -v grep | awk '{print $1}' | xargs -r kill -9
}

prepare() {
    termux-setup-storage
    pkg update -y
    pkg upgrade -y
    pkg install -y termux-services clang binutils
}

# Python 3.11 전용 설치 및 패키지 업데이트 고정
setup_python311() {
    echo -e "\n\n[Python 3.11 환경 설정 시작]"
    pkg install -y tur-repo
    pkg update -y
    pkg install -y python3.11
    
    # 기본 python 심볼릭 링크를 3.11로 교체
    ln -sf "$PREFIX/bin/python3.11" "$PREFIX/bin/python"
    
    # pkg upgrade 시 상위 파이썬 버전으로 덮어쓰지 않도록 고정
    apt-mark hold python
    
    # pip 기본 모듈 준비 및 최신화
    python -m ensurepip 2>/dev/null || true
    python -m pip install --upgrade pip wheel setuptools
    
    echo -e "\n-------------------------------------------"
    echo -e "적용 완료된 파이썬 버전:"
    python --version
    echo -e "Python 패키지가 3.11로 고정(hold)되었습니다."
    echo -e "-------------------------------------------"
}

install() {
    stop
    mkdir -p "$DIR_DATA"
    pkg in -y git wget
    git config --global --add safe.directory '*'
    
    # C 빌드 도구 및 이미지/XML 라이브러리
    pkg in -y binutils libjpeg-turbo libpng libxml2 libxslt
    pkg in -y python-cryptography python-pillow

    # lxml 컴파일 에러 및 OOM 방지 옵션 적용
    CFLAGS="-Wno-error=incompatible-function-pointer-types -O0" python -m pip install lxml

    python -m pip install --upgrade FlaskFarm
    python -m pip install redis tzdata pathlib "celery[redis]"
    
    detect_so
    if [ ! -e "$CONFIGFILE" ]; then
        cat <<EOF >"$CONFIGFILE"
path_data: "$DIR_DATA"
use_celery: False
running_type: termux
EOF
    fi
    add_to_bashrc "nohup ff start > /dev/null 2>&1 &"
    echo "설치 완료! Termux를 재실행하거나 'ff start'를 실행하세요."
}

set64() {
    export SO="64"
    echo "Apply 64bit.."
}

set32() {
    export SO="32"
    echo "Apply 32bit.."
}

start() {
    printf "\n\nApp을 시작합니다.\n\n"
    stop

    detect_so
    echo "현재 적용 아키텍처: ${SO}bit"

    # 외장 스토리지 마운트 대기
    while [ ! -d "$(dirname "$DIR_DATA")" ]; do sleep 1; done

    # 버전 확인 및 업데이트 (루프 바깥에서 1회 수행)
    python -m pip install --upgrade FlaskFarm

    COUNT=0
    while true; 
    do
        # FlaskFarm 설치 경로 및 CPython ABI 태그 동적 탐색
        LIBSC_DIR=$(python -c "import flaskfarm, os; print(os.path.join(os.path.dirname(flaskfarm.__file__), 'lib', 'support', 'libsc'))" 2>/dev/null)
        PY_TAG=$(python -c "import sys; print(f'cpython-{sys.version_info.major}{sys.version_info.minor}')" 2>/dev/null)

        if [ -n "$LIBSC_DIR" ] && [ -d "$LIBSC_DIR" ]; then
            TARGET_SO="$LIBSC_DIR/sc.${PY_TAG}.so"
            SRC_SO="$LIBSC_DIR/sc.${PY_TAG}_${SO}.so"

            rm -f "$TARGET_SO"
            if [ -f "$SRC_SO" ]; then
                ln -sf "$SRC_SO" "$TARGET_SO"
            else
                echo "경고: 호환 바이너리 파일(${SRC_SO})을 찾을 수 없습니다."
            fi
        fi

        # Celery 사용 설정 시 Redis 서버 자동 백그라운드 구동
        if grep -q "use_celery: True" "$CONFIGFILE" 2>/dev/null; then
            if ! pgrep redis-server > /dev/null; then
                echo "Redis 서버를 실행합니다..."
                nohup redis-server > /dev/null 2>&1 &
                sleep 1
            fi
        fi

        python -m flaskfarm.main --repeat ${COUNT} --config "${CONFIGFILE}"
        RESULT=$?
        echo "PYTHON EXIT CODE : ${RESULT}.............."
        if [ "$RESULT" = "1" ]; then
            echo 'REPEAT....'
        else
            echo 'FINISH....'
            break
        fi 
        COUNT=$((COUNT + 1))
    done
}

install_ffmpeg() {
    pkg in -y ffmpeg
}

install_filebrowser() {
    FILEBROWSER_PATH="$DIR_BIN/filebrowser"
    TMP_PATH="$HOME/tmp"
    mkdir -p "$TMP_PATH"
    $PS_COMMAND | grep filebrowser | grep -v grep | awk '{print $1}' | xargs -r kill -9
    rm -f "$FILEBROWSER_PATH"

    case "$(uname -m)" in
        aarch64) ARCH="arm64";;
        x86_64)  ARCH="amd64";;
        amd64)   ARCH="amd64";;
        *)       ARCH="armv7";;
    esac

    curl -Lo "$TMP_PATH/file.tar.gz" "https://github.com/filebrowser/filebrowser/releases/download/v2.22.4/linux-$ARCH-filebrowser.tar.gz"
    tar -zxvf "$TMP_PATH/file.tar.gz" -C "$TMP_PATH"
    mv "$TMP_PATH/filebrowser" "$FILEBROWSER_PATH"
    chmod +x "$FILEBROWSER_PATH"
    add_to_bashrc "nohup $FILEBROWSER_PATH -a 0.0.0.0 -p 9996 -d ~/filebrowser.db > /dev/null 2>&1 &"
    rm -rf "$TMP_PATH"
}

install_rclone() {
    printf "\n\nRclone 설치 중...\n\n"
    curl -fsSL https://raw.githubusercontent.com/wiserain/rclone/mod/install.sh | bash
}

install_code_server() {
    pkg install -y proot-distro
    proot-distro install ubuntu
    proot-distro login ubuntu -- wget https://raw.githubusercontent.com/flaskfarm/flaskfarm_support/main/files/termux/ff.sh
    proot-distro login ubuntu -- sh code.sh

    local config="$DIR_DATA/code-server/config.yaml"
    mkdir -p "$DIR_DATA/code-server"
    if [ ! -e "$config" ]; then
        cat <<EOF >"$config"
bind-addr: 127.0.0.1:9995
auth: password
password: admin
cert: false
EOF
    fi

    add_to_bashrc "nohup proot-distro login ubuntu --bind /storage/emulated/0:/storage --bind ~:/termux_home -- sh run.sh > /dev/null 2>&1 &"
    rm -rf "$HOME/.cache/code-server"
}

install_transmission() {
    echo -e "\n\ntransmission 설치를 시작합니다."
    pkg in -y transmission
    if [ ! -d "$PREFIX/share/transmission/web_default" ]; then
        mv "$PREFIX/share/transmission/web" "$PREFIX/share/transmission/web_default"
    else
        rm -rf "$PREFIX/share/transmission/web"
    fi
    git clone https://github.com/ronggang/transmission-web-control "$HOME/twc"
    mv "$HOME/twc/src" "$PREFIX/share/transmission/web"
    rm -rf "$HOME/twc"
    sv-enable transmission
}

install_sshd() {
    echo -e "\n\nsshd 설치를 시작합니다."
    pkg in -y openssh
    echo -e "\n암호를 입력하세요\n"
    passwd
    echo "IP   : $(ifconfig wlan0 2>/dev/null | grep inet | awk '{print $2}')"
    echo "PORT : 8022"
    echo "USER : $(whoami)"
    add_to_bashrc "sshd"
}

install_vim() {
    pkg in -y vim-python
    cat <<EOF >"$HOME/.vimrc"
set encoding=utf-8
set fileencodings=utf-8,euc-kr
EOF
}

menu() {
    clear
    echo "$LINE"
    echo -e "스크립트 v$SCRIPT_VERSION - $SCRIPT_TYPE"
    echo "$LINE"
    echo -e "<설치>"
    echo "0. 저장소 접근 허용 & 서비스 준비 (필수)"
    echo "p. Python 3.11 설치 및 고정 (필수)"
    echo "1. APP 설치"
    echo "$LINE"
    echo -e "<실행>"
    echo "2. 시작 - Foreground"
    echo "3. 중지 - stop"
    echo "4. 64bit so 파일 적용"
    echo "5. 32bit so 파일 적용"
    echo "$LINE"
    echo -e "<권장 툴>"
    echo "6. code-server 설치"
    echo "7. Filebrowser 설치"
    echo "8. rclone 설치"
    echo "9. ffmpeg 설치"
    echo "$LINE"
    echo -e "<기타>"
    echo "c. vi 설치"
    echo "d. sshd 설치"
    echo "e. transmission 설치"
    echo "x. .bashrc 확인"
    echo "y. ps -ef"
    echo "z. 스크립트 업데이트"
    echo "$LINE"
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
        p)  setup_python311;;
        1)  install;;
        2)  start;;
        3)  stop;;
        4)  set64;;
        5)  set32;;
        6)  install_code_server;;
        7)  install_filebrowser;;
        8)  install_rclone;;
        9)  install_ffmpeg;;
        c)  install_vim;;
        d)  install_sshd;;
        e)  install_transmission;;
        x)  echo -e "\n\n$LINE" && cat "$HOME/.bashrc" && echo -e "\n$LINE";;
        y)  ps -ef;;
        z)  echo -e "\n\n업데이트를 시작합니다." && install_sh && echo -e "\n\n재실행하세요.\n" && exit;;
        install_sh) install_sh;;
        q)  exit 0;;
        prepare) prepare;;
        py311) setup_python311;;
        install) install;;
        start) start;;
        stop) stop;;
        [\s\n]) ;;
        *)  echo -e "\n" && exit 0;;
    esac
    echo -e "\n"
    if [ $# -eq 0 ]; then
        read -n 1 -s -r -p "아무키나 누르세요.."
    else
        exit 0
    fi
done

exit 0
