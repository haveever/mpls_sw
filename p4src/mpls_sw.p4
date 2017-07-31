#include <tofino/intrinsic_metadata.p4>
#include <tofino/constants.p4>
#include "includes/headers.p4"
#include "includes/parser.p4"

action nop()
{
	no_op();
}

action check_vlan_match_a(){
	modify_field(mpls_lookup_m.vlan_id, vlan[0].vid);
	modify_field(mpls_lookup_m.inport,ig_intr_md.ingress_port);
}

counter vlan_valid_c{
	type : packets;
	direct : check_vlan_table;
}

table check_vlan_table{
	reads {
		vlan[0] : valid;
		mpls[0] : valid;
		mpls[1] : valid;
	}
	actions {
		check_vlan_match_a;
		check_mpls_match_a;
		nop;
	}
}

action check_mpls_match_a()
{
	modify_field(mpls_lookup_m.vc_label, mpls[1].label);
	modify_field(mpls_lookup_m.vc_exp, mpls[1].exp);
	modify_field(mpls_lookup_m.vp_label, mpls[0].label);
	modify_field(mpls_lookup_m.vp_label, mpls[0].exp);
}

action ler_ingress_match_a(vc_label, vc_exp, vp_label, vp_exp, outport)
{
	modify_field(vlan[0].etherType, ETHERTYPE_MPLS);

	add_header(mpls[0]);
	modify_field(mpls[0].label, vp_label);
	modify_field(mpls[0].exp, vp_exp);
	modify_field(mpls[0].ttl, MPLS_TTL_DEFAULT);

	add_header(mpls[1]);
	modify_field(mpls[1].label, vc_label);
	modify_field(mpls[1].exp, vc_exp);
	modify_field(mpls[1].ttl, MPLS_TTL_DEFAULT);
	modify_field(mpls[1].s, 1);

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

action lsr_mpls_swap_a(swap_vp_label, swap_vp_exp, outport)
{
	modify_field(mpls[0].label, swap_vp_label);	
	modify_field(mpls[0].exp, swap_vp_exp);
	
	modify_field(ig_intr_md_for_tm.ucast_egress_port, outport);
}

table lsr_swap_table{
	reads {
		mpls[0].label : exact;
	}
	actions {
		lsr_mpls_swap_a;
		nop;
	}
}

action ler_mpls_match_a(outport){

	remove_header(mpls[1]);
	remove_header(mpls[0]);

	modify_field(vlan[0].etherType, ETHERTYPE_IPV4);
	modify_field(ig_intr_md_for_tm.ucast_egress_port, outport);
	
}

table ler_egress_table{
	reads {
		mpls[0].label : exact;
		mpls[1].label : exact;
	}
	actions {
		ler_mpls_match_a;
		nop;
	}
}

control ingress{
	apply(check_vlan_table)
	{
		check_vlan_match_a
		{
			apply(ler_ingress_table);
		}
		check_mpls_match_a	
		{
			apply(lsr_swap_table)
			{
				hit{
					
				}
				miss{
					apply(ler_egress_table);	
				}
			}
		}
		default
		{
		}
	}


}

control egress{

}
