#!/bin/bash
#AQ
set -x
init() {
    check_root
    PWD=$(pwd)
    SRC=$PWD/AQ
    QEMU_PREFIX=/data/local/aixiao.qemu

    QEMU_VERSION="2.8.1.1"
    #QEMU_VERSION=${QEMU_VERSION:+qemu_version}
    test -n "$qemu_version" && QEMU_VERSION=$qemu_version
    QEMU_TAR_SRC=${PWD}/AQ/qemu-${QEMU_VERSION}.tar.xz
    QEMU_TAR_SRC_USR=http://download.qemu-project.org/qemu-${QEMU_VERSION}.tar.xz

    QEMU_SRC_DIR=${PWD}/AQ/qemu-${QEMU_VERSION}
    QEMU_GIT_SRC_DIR=${PWD}/qemu

    QEMU_CONFIGURE="./configure --prefix=${QEMU_PREFIX} --target-list=arm-linux-user,arm-softmmu \
    --static \
    --enable-docs --enable-guest-agent --enable-gcrypt \
    --enable-vnc --enable-vnc-jpeg --enable-vnc-png \
    --enable-fdt --enable-bluez --enable-kvm \
    --enable-colo --enable-linux-aio --enable-cap-ng \
    --enable-attr --enable-vhost-net --enable-bzip2 \
    --enable-coroutine-pool --enable-tpm --enable-libssh2 \
    --enable-replication --disable-libiscsi --disable-libnfs \
    --disable-libusb"
    #pkg_install
    #src_download
    #tar_extract
    MAKE_J="-j$(grep -c ^processor /proc/cpuinfo | grep -E '^[1-9]+[0-9]*$' || echo 1)"

    if ! test "$GIT_QEMU" = "0" ; then
        #src_download
        tar_extract
        install qemu
    else
        #git_download
        install qemu-git
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
    DEBIAN_FRONTEND=noninteractive bg_wait apt-get -qqy --force-yes build-dep qemu-system
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
        echo -n +Extract Qemu ....
        tar -axf $QEMU_TAR_SRC -C $SRC >> /dev/null 2>&1
        if ! test -d $QEMU_SRC_DIR ; then
            echo -ne \\b\\b\\b\\bfail\\n
            exit
        else
            echo -ne \\b\\b\\b\\bdone\\n
        fi
    fi
}

git_download() {
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
    test "$QEMU_VERSION" = "2.8.0" && sed -i '1977i printf(\"AIXIAO.ME Compile Links, EMAIL 1605227279@QQ.COM\\n\");' vl.c
    test "$QEMU_VERSION" = "2.8.1.1" && sed -i '1977i printf(\"AIXIAO.ME Compile Links, EMAIL 1605227279@QQ.COM\\n\");' vl.c
}

configure() {
    case $1 in
        qemu)
            case $2 in
                "2.8.0")
    #./configure --prefix=/data/local/aixiao.qemu --target-list=arm-linux-user,arm-softmmu
    ./configure --prefix=${QEMU_PREFIX} --target-list=arm-linux-user,arm-softmmu \
    --static \
    --enable-docs --enable-guest-agent --enable-gcrypt \
    --enable-vnc --enable-vnc-jpeg --enable-vnc-png \
    --enable-fdt --enable-bluez --enable-kvm \
    --enable-colo --enable-linux-aio --enable-cap-ng \
    --enable-attr --enable-vhost-net --enable-bzip2 \
    --enable-coroutine-pool --enable-tpm --enable-libssh2 \
    --enable-replication --disable-libiscsi --disable-libnfs \
    --disable-libusb
                ;;
                "2.8.1.1")
    #./configure --prefix=/data/local/aixiao.qemu --target-list=arm-linux-user,arm-softmmu
    ./configure --prefix=${QEMU_PREFIX} --target-list=arm-linux-user,arm-softmmu \
    --static \
    --enable-docs --enable-guest-agent --enable-gcrypt \
    --enable-vnc --enable-vnc-jpeg --enable-vnc-png \
    --enable-fdt --enable-bluez --enable-kvm \
    --enable-colo --enable-linux-aio --enable-cap-ng \
    --enable-attr --enable-vhost-net --enable-bzip2 \
    --enable-coroutine-pool --enable-tpm --enable-libssh2 \
    --enable-replication --disable-libiscsi --disable-libnfs \
    --disable-libusb
                ;;
                "2.9.0")

                ;;
            esac
        ;;
        qemu-git)
            ./configure
            #$QEMU_CONFIGURE
        ;;
    esac
}

install() {
    case $1 in
        qemu)
            cd $QEMU_SRC_DIR
            configure $1 $QEMU_VERSION >> /dev/null 2>&1 &
            echo -n Configure QEMU\ ;wait_pid $!
            if test -d $QEMU_SRC_DIR/Makefile ; then
                echo -ne done\\n
            else
                echo -ne fail\\n
                exit
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
            cd $QEMU_GIT_SRC_DIR
            configure $1 >> /dev/null 2>&1 &
            echo -n Configure QEMU\ ;wait_pid $!
            if test -d $QEMU_GIT_SRC_DIR/Makefile ; then
                echo -ne done\\n
            else
                echo -ne fail\\n
                exit
            fi
            make $MAKE_J >> /dev/null 2>&1 &
            echo -n Make Qemu\ ;wait_pid $!
            if test -x $QEMU_GIT_SRC_DIR/arm-softmmu/qemu-system-arm ; then
                echo -ne done\\n
            else
                echo -ne fail\\n
                exit
            fi
            #make install >> /dev/null 2>&1 &
            #echo -n Make install Qemu\ ;wait_pid $!
            #if test -x $QEMU_PREFIX/bin/qemu-system-arm ; then
            #    echo -ne done\\n
            #else
            #    echo -ne fail\\n
            #    exit
            #fi
        ;;
    esac
}

init_exec() {
    case "$1" in
        "--help")
            cat <<HELP
AQ
Android Qemu
Aixiao.me
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

for((i=1;i<=$#;i++)); do
    ini_cfg=${!i}
    ini_cfg_a=`echo $ini_cfg | sed -r s/^-?-?.*=//`
    ini_cfg_b=`echo $ini_cfg | grep -o -E ^-?-?[a-z]+`
    init_exec "$ini_cfg_b" "$ini_cfg_a"
done
init $@
exit
AIXIAO.ME
