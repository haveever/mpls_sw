/*
Copyright 2013-present Barefoot Networks, Inc. 

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

// Template headers.p4 file for basic_switching
// Edit this file as needed for your P4 program

// Here's an ethernet header to get started.

header_type ethernet_t {
    fields {
        dstAddr : 48;
        srcAddr : 48;
        etherType : 16;
    }
}


header_type mpls_t {
	fields {
		label : 20;
		exp   : 3;
	    s     : 1;
	    ttl   : 8;
	}
}


header_type vlan_tag_t {
    fields {
        pcp : 3;
        cfi : 1;
        vid : 12;
        etherType : 16;
    }
}

header_type mpls_lookup_t{
	fields {
		n_mpls  : 12;
		inport  : 8;
		vlan_id : 12;
		vp_label: 20;
		vp_exp : 12;
		vc_label: 20;
		vc_exp  : 12;
	}
}

metadata mpls_lookup_t mpls_lookup_m;

header_type ipv4_t {
	fields {
		ver    : 4;
		hd_len : 4;
	    dsf    : 8;
	    total_len: 16;
		id     : 16;
		resv   : 1;
        dont_frag : 1;
		more_frag : 1;
		frag_off  : 13;
        ttl    : 8;
		protocol : 8;
		checksum:16;
		src_ip : 32;
	    dst_ip : 32;
	}
}

header ipv4_t ipv4;

header_type udp_t {
	fields {
		src_port : 16;
		dst_port : 16;
		udp_len : 16;
		check_sum : 16;
	}
}

header udp_t udp;

header_type tcp_t{
	fields {
		src_port : 16;
		dst_port : 16;
		seq      : 32;
		ack      : 32;
		hdr_len  : 8;
		flag_resv: 1;
		flag_enc : 1;
		flag_cwr : 1;
		flag_ur  : 1;
		flag_ack : 1;
		flag_push: 1;
		flag_reset: 1;
		flag_syn : 1;
		flag_fin : 1;
		win_size : 16;
		checksum : 16;
		ur_point : 16;
	}
}

header tcp_t tcp;

header_type flow_tuple_t{
	fields {
		src_ip : 32;
		dst_ip : 32;
		src_port : 16;
		dst_port : 16;
		protocol : 16;
	}
}

metadata flow_tuple_t flow_tuple_m;

