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

// Template parser.p4 file for basic_switching
// Edit this file as needed for your P4 program

// This parses an ethernet header

parser start {
    return parse_ethernet;
}


header ethernet_t ethernet;

parser parse_ethernet {
    extract(ethernet);
    return select(latest.etherType) {
        ETHERTYPE_VLAN : parse_vlan;
		ETHERTYPE_MPLS : parse_mpls;
        default: ingress;
    }
}

#define MPLS_BOS current(23,1)

#define MPLS_DEPTH 4 

header mpls_t mpls[MPLS_DEPTH];

parser parse_mpls {
	extract(mpls[next]);
	return select(latest.s) {
		0 : parse_mpls;
	    1 : ingress;
		default : ingress;
	}
}

#define VLAN_DEPTH 2
header vlan_tag_t vlan[VLAN_DEPTH];

parser parse_vlan {
    extract(vlan[next]);
	return select(latest.etherType){
        ETHERTYPE_VLAN : parse_vlan;
        ETHERTYPE_MPLS : parse_mpls;
        default: ingress;
	}
}
