#ifndef __PD_TEST_H__
#define __PD_TEST_H__
#define TOFINO_BM_PF

#ifdef TOFINO_BM_PF 
#include "tofinobmpd/l4_lb/pd/pd.h"
#include "tofinobmpd/l4_lb/pd/pd_counters.h"
#include "tofinobmpd/l4_lb/thrift-src/pd_rpc_server.h"
#include "tofinobm/pdfixed/pd_static.h"
#include "tofinobm/pdfixed/thrift-src/pdfixed_rpc_server.h"
#else
#include "bmpd/l4_lb/pd/pd.h"
#include "bmpd/l4_lb/pd/pd_counters.h"
#include "bmpd/l4_lb/thrift-src/pd_rpc_server.h"
#include "bm/pdfixed/pd_static.h"
#include "bm/pdfixed/thrift-src/pdfixed_rpc_server.h"
#endif 

#define INSTALL_DIR "/home/wunan/p4_proj/l4_lb/install"
#define BMV2_LIB_DIR INSTALL_DIR"/lib/bmpd/l4_lb"
#define TOFINOBMPD_LIB_DIR INSTALL_DIR"/lib/tofinobmpd/l4_lb"
#define TOFINOPD_LIB_DIR INSTALL_DIR"/lib/tofinopd/l4_lb"

#define DEV_ID 0
#define DEV_PIPE_ID 0xffff

#endif
