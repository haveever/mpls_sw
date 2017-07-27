#include <tofino/intrinsic_metadata.p4>
#include <tofino/constants.p4>
#include "includes/headers.p4"
#include "includes/parser.p4"

action ler_ingress_match_a(vc_label, vc_exp, vp_label, vp_exp, outport)
{
	add_header(mpls[1]);
	add_header(mpls[0]);

	modify_field(mpls[1].label, vc_label);
	modify_field(mpls[1].exp, vc_exp);
	modify_field(mpls[0].label, vp_label);
	modify_field(mpls[0].exp, vp_exp);
	
	//TODO modify output port
	modify_field(ig_intr_md_for_tm.ucast_egress_port, outport);
}

table ler_ingress_table{
	reads{
		mpls_lookup_m.vlan_id : exact;
		mpls_lookup_m.inport  : exact;
	}
	actions{
		ler_ingress_match_a;
		nop;
	}
}

action ler_engress_match_a(outport)
{
	remove_header(mpls[0]);
	remove_header(mpls[1]);

	//TODO mody outprt
	modify_field(ig_intr_md_for_tm.ucast_egress_port, outport);
}

action nop()
{
	no_op();
}

table ler_engress_table{
	reads {
		mpls_lookup_m.vc_label : exact;
		mpls_lookup_m.vp_label : exact;
	}
	actions {
		ler_engress_match_a;
		nop;
	}
}

action lsr_swap_table_a(vp_label, vp_exp, outport)
{
	modify_field(mpls[0].label, vp_label);
	modify_field(mpls[0].exp, vp_exp);
	//TODO mdy outport
	modify_field(ig_intr_md_for_tm.ucast_egress_port, outport);
}

table lsr_swap_table{
	reads {
		mpls_lookup_m.vp_label : exact;
	}
	actions {
		lsr_swap_table_a;
		nop;
	}
		
}

control ingress{

	apply(ler_ingress_table);
	apply(lsr_swap_table);

	apply(ler_engress_table);

}

control egress{

}
