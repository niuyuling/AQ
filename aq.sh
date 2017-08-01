#!/bin/bash
#AQ
#set -x
path() {
    export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
}
init() {
    initdate
    check_os
    helloworld
    check_root
    #test $OS = "ubuntu" && echo -ne Debian Run ?\\n ; exit
    PWD=$(pwd)
    SRC=$PWD/AQ
    QEMU_PREFIX=/data/local/aixiao.qemu

    QEMU_VERSION="2.8.0"
    QEMU_VERSION="2.8.1.1"
    QEMU_VERSION="2.10.0-rc0"
    #QEMU_VERSION=${QEMU_VERSION:+qemu_version}
    test -n "$qemu_version" && QEMU_VERSION=$qemu_version
    QEMU_TAR_SRC=${PWD}/AQ/qemu-${QEMU_VERSION}.tar.xz
    QEMU_TAR_SRC_USR=http://download.qemu-project.org/qemu-${QEMU_VERSION}.tar.xz

    QEMU_SRC_DIR=${PWD}/AQ/qemu-${QEMU_VERSION}
    QEMU_GIT_SRC_DIR=${PWD}/qemu

    QEMU_CONFIGURE_2_8_0="
    ./configure --prefix=${QEMU_PREFIX} --target-list=arm-linux-user,arm-softmmu \
    --static \

    --enable-docs --enable-guest-agent \

    --enable-gcrypt --enable-vnc --enable-vnc-jpeg --enable-vnc-png \
    --enable-fdt --enable-bluez --enable-kvm \
    --enable-colo --enable-linux-aio --enable-cap-ng --enable-attr --enable-vhost-net --enable-bzip2 \

    --enable-coroutine-pool --enable-tpm --enable-libssh2 --enable-replication \
    --disable-libiscsi --disable-libnfs --disable-libusb \
    "
    QEMU_CONFIGURE_2_8_1_1="
    ./configure --prefix=${QEMU_PREFIX} --target-list=arm-linux-user,arm-softmmu \
    --static \

    --enable-docs --enable-guest-agent \

    --enable-gcrypt --enable-vnc --enable-vnc-jpeg --enable-vnc-png \
    --enable-fdt --enable-bluez --enable-kvm \
    --enable-colo --enable-linux-aio --enable-cap-ng --enable-attr --enable-vhost-net --enable-bzip2 \

    --enable-coroutine-pool --enable-tpm --enable-libssh2 --enable-replication \
    --disable-libiscsi --disable-libnfs --disable-libusb \
    "
    QEMU_CONFIGURE_2_10_0_RC0="
    ./configure --prefix=${QEMU_PREFIX} --target-list=arm-linux-user,arm-softmmu,i386-linux-user,i386-softmmu \
    --static \

    --enable-docs \
    --enable-guest-agent \

    --disable-sdl --disable-gtk --disable-vte --disable-curses --disable-cocoa \
    --enable-gcrypt \
    --enable-vnc --enable-vnc-jpeg --enable-vnc-png \
    --disable-virtfs --enable-fdt --enable-bluez \
    --enable-kvm --disable-hax \
    --enable-linux-aio --enable-cap-ng --enable-attr --enable-vhost-net --enable-libiscsi --disable-libnfs --disable-smartcard --disable-libusb --enable-live-block-migration --disable-usb-redir \
    --enable-bzip2 \

    --enable-coroutine-pool --disable-glusterfs --enable-tpm --enable-libssh2 --enable-replication --enable-vhost-vsock --enable-xfsctl --enable-tools \
    --enable-crypto-afalg \
    "

    QEMU_CONFIGURE_GIT=$QEMU_CONFIGURE_2_10_0_RC0

    #pkg_install

    MAKE_J="$(grep -c ^processor /proc/cpuinfo | grep -E '^[1-9]+[0-9]*$' || echo 1)" ; test $MAKE_J != "1" && make_j=$((MAKE_J - 1)) || make_j=$MAKE_J
    MAKE_J="-j${make_j}"

    if ! test "$GIT_QEMU" = "0" ; then
        #src_download
        tar_extract
        install qemu
    else
        #git_clone
        #install qemu-git
    fi
}

initdate() {
    init_date=`date +%s`
}

helloworld() {
    vvv=$(echo $OS_VER | cut -b1)
    test $OS = "ubuntu" && vvv=$(echo $OS_VER | awk -F '.' '{print$1}')
    cat <<HELLOWORLD
-----------------------------
Web: AIXIAO.ME
AQ: $VER for $OS $vvv
Qq: 1225803134
Qq: 1605227279
Qemail: 1225803134@qq.com
Qemail: 1605227279@qq.com
Author: nan13643966916@gmail.com
Android Qemu & Linux Qemu
-----------------------------
HELLOWORLD
}

check_os() {
    if cat /etc/issue | grep -i 'ubuntu' >> /dev/null 2>&1 ; then
        OS=ubuntu
        OS_VER=$(cat /etc/issue | head -n1 | awk '{print$2}')
        echo -e SYSTEM: UBUNTU $(uname -m) ${OS_VER}\\nKERNEL: $(uname -sr)
    elif test -f /etc/debian_version ; then
        OS=debian
        OS_VER=$(cat /etc/debian_version)
        echo -e SYSTEM: DEBIAN $(uname -m) ${OS_VER}\\nKERNEL: $(uname -sr)
    elif test -f /etc/centos-release ; then
        OS=centos
        OS_VER=$(cat /etc/centos-release | grep -o -E '[0-9.]{3,}') 2>> /dev/null
        echo -e SYSTEM: CENTOS $(uname -m) ${OS_VER}\\nKERNEL: $(uname -sr)
    else
        echo The system does not support
        exit
    fi
}

check_root() {
    if test $(id -u) != "0" || test $(id -g) != 0 ; then
        echo Root run $0 ?
        exit
    fi
}

bg_exec() {
    rm -f $BGEXEC_EXIT_STATUS_FILE
    $@
    echo $? > $BGEXEC_EXIT_STATUS_FILE
}
bg_wait() {
    BGEXEC_EXIT_STATUS_FILE=/tmp/QEMU.status
    bg_exec $@ >> /dev/null 2>&1 &
    wait_pid $!
    ! test -f $BGEXEC_EXIT_STATUS_FILE && exit 2
}

wait_pid() {
    while true ; do
        ps -p $1 >> /dev/null
        if test "$?" = "1" ; then
            break
        fi
        sleep 1
        echo -ne .
        sleep 1
        echo -ne .
        sleep 1
        echo -ne .
        sleep 1
        echo -ne .
        sleep 1
        echo -ne \\b\\b\\b\\b\ \ \ \ \\b\\b\\b\\b
        sleep 1
    done
}

pkg_install() {
    echo -n "Debian apt update "
    bg_wait apt-get update
    if test $(cat $BGEXEC_EXIT_STATUS_FILE) != "0" ; then
        echo -ne fail\\n
    else
        echo -ne done\\n
    fi
    echo -n "Debian apt install "
    #DEBIAN_FRONTEND=noninteractive bg_wait apt-get -qqy --force-yes install cmake autoconf pkg-config locales-all build-essential $APT_1 $APT_2 $APT_3
    #bg_wait apt-get build-dep qemu-system
    DEBIAN_FRONTEND=noninteractive bg_wait apt-get -qqy --force-yes build-dep qemu-system build-essential
    if test $(cat $BGEXEC_EXIT_STATUS_FILE) != "0" ; then
        echo -ne fail\\n-----------------------------\\n
        exit
    fi
    #! test -f /usr/include/gmp.h && ln -s $(find /usr/include/ -name gmp.h) /usr/include/gmp.h >> /dev/null 2>&1
    echo -ne done\\n-----------------------------\\n
}

src_download() {
    if ! test -f ${QEMU_TAR_SRC} ; then
        echo -n "Download QEMU ${QEMU_VERSION} "
        bg_wait wget -q -T 120 -O ${QEMU_TAR_SRC}_tmp ${QEMU_TAR_SRC_USR}
        if test $(cat $BGEXEC_EXIT_STATUS_FILE) != "0" || ! test -f ${1}_tmp ; then
            echo -ne fail\\n
            test -f ${QEMU_TAR_SRC}_tmp && rm -f ${QEMU_TAR_SRC}_tmp && exit 2
        else
            echo -ne done\\n
            mv ${QEMU_TAR_SRC}_tmp ${QEMU_TAR_SRC_USR}
        fi
    fi
}

tar_extract() {
    if ! test -d $QEMU_SRC_DIR; then
        echo -n +Extract QEMU ....
        tar -axf $QEMU_TAR_SRC -C $SRC >> /dev/null 2>&1
        if ! test -d $QEMU_SRC_DIR ; then
            echo -ne \\b\\b\\b\\bfail\\n
            exit
        else
            echo -ne \\b\\b\\b\\bdone\\n
        fi
    fi
}

git_clone() {
    if ! test -d $QEMU_GIT_SRC_DIR ; then
        echo -n "GIT PULL QEMU "
        cd $SRC
        bg_wait git clone git://git.qemu-project.org/qemu.git
        cd qemu
        bg_wait git submodule init
        bg_wait git submodule update --recursive
        if test $(cat $BGEXEC_EXIT_STATUS_FILE) != "0" || ! test -f $QEMU_GIT_SRC_DIR/configure ; then
            echo -ne fail\\n
        else
            echo -ne done\\n
        fi
    fi
}

c_configure() {
    #test "$QEMU_VERSION" = "2.8.0" && sed -i '1977i printf(\"AIXIAO.ME Compile Links, EMAIL 1605227279@QQ.COM\\n\");' vl.c
    #test "$QEMU_VERSION" = "2.8.1.1" && sed -i '1977i printf(\"AIXIAO.ME Compile Links, EMAIL 1605227279@QQ.COM\\n\");' vl.c
    a="'"
    b="\""
    c="\\"
    l=$(grep -ne "static void version(void)" vl.c | cut -d : -f1)
    l=$((l+2))
    #x=$(eval "sed -i ${a}${l}i printf(${c}${b}AIXIAO.ME Compile Links, EMAIL 1605227279@QQ.COM${c}${c}n${c}${b});${a} vl.c")
    #$x
    if test "$(grep "AIXIAO.ME" vl.c ; echo $?)" = "1" ; then
        eval "sed -i ${a}${l}i printf(${c}${b}AIXIAO.ME Compile Links, EMAIL 1605227279@QQ.COM${c}${c}n${c}${b});${a} vl.c"
    else
        exit
    fi
}

configure() {
    case $1 in
        qemu)
            case $2 in
                "2.8.0")
    ${QEMU_CONFIGURE_2_8_0}
                ;;
                "2.8.1.1")
    ${QEMU_CONFIGURE_2_8_1_1}
                ;;
                "2.9.0")

                ;;
                "2.10.0-rc0")
    ${QEMU_CONFIGURE_2_10_0_RC0}
                ;;
            esac
        ;;
        qemu-git)
    ${QEMU_CONFIGURE_GIT}
        ;;
    esac
}

install() {
    case $1 in
        qemu)
            cd $QEMU_SRC_DIR
            configure $1 $QEMU_VERSION >> /dev/null 2>&1 &
            echo -n Configure QEMU\ ;wait_pid $!
            if test -f $QEMU_SRC_DIR/Makefile ; then
                echo -ne done\\n
            else
                echo -ne fail\\n
                exit
            fi
            c_configure >> /dev/null 2>&1 &
            echo -n Configure QEMU C File\ ;wait_pid $!
            if test "$(grep "AIXIAO.ME" vl.c ; echo $?)" = "1" ; then
                echo -ne fail\\n
                exit
            else
                echo -ne done\\n
            fi
            make $MAKE_J >> /dev/null 2>&1 &
            echo -n Make QEMU\ ;wait_pid $!
            if test -x $QEMU_SRC_DIR/arm-softmmu/qemu-system-arm ; then
                echo -ne done\\n
            else
                echo -ne fail\\n
                exit
            fi
            make install >> /dev/null 2>&1 &
            echo -n Make install QEMU\ ;wait_pid $!
            if test -x $QEMU_PREFIX/bin/qemu-system-arm ; then
                echo -ne done\\n
            else
                echo -ne fail\\n
                exit
            fi
        ;;
        qemu-git)
            qemu-git() {
            cd $QEMU_GIT_SRC_DIR
            configure $1 $QEMU_VERSION >> /dev/null 2>&1 &
            echo -n Configure QEMU\ ;wait_pid $!
            if test -f $QEMU_GIT_SRC_DIR/Makefile ; then
                echo -ne done\\n
            else
                echo -ne fail\\n
                exit
            fi
            make $MAKE_J >> /dev/null 2>&1 &
            echo -n Make QEMU\ ;wait_pid $!
            if test -x $QEMU_GIT_SRC_DIR/arm-softmmu/qemu-system-arm ; then
                echo -ne done\\n
            else
                echo -ne fail\\n
                exit
            fi
            make install >> /dev/null 2>&1 &
            echo -n Make install QEMU\ ;wait_pid $!
            if test -x $QEMU_PREFIX/bin/qemu-system-arm ; then
                echo -ne done\\n
            else
                echo -ne fail\\n
                exit
            fi
            }
        ;;
    esac
}

init_exec() {
    case "$1" in
        "--help")
            cat <<HELP
---------------------------
            AQ
Android Qemu & Linux Qemu
Qq: 1225803134
Qq: 1605227279
Qemail: 1225803134@qq.com
Qemail: 1605227279@qq.com
Author: nan13643966916@gmail.com
---------------------------
--prefix=
---------------------------
--qemuversion=
---------------------------
---------------------------
--help
---------------------------
HELP
            exit
        ;;
        "--prefix")
            test "$2" != "" && QEMU_PREFIX="$2"
        ;;
        "--qemuversion")
            test "$2" != "" && qemu_version="$2"
        ;;
        "--gitqemu")
            GIT_QEMU="0"
        ;;
    esac
}
path
VER=1.02
for((i=1;i<=$#;i++)); do
    ini_cfg=${!i}
    ini_cfg_a=`echo $ini_cfg | sed -r s/^-?-?.*=//`
    ini_cfg_b=`echo $ini_cfg | grep -o -E ^-?-?[a-z]+`
    init_exec "$ini_cfg_b" "$ini_cfg_a"
done
init $@
exit
AIXIAO.ME
