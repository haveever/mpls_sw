#!/bin/bash
# Start running bmv2 or tofinobm model

function print_help() {
  echo "USAGE: $(basename ""$0"") -p <P4_NAME> [OPTIONS -- BMV2_OPTIONS]"
  echo "Options for running bmv2 and tofinobm model:"
  echo "  -p <p4_program_name>"
  echo "    Program name"
  echo "  --arch <ARCHITECTURE>"
  echo "    Architecture (Tofino or SimpleSwitch)"
  echo "  -f PORTINFO_FILE"
  echo "    Read port to veth mapping information from PORTINFO_FILE"
  echo "  -g"
  echo "    Run with gdb"
  echo "  -h"
  echo "    Print this message"
  echo "  -i IF_PREFIX"
  echo "    Use port to interface mapping for sw"
  exit 0
}

trap 'exit' ERR

[ -z ${SDE_INSTALL} ] && echo "Environment variable SDE_INSTALL not set" && exit 1

echo "Using SDE_INSTALL ${SDE_INSTALL}"

PROJ_DIR=$PWD
PROJ_INSTALL=$PROJ_DIR/install/

opts=`getopt -o p:f:i:gh --long arch: -- "$@"`
if [ $? != 0 ]; then
  exit 1
fi
eval set -- "$opts"

P4_NAME=""
DBG=""
PORTINFO=None
ARCH="SimpleSwitch"
USEINTF=false
IF_PREFIX=""

HELP=false
while true; do
    case "$1" in
      -h) HELP=true; shift 1;;
      -g) DBG="gdb -ex run --args"; shift 1;;
      -p) P4_NAME=$2; shift 2;;
      -f) PORTINFO=$2; shift 2;;
      -i) IF_PREFIX=$2; USEINTF=true; shift 2;;
      --arch) ARCH=$2; shift 2;;
      --) shift; break;;
    esac
done

if [ $HELP = true ] || [ -z $P4_NAME ]; then
  print_help
fi
echo "Using Port-info file ${PORTINFO}"
echo "Arch is $ARCH"

if [[ "$ARCH" == "Tofino" ]]; then
    JSON_FILE=$PROJ_INSTALL/share/tofinobmpd/${P4_NAME}/${P4_NAME}.json
    BMV2_BINARY_PATH=tofinobmv2
else
    JSON_FILE=$PROJ_INSTALL/share/bmpd/${P4_NAME}/${P4_NAME}.json
    BMV2_BINARY_PATH=simple_switch
fi
if [ ! -f $JSON_FILE ]; then
    echo "json file $JSON_FILE not found for p4-program ${P4_NAME}; did you run 'make'?"
    exit 1
fi
echo "Using Json file ${JSON_FILE}"

export PATH=$SDE_INSTALL/bin:$PATH
export LD_LIBRARY_PATH=/usr/local/lib:$SDE_INSTALL/lib:$LD_LIBRARY_PATH

echo "Using PATH ${PATH}"
echo "Using LD_LIBRARY_PATH ${LD_LIBRARY_PATH}"

if [ x@BMV2_BINARY_PATH@ = x ]; then
    echo "$BMV2_BINARY_PATH executable not found by latest configure run"
    echo "have you installed $BMV2_BINARY_PATH since? if yes, you need to run configure again"
    exit 1
fi
echo "Running $BMV2_BINARY_PATH"

if [[ "$ARCH" == "Tofino" ]] && [ -f $PORTINFO ]; then
    INTERFACES=$(python $SDE_INSTALL/lib/python2.7/site-packages/bmv2utils/bmv2_model_interfaces.py --port-info $PORTINFO)
else
    if [[ $USEINTF == true ]] && [[ $IF_PREFIX != "" ]]; then
        INTERFACES="-i 0@${IF_PREFIX}-eth1 -i 1@${IF_PREFIX}-eth2 -i \
                    2@${IF_PREFIX}-eth3 -i 3@${IF_PREFIX}-eth4 -i 4@${IF_PREFIX}-eth5 \
                    -i 5@${IF_PREFIX}-eth6 -i 6@${IF_PREFIX}-eth7 -i \
                    7@${IF_PREFIX}-eth8 -i 8@${IF_PREFIX}-eth9 -i 64@veth250"
    else
        INTERFACES="-i 0@veth0 -i 1@veth2 -i 2@veth4 -i 3@veth6 -i 4@veth8 -i \
                    5@veth10 -i 6@veth12 -i 7@veth14 -i 8@veth16 -i 64@veth250"
    fi
fi
echo "Using INTERFACES ${INTERFACES}"

sudo env "PATH=$PATH" "LD_LIBRARY_PATH=$LD_LIBRARY_PATH" $DBG $BMV2_BINARY_PATH --log-console $INTERFACES --thrift-port 10001 --pcap $JSON_FILE $@
