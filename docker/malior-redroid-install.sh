#!/bin/env bash
# set -ex
MH_BEFORE=${MALIOR_HOME:-$HOME}
source ${MALIOR_HOME:-$HOME}/.config/malior/envs.sh
[ ! -z "$MALIOR_HOME" ] && [ "$MH_BEFORE" != "$MALIOR_HOME" ] \
    && echo "Found new MALIOR_HOME $MH_BEFORE -> $MALIOR_HOME" \
    && echo "It is recommended to put MALIOR_HOME in .bashrc instead of envs.sh" \
    && source $MALIOR_HOME/.config/malior/envs.sh

MALIOR_HOME=${MALIOR_HOME:-$HOME}
MALIOR_PREFIX=${MALIOR_PREFIX:-https://github.com/ChisBread}
MALIOR_DROID_IMAGE=${MALIOR_IMAGE:-chisbread/rk3588-gaming:redroid-firefly}

MALIOR_RUNNING=1
if [ "`sudo docker ps|grep redroid-rk3588-$USER`" == "" ]; then
    MALIOR_RUNNING=0
fi
DOCKER_OPTS='-i'
if [ -t 0 ] && [ -t 1 ]; then
    DOCKER_OPTS=$DOCKER_OPTS" -t"
fi
function help() {
    cat <<EOF
Usage: 
    $(basename $0) [command] <game|application> <args>
    note. kernel config PSI ASHMEM ANDROID_BINDERFS etc... is required
    warning. zygisk is not supported, will mess up the container when enabled
    e.g. 
        'malior-droid whoami' is same as 'adb shell whoami' (root user)
        'adb connect localhost:5555' for adb
        'scrcpy -s localhost:5555' view redroid screen
Command:
    help                   This usage guide
    update                 Update malior redroid image
    recreate               Recreate malior redroid container
    destroy                Stop and remove malior redroid container
    pause|stop             Pause(docker stop) malior redroid container
    resume|start           Resume(docker start) malior redroid container
    restart                Restart malior redroid container
    resize                 Resize redroid window e.g. malior-droid resize 1920x1080
    install-overlay        Overlays, it will be mounted on the rootfs of redroid and stored in ~/.local/malior/redroid_overlay
                               base: Automatically installed overlay, providing magisk support and gapps support
EOF
}

function resize() {
    sudo docker exec $DOCKER_OPTS redroid-rk3588-$USER  /system/bin/sh -c "
        wm size $1
    "
}
function safetydownloadto() {
    sudo wget $1 -O $2
    [ "$?" != "0" ] && echo "failed to download $1"
}
function install_overlay() {
    [ ! -d $MALIOR_HOME/.local/malior/redroid_overlay/  ] && mkdir -p $MALIOR_HOME/.local/malior/redroid_overlay
    safetydownloadto $MALIOR_PREFIX/malior/releases/download/redroid-overlays-latest/$1_overlay.zip \
        $MALIOR_HOME/.local/malior/redroid_overlay/$1_overlay.zip
    sudo bash -c "cd $MALIOR_HOME/.local/malior/redroid_overlay/ && unzip -o $1_overlay.zip && rm -f $1_overlay.zip"
}
function runtime_start() {
    if [ ! -d $MALIOR_HOME/.local/malior/redroid_overlay/  ]; then
        mkdir -p $MALIOR_HOME/.local/malior/redroid_overlay
        echo "install base overlay"
        install_overlay base
        sudo chmod -R +x $MALIOR_HOME/.local/malior/redroid_overlay/vendor/bin/*
    fi

    if [ "`sudo docker container ls -a|grep redroid-rk3588-$USER`" == "" ]; then
        sudo docker run -itd --privileged --name redroid-rk3588-$USER \
            -v $MALIOR_HOME/.local/malior/redroid:/data \
            $(sudo find $MALIOR_HOME/.local/malior/redroid_overlay -type f | sed -e 's@\(.*local.*redroid_overlay\)\(.*\)@-v \1\2:\2@g') \
            -p ${MALIOR_DROID_PORT:-5555}:5555 \
            --entrypoint /init \
            $(ls -v /dev|grep -P 'mali0|fb0|kfd|nvidia|vga_arbiter|video|dri|snd|/shm'|awk '{print "-v /dev/"$1":/dev/"$1}') \
            ${MALIOR_DROID_IMAGE} \
            androidboot.hardware=rk30board
        
        echo "Some features (ro.secure=0 etc...) will take effect on the next start"

    else
        sudo docker start redroid-rk3588-$USER
    fi
    #init
     # Wait for some initialization
    LOOP_CNT=0
    
    echo "checking android status..."
    while :
    do
        LOOP_CNT=$(( $LOOP_CNT + 1 ))
        if [ $LOOP_CNT -eq 100 ]; then
            sudo docker rm -f redroid-rk3588-$USER
            exit 1
        fi
        sleep 4
        echo "check android status $LOOP_CNT times"

        sudo docker exec $DOCKER_OPTS redroid-rk3588-$USER \
            /system/bin/sh -c '[ -e /dev/binderfs/binder ] || exit 1'
        [ "$?" != "0" ] && echo '    /dev/binderfs/binder not available' && continue
        sudo docker exec $DOCKER_OPTS redroid-rk3588-$USER \
            /system/bin/sh -c '[ "$(ps |grep com.android.systemui)" != "" ] || exit 1'
        [ "$?" != "0" ] && echo '    com.android.systemui not available' && continue

        break
    done

    # settings put global private_dns_mode off ;
    GATEWAY=$(sudo docker inspect redroid-rk3588-$USER |grep '"Gateway"'| sed -e 's@[^0-9]*\([0-9].*[0-9]\)".*@\1@g'|sort -u)
    CONIP=$(sudo docker inspect redroid-rk3588-$USER |grep '"IPAddress"'| sed -e 's@[^0-9]*\([0-9].*[0-9]\)".*@\1@g'|sort -u)
    IPPRX=$(sudo docker inspect redroid-rk3588-$USER |grep '"IPPrefixLen"'| sed -e 's@[^0-9]*\([0-9]*\)[^0-9]*@\1@g'|sort -u)
    sudo docker exec $DOCKER_OPTS redroid-rk3588-$USER  /system/bin/sh -c "
        wm size ${MALIOR_DROID_WMSIZE:-1080x2160} ; \
        sed -i 's@ro.secure=1@ro.secure=0@g' /system/build.prop ; \
        setprop persist.sys.locale ${MALIOR_DROID_LANG:-en}; \
        setprop persist.sys.timezone \"${MALIOR_DROID_TZ:-$(cat /etc/timezone)}\"; \
        ip addr add $CONIP/$IPPRX dev eth0 ; \
        ip route add default via $GATEWAY dev eth0 ; \
        setprop ro.boot.redroid_net_ndns 2 ; \
        setprop ro.boot.redroid_net_dns1 ${MALIOR_DROID_DNS1:-8.8.8.8} ; \
        setprop ro.boot.redroid_net_dns2 ${MALIOR_DROID_DNS2:-8.8.4.4} ; \
        /vendor/bin/ipconfigstore ; \
        pm uninstall -k --user 0 com.firefly.fireflyapi2service ; \
        pm uninstall -k --user 0 com.firefly.fireflyapi2service ; \
        pm uninstall -k --user 0 com.firefly.fireflyapi2demo ; \
        pm uninstall -k --user 0 com.firefly.fireflyapi2demo ; \
        stop;sleep 3;start; \
    "
}
COMMAND=$1
case $COMMAND in
    help)
        help
        exit
        ;;
    update)
        if [ $MALIOR_RUNNING -eq 1 ]; then
            sudo docker rm -f redroid-rk3588-$USER
        fi
        sudo docker pull ${MALIOR_DROID_IMAGE}
        MALIOR_RUNNING=0
        shift
        ;;
    recreate)
        if [ $MALIOR_RUNNING -eq 1 ]; then
            sudo docker rm -f redroid-rk3588-$USER
        fi
        MALIOR_RUNNING=0
        shift
        ;;
    destroy)
        sudo docker rm -f redroid-rk3588-$USER
        exit
        ;;
    pause|stop)
        sudo docker stop redroid-rk3588-$USER
        exit
        ;;
    resume|start)
        runtime_start
        exit
        ;;
    restart)
        sudo docker stop redroid-rk3588-$USER
        runtime_start
        exit
        ;;
    resize)
        resize $2
        exit
        ;;
    install-overlay)
        install_overlay $2
        exit
        ;;

esac

if [ $MALIOR_RUNNING -eq 0 ]; then
    runtime_start
fi

sudo docker exec $DOCKER_OPTS redroid-rk3588-$USER  /system/bin/sh -c "$*" 
