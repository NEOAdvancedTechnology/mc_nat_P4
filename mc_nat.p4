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


action do_nat(dst_ip,output_port) {
      modify_field(standard_metadata.egress_spec,1);
      modify_field(ipv4.dstAddr,dst_ip);
      add_to_field(nat_metadata.copyCount,1);
      clone_egress_pkt_to_egress(output_port,md_fields); 
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
