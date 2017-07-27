#!/bin/bash

#
# p4_build.sh
#
# This script utilizes p4-build system to build user's P4 program within
# the framework of the chosen SDE
#
# Directory Organization:
#
# $P4_PATH ---> points to the "main" p4 file that constitutes user program
#
# Recommended organization of user directories:
#
# $YOUR_DIR \
#    p4src     -- P4 code
#    ptf-tests -- PTF tests
#
# $SDE \
#    build/user/$P4_NAME -- p4-build directory for the program
#    logs/user/$P4_NAME  -- log files for the build    
#    install             -- programs are installed according to p4-build
#
# The build should be done using the tools in $SDE and $SDE_INSTALL
# Similarly, when test is going to be run, the model, the drivers, PTF, etc. 
# should be coming from $SDE and $SDE_INSTALL
#

#
# Just stop if there is any problem
#
set -e

p4src=p4src
ptf=ptf-tests
jobs=-j2

packages=packages         # The SDE subdirectory SDE where package tarballs are
pkgsrc=pkgsrc             # The SDE subdirectory, where tarbals are untarred
build=build               # The SDE subdirectory, where the builds are done
logs=logs                 # The SDE subdirectory, where build logs are stored
install=install
target_platform=--with-tofino

usage() {
    echo "Usage: p4-build <path-to-p4-program> [p4-build options]"
    echo
    echo "Typical p4-build options to use:"
    echo "     Platforms:"
    echo "                --with-tofino (*)"
    echo "                --with-tofinobm"
    echo "                --with-bmv2"
    echo "     Options:"
    echo "                enable_thrift=yes"
    echo "     Makefile variables"
    echo "                P4C           -- path to the P4 compiler"
    echo "                P4PPFLAGS     -- parameters for P4 CPP invocation"
    echo "                P4FLAGS       -- p4 compiler flags"
    echo "                CFLAGS        -- C compiler flags"
    echo "                CXXFLAGS      -- C++ compiler flags"
    echo "                . . ."
}

#
# This function makes sure that all "normal" SDE-related variables are there
#
check_environment() {
    if [ -z $SDE ]; then
        echo "WARNING: SDE Environment variable is not set"
        echo "         Assuming the latest in your \$HOME"
        SDE=`ls -d ~/bf-sde* | tail -1`
    fi

    echo "Using SDE ${SDE}"

    if [ -z $SDE_INSTALL ]; then
        echo "WARNING: SDE_INSTALL Environment variable is not set"
        echo "         Assuming $SDE/install"
        SDE_INSTALL=$SDE/install
    else
        echo "Using SDE_INSTALL ${SDE_INSTALL}"
    fi

    if [[ ":$PATH:" == *":$SDE_INSTALL/bin:"* ]]; then
        echo "Your path contains \$SDE_INSTALL/bin. Good"
    else
        echo "Adding $SDE_INSTALL/bin to your PATH"
        PATH=$SDE_INSTALL/bin:$PATH
    fi

	PROJ_DIR=$PWD
    SDE_PACKAGES=$SDE/$packages
    SDE_PKGSRC=$SDE/$pkgsrc
    SDE_BUILD=$SDE/$build
    SDE_LOGS=$SDE/$logs
}

package_dir() {
    package_name=$1
    shift

    package_list=(`cd $SDE_PKGSRC; ls -d ${package_name}-* 2>/dev/null`)
    num_packages=${#package_list[@]}
    case $num_packages in
        0)
            echo ""
            ;;
        1)
            echo ${package_list[0]}
            ;;
        *)
            prompt="\nWARNING: Multiple versions of $package_name package found in \$SDE/$pkgsrc"
            for p in `seq 0 $[$num_packages-1]`; do
                prompt="${prompt}\n    ${p} -- ${package_list[$p]}"
            done
            prompt="$prompt\nPlease choose one(0..$[$num_packages-1])[0]"
            prompt=`echo -e $prompt`
            read -p "$prompt " p
            if [ -z $p ]; then
                p=0
            fi
            echo ${package_list[$p]}
            ;;
    esac
    return 0
}

build_case() {
    P4_NAME=`basename $P4_PATH .p4`
    P4_PREFIX=$P4_NAME

    P4_BUILD=$PROJ_DIR/build
    P4_LOGS=$PROJ_DIR/logs
    P4_INSTALL=$PROJ_DIR/install

    p4_build=`package_dir p4-build`
    if [ -z $p4_build ]; then 
        echo "ERROR: p4-build package not found in $SDE"
        return 1
    fi

    p4_examples=`package_dir p4-examples`
    if [ -z $p4_examples ]; then 
        echo "ERROR: p4-examples package not found in $SDE"
        return 1
    fi

    mkdir -p $P4_BUILD
    mkdir -p $P4_LOGS
    mkdir -p $P4_INSTALL
    cd $P4_BUILD
    
    echo -n "Configuring $P4_NAME in $P4_BUILD ... "
	if $SDE_PKGSRC/$p4_build/configure            \
           --prefix=$P4_INSTALL                \
           P4_PATH=$P4_REALPATH                \
           P4_NAME=$P4_NAME                    \
           P4_PREFIX=$P4_PREFIX                \
           enable_thrift=yes                   \
		   $target_platform                    \
		   CPPFLAGS=-I$SDE_INSTALL/include     \
           "$@" &> $P4_LOGS/configure.log; then
        echo DONE
    else
        echo FAILED
        tail $P4_LOGS/configure.log
        echo See $P4_LOGS/configure.log for details
        cd $P4
        return 1
    fi

    echo -n "   Building $P4_NAME ... "
    if make ${jobs} &> $P4_LOGS/make.log; then
        echo DONE
    else
        echo FAILED
        tail $P4_LOGS/make.log
        echo See $P4_LOGS/make.log for details
        cd $P4
        return 1
    fi

    echo -n " Installing $P4_NAME in $P4_INSTALL ... "
    if make install &> $P4_LOGS/install.log; then
        echo DONE
    else
        echo FAILED
        tail $P4_LOGS/install.log
        echo See $P4_LOGS/install.log for details
        cd $P4
        return 1
    fi

    #
    # Installing the conf file
    #
    mkdir -p ${P4_INSTALL}/share/p4/targets
    sed -e "s/TOFINO_SINGLE_DEVICE/${P4_NAME}/"                  \
        $SDE_PKGSRC/${p4_examples}/tofino_single_device.conf.in  \
        > ${P4_INSTALL}/share/p4/targets/${P4_NAME}.conf 

    cd $P4
    return 0
}

#
# Here we go...
#
P4_PATH=$1
shift

if [ -z $P4_PATH ]; then
    usage
    exit 1
fi

if [ ! -f $P4_PATH ]; then
    echo "ERROR: P4 program $P4_PATH doesn't exist or is not readable"
    usage
    exit 1
fi

P4_REALPATH=$(realpath $P4_PATH)

for args in $@
do
	if [[ "$args" == "--with-bmv2" ]] || [[ "$args" == "--with-tofino" ]] || [[ "$args" == "with-tofinobm" ]]
	then
		target_platform=$args	
		shift
	fi
done

check_environment
build_case $*
