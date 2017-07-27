PROJ_DIR=$PWD
PROJ_LIB_DIR=$PROJ_DIR/install/lib/tofinobmpd/l4_lb/
SDE_LIB_DIR=$SDE_INSTALL/lib/
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$SDE_LIB_DIR:$PROJ_LIB_DIR
echo $LD_LIBRARY_PATH
$PROJ_DIR/bmv2-tofino-demo/bmv2_tofino_demo --p4-name l4_lb --p4-prefix l4_lb
