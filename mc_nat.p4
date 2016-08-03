// mc_nat.p4
// performs "multicast NAT replication", i.e. for every one
// packet that comes in, several packets come out with
// different DST IPs and from different egress ports
//
// Author: Thomas Edwards (thomas.edwards@fox.com)
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

header_type ethernet_t {
    fields {
        dstAddr : 48;
        srcAddr : 48;
        etherType : 16;
    }
}

header_type ipv4_t {
    fields {
        version : 4;
        ihl : 4;
        diffserv : 8;
        totalLen : 16;
        identification : 16;
        flags : 3;
        fragOffset : 13;
        ttl : 8;
        protocol : 8;
        hdrChecksum : 16;
        srcAddr : 32;
        dstAddr : 32;
    }
}

// filler field because clone_egress_pkt_to_egress requires a field list in the bmv2
// simple_switch target despite being optional in the P4 Language Spec.
// 
field_list filler_field {
    standard_metadata;
}

parser start {
    return parse_ethernet;
}

header ethernet_t ethernet;

#define ETHERTYPE_IPV4 0x0800

parser parse_ethernet {
    extract(ethernet);
    return select(latest.etherType) {
        ETHERTYPE_IPV4 : parse_ipv4;
        default: ingress;
   }
}

header ipv4_t ipv4;

#define PROTOCOL_UDP 0x11

parser parse_ipv4 {
    extract(ipv4);
    return ingress;
}

action set_output_port(output_port) {
      modify_field(standard_metadata.egress_spec,output_port);
}

// Because egress_spec is "baked in" at buffering mechanism,
// the "output_port" parameter actually specifies the desired output
// port of the next packet cloned from the packet being
// currently acted upon.  A bit confusing
//
action do_nat(dst_ip,output_port) {
      modify_field(ipv4.dstAddr,dst_ip);
      clone_egress_pkt_to_egress(output_port,filler_field); 
}

action _drop() {
    drop();
}

// table used during ingress to set output port for first
// output packet (again because the egress_spec is "baked in"
// at the buffering mechanism between ingress and egress
// pipelines
//
table output_port {
    reads {
        ipv4.dstAddr: exact;
    }
    actions {
       	set_output_port; 
	_drop;
    }
    size : 16384;
}

table nat_table {
    reads {
	ipv4.dstAddr: exact;
    }
    actions {
        do_nat; 
        _drop;
    }
    size : 16384;
}

control ingress {
// needed for first output packet to come out of desired port
    apply(output_port);
}

control egress {
    apply(nat_table);
}
