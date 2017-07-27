#!/bin/bash
# Start running tofino-model program

function print_help() {
  echo "USAGE: $(basename ""$0"") -p <p4_program_name> [OPTIONS -- TOFINO_MODEL_OPTIONS]"
  echo "Options for running tofino-model:"
  echo "  -d NUM"
  echo "    Instantiate NUM devices in tofino-model"
  echo "  -h"
  echo "    Print this message"
  echo "  -g"
  echo "    Run with gdb"
  echo "  -f PORTINFO_FILE"
  echo "    Read port to veth mapping information from PORTINFO_FILE"
  echo "  -m"
  echo "    Run with port-monitor"
  echo "  --int-port-loop"
  echo "    Put all ports in internal loopback mode"
  echo "  --log-dir"
  echo "    Specify log file directory"
  exit 0
}

trap 'exit' ERR

[ -z ${SDE} ] && echo "Environment variable SDE not set" && exit 1
[ -z ${SDE_INSTALL} ] && echo "Environment variable SDE_INSTALL not set" && exit 1

echo "Using SDE ${SDE}"
echo "Using SDE_INSTALL ${SDE_INSTALL}"

opts=`getopt -o d:f:p:ghm --long int-port-loop,log-dir: -- "$@"`
if [ $? != 0 ]; then
  exit 1
fi
eval set -- "$opts"

# default P4_NAME to basic_ipv4
P4_NAME=""
# default num_devices to 1
NUM_DEVICES=1
# json file specifying of-port info
PORTINFO=None
# debug options
DBG=""
# internal port loop
INT_PORT_LOOP=""
LOG_DIR=""

HELP=false
PORTMONITOR=""
while true; do
    case "$1" in
      -d) NUM_DEVICES=$2; shift 2;;
      -f) PORTINFO=$2; shift 2;;
      -h) HELP=true; shift 1;;
      -g) DBG="gdb -ex run --args"; shift 1;;
      -m) PORTMONITOR="--port-monitor"; shift 1;;
      -p) P4_NAME=$2; shift 2;;
      --int-port-loop) INT_PORT_LOOP="$1"; shift 1;;
      --log-dir) LOG_DIR="--log-dir $2"; shift 2;;
      --) shift; break;;
    esac
done

if [ $HELP = true ] || [ -z $P4_NAME ]; then
  print_help
fi

PROJ_DIR=$PWD
PROJ_INSTALL=$PROJ_DIR/install/

LOG_JSON=$PROJ_INSTALL/share/tofinopd/${P4_NAME}/p4_name_lookup.json
[ ! -r $LOG_JSON ] && echo "File $LOG_JSON not found" && exit 1

export PATH=$SDE_INSTALL/bin:$PATH
export LD_LIBRARY_PATH=/usr/local/lib:$SDE_INSTALL/lib:$LD_LIBRARY_PATH

echo "Using PATH ${PATH}"
echo "Using LD_LIBRARY_PATH ${LD_LIBRARY_PATH}"

#Start tofino-model
sudo env "PATH=$PATH" "LD_LIBRARY_PATH=$LD_LIBRARY_PATH" $DBG tofino-model \
	-d $NUM_DEVICES \
	-l $SDE_INSTALL/share/tofinopd/${P4_NAME}/p4_name_lookup.json \
	-f $PORTINFO $PORTMONITOR $LOG_DIR $INT_PORT_LOOP $@

