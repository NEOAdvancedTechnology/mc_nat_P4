mc_nat_P4
=====================

Multicast replication with Network Address Translation (NAT) in P4

This means that for every one packet that comes in that matches
an IP DST, the switch can output a cascade of packets with
different IP DSTs to various switch output ports.

Tables:
output_port - sets the output port of the first multicast NAT output packet

nat_table - sets the IP DST of new cloned packets as well as the
 destination port (of the next cloned packet)

Tested on bmv2 with target simple_switch

commands_mc_nat.txt: CLI commands to set up a simple set of multicast
replication with NAT
