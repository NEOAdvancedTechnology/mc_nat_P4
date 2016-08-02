// Multicast replication with network address translation (NAT)
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

header_type nat_t {
    fields {
	copyCount : 8;
    }
}

metadata nat_t nat_metadata { copyCount: 0;};

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

field_list md_fields{
      nat_metadata;
}


action do_nat(dst_ip) {
      modify_field(standard_metadata.egress_spec,1);
      modify_field(ipv4.dstAddr,dst_ip);
      add_to_field(nat_metadata.copyCount,1);
      clone_egress_pkt_to_egress(250,md_fields); 
}

action _drop() {
    drop();
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
}

control egress {
    apply(nat_table);
}
