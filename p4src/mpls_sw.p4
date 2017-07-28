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

table check_vlan_table{
	reads {
		vlan[0] : valid;
	}
	actions {
		check_vlan_match_a;
		nop;
	}
}

action check_mpls_table_a()
{
	modify_field(mpls_lookup_m.vc_label, mpls[1].label);
	modify_field(mpls_lookup_m.vc_exp, mpls[1].exp);
	modify_field(mpls_lookup_m.vp_label, mpls[0].label);
	modify_field(mpls_lookup_m.vp_label, mpls[0].exp);
}

table check_mpls_table{
	reads{
		mpls[0] : valid;
		mpls[1] : valid;
	}
	actions{
		check_mpls_table_a;
		nop;
	}
}

action ler_ingress_match_a()
{
	add_header(mpls[1]);
	add_header(mpls[0]);
}

table ler_ingress_table{
	reads{
		mpls_lookup_m.vlan_id   : exact;
     	mpls_lookup_m.inport : exact;
	}
	actions{
		ler_ingress_match_a;
		nop;
	}
}

control ingress{
	apply(check_vlan_table)
	{
		hit
		{
			apply(ler_ingress_table);
		}
		miss
		{
			apply(check_mpls_table)
			{
				hit{
					//TODO check lrs table
					
				}
			}
		}
	}

	//apply(ler_ingress_table);

}

control egress{

}
