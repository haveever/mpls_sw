/*******************************************************************************
 * BAREFOOT NETWORKS CONFIDENTIAL & PROPRIETARY
 *
 * Copyright (c) 2015-2016 Barefoot Networks, Inc.

 * All Rights Reserved.
 *
 * NOTICE: All information contained herein is, and remains the property of
 * Barefoot Networks, Inc. and its suppliers, if any. The intellectual and
 * technical concepts contained herein are proprietary to Barefoot Networks,
 * Inc.
 * and its suppliers and may be covered by U.S. and Foreign Patents, patents in
 * process, and are protected by trade secret or copyright law.
 * Dissemination of this information or reproduction of this material is
 * strictly forbidden unless prior written permission is obtained from
 * Barefoot Networks, Inc.
 *
 * No warranty, explicit or implicit is provided, unless granted under a
 * written agreement with Barefoot Networks, Inc.
 *
 * $Id: $
 *
 ******************************************************************************/

#include <errno.h>
#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include <dlfcn.h>

#include <getopt.h>
#include <assert.h>

#include "pd_test.h"

char *pd_server_str = NULL;

/**
 * The maximum number of ports to support:
 * @fixme should be runtime parameter
 */
#define PORT_COUNT 256
#define PD_SERVER_DEFAULT_PORT 9090

p4_pd_sess_hdl_t sess_hdl;
p4_pd_dev_target_t dev_target;
/**
 * Check an operation and return if there's an error.
 */
#define CHECK(op)                                                             \
  do {                                                                        \
    int _rv;                                                                  \
    if ((_rv = (op)) < 0) {                                                   \
      fprintf(stderr, "%s: ERROR %d at %s:%d", #op, _rv, __FILE__, __LINE__); \
      return _rv;                                                             \
    }                                                                         \
  } while (0)

p4_pd_status_t flow_tuple_learn_cb(p4_pd_sess_hdl_t sess_hdl, p4_pd_l4_lb_flow_tuple_l_digest_msg_t* msg, void* cookie)
{
	printf("call back invoked\n");
	p4_pd_l4_lb_flow_tuple_l_digest_entry_t* entry = NULL;
	
	int i = 0 ;
	for (i = 0; (msg != NULL) && (i < msg->num_entries); ++i) {
		entry = msg->entries + i;
		printf("src_ip=%02x, dst_ip=%02x, src_port=%u, dst_port=%u, proto=%u\n", entry->flow_tuple_m_src_ip, entry->flow_tuple_m_dst_ip, entry->flow_tuple_m_src_port, entry->flow_tuple_m_dst_port, entry->flow_tuple_m_protocol);
	}
	p4_pd_l4_lb_flow_tuple_l_notify_ack(sess_hdl, msg);
	return 0;
}

int bmv2_model_init(char *p4_name,
                    char *p4_prefix,
                    bool with_switchsai,
                    bool with_switchlink) {
  int rv = 0;
  char *error = NULL;
  void *pd_server_cookie;
  static void *pd_lib_hdl = NULL;
  static void *pd_thrift_lib_hdl = NULL;
  char pd_init_fn_name[80];
  char pd_assign_device_fn_name[80];
  char pd_thrift_add_to_rpc_fn_name[80];
  int (*pd_init_fn)(void);
  int (*pd_assign_device_fn)(
      int dev_id, const char *notif_addr, int rpc_port_num);
  int (*add_to_rpc_fn)(void *);
  typedef void *pvoid_dl_t __attribute__((__may_alias__));
  char libpd_name[256] = {0};
  char libpdthrift_name[256] = {0};

  snprintf(libpd_name, 256, "%s/libpd.so", TOFINOBMPD_LIB_DIR);

  printf("%s: Loading %s for %s \n", __func__, libpd_name, p4_name);
  pd_lib_hdl = dlopen(libpd_name , RTLD_LAZY | RTLD_GLOBAL);
  if(pd_lib_hdl == NULL){
	printf("error %s\n", dlerror());
  }

  if ((error = dlerror()) != NULL) {
    printf("%s: %d: Error in dlopen, err=%s ", __func__, __LINE__, error);
    return -1;
  }


  snprintf(libpdthrift_name, 256, "%s/libpdthrift.so", TOFINOBMPD_LIB_DIR);

  printf("%s: Loading %s for %s \n", __func__, libpdthrift_name, p4_name);
  pd_thrift_lib_hdl = dlopen(libpdthrift_name, RTLD_LAZY | RTLD_GLOBAL);
  if(pd_thrift_lib_hdl == NULL){
	printf("error %s\n", dlerror());
  }
  if ((error = dlerror()) != NULL) {
    printf("%s: %d: Error in dlopen, err=%s ", __func__, __LINE__, error);
    return -1;
  }

  /* Retreive pd initialization functions */
  sprintf(pd_init_fn_name, "p4_pd_%s_init", p4_prefix);
  *(pvoid_dl_t *)(&pd_init_fn) = dlsym(pd_lib_hdl, pd_init_fn_name);
  if(pd_init_fn == NULL)
  {
	  printf("error %s\n", dlerror());
  }
  if ((error = dlerror()) != NULL) {
    printf("%s: %d: Error in looking up pd_init func, err=%s ",
           __func__,
           __LINE__,
           error);
    return -1;
  }

  sprintf(pd_assign_device_fn_name, "p4_pd_%s_assign_device", p4_prefix);
  *(pvoid_dl_t *)(&pd_assign_device_fn) =
      dlsym(pd_lib_hdl, pd_assign_device_fn_name);
  if(pd_assign_device_fn == NULL)
  {
	  printf("error %s\n", dlerror());
  }
  if ((error = dlerror()) != NULL) {
    printf("%s: %d: Error in looking up pd_assign_device func, err=%s ",
           __func__,
           __LINE__,
           error);
    return -1;
  }

  /* Retreive pdthrift initialization function */
  sprintf(pd_thrift_add_to_rpc_fn_name, "add_to_rpc_server");
  *(pvoid_dl_t *)(&add_to_rpc_fn) =
      dlsym(pd_thrift_lib_hdl, pd_thrift_add_to_rpc_fn_name);
  if(pd_thrift_lib_hdl == NULL)
  {
	  printf("error %s\n", dlerror());
  }
  if ((error = dlerror()) != NULL) {
    printf("%s: %d: Error in looking up add_to_rpc func, err=%s ",
           __func__,
           __LINE__,
           error);
    return -1;
  }

  /* Start the thrift RPC server */
  start_bfn_pd_rpc_server(&pd_server_cookie);
  /* Add PD thrift service to the RPC server */
  add_to_rpc_fn(pd_server_cookie);

  /* Initialize the PD fixed library */
  p4_pd_init();
  /* Initialize the PD library */
  pd_init_fn();
  /* Instantiate the bmv2 device */
  pd_assign_device_fn(0, "ipc:///tmp/bmv2-0-notifications.ipc", 10001);



  memset(&sess_hdl, 0, sizeof(p4_pd_sess_hdl_t));
  dev_target.device_id = DEV_ID;
  dev_target.dev_pipe_id = DEV_PIPE_ID;

  p4_pd_client_init(&sess_hdl);

  p4_pd_status_t ret_status;
  ret_status = p4_pd_l4_lb_set_learning_timeout(sess_hdl, DEV_ID, 4);
  if(ret_status)
  {
	  printf("timeout status = %d\n", ret_status);
	  return -1;
  }

  ret_status = p4_pd_l4_lb_flow_tuple_l_register(sess_hdl, DEV_ID, flow_tuple_learn_cb, NULL);
  if(ret_status)
  {
	  printf("reg status = %d\n", ret_status);
	  return -1;
  }
  printf("reg ok\n");

  return rv;
}
