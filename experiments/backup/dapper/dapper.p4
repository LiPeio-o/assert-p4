#include <core.p4>
#include <v1model.p4>

struct intrinsic_metadata_t {
    bit<48> ingress_global_timestamp;
    bit<32> lf_field_list;
    bit<16> mcast_grp;
    bit<16> egress_rid;
}

struct my_metadata_t {
    bit<8> parse_tcp_options_counter;
}

struct routing_metadata_t {
    bit<32> nhop_ipv4;
}

struct stats_metadata_t {
    bit<32> dummy;
    bit<32> dummy2;
    bit<2>  flow_map_index;
    bit<32> senderIP;
    bit<32> seqNo;
    bit<32> ackNo;
    bit<32> sample_rtt_seq;
    bit<32> rtt_samples;
    bit<32> mincwnd;
    bit<32> dupack;
}

header ethernet_t {
    bit<48> dstAddr;
    bit<48> srcAddr;
    bit<16> etherType;
}

header ipv4_t {
    bit<4>  version;
    bit<4>  ihl;
    bit<8>  diffserv;
    bit<16> totalLen;
    bit<16> identification;
    bit<3>  flags;
    bit<13> fragOffset;
    bit<8>  ttl;
    bit<8>  protocol;
    bit<16> hdrChecksum;
    bit<32> srcAddr;
    bit<32> dstAddr;
}

header options_end_t {
    bit<8> kind;
}

header options_mss_t {
    bit<8>  kind;
    bit<8>  len;
    bit<16> MSS;
}

header options_sack_t {
    bit<8> kind;
    bit<8> len;
}

header options_ts_t {
    bit<8>  kind;
    bit<8>  len;
    bit<64> ttee;
}

header options_wscale_t {
    bit<8> kind;
    bit<8> len;
    bit<8> wscale;
}

header tcp_t {
    bit<16> srcPort;
    bit<16> dstPort;
    bit<32> seqNo;
    bit<32> ackNo;
    bit<4>  dataOffset;
    bit<3>  res;
    bit<3>  ecn;
    bit<1>  urg;
    bit<1>  ack;
    bit<1>  push;
    bit<1>  rst;
    bit<1>  syn;
    bit<1>  fin;
    bit<16> window;
    bit<16> checksum;
    bit<16> urgentPtr;
}

header options_nop_t {
    bit<8> kind;
}

struct metadata {
    @name(".intrinsic_metadata") 
    intrinsic_metadata_t intrinsic_metadata;
    @name(".my_metadata") 
    my_metadata_t        my_metadata;
    @name(".routing_metadata") 
    routing_metadata_t   routing_metadata;
    @name(".stats_metadata") 
    stats_metadata_t     stats_metadata;
}

struct headers {
    @name(".ethernet") 
    ethernet_t       ethernet;
    @name(".ipv4") 
    ipv4_t           ipv4;
    @name(".options_end") 
    options_end_t    options_end;
    @name(".options_mss") 
    options_mss_t    options_mss;
    @name(".options_sack") 
    options_sack_t   options_sack;
    @name(".options_ts") 
    options_ts_t     options_ts;
    @name(".options_wscale") 
    options_wscale_t options_wscale;
    @name(".tcp") 
    tcp_t            tcp;
    @name(".options_nop") 
    options_nop_t[3] options_nop;
}

parser ParserImpl(packet_in packet, out headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".parse_end") state parse_end {
        packet.extract(hdr.options_end);
        meta.my_metadata.parse_tcp_options_counter = meta.my_metadata.parse_tcp_options_counter - 8w1;
        transition parse_tcp_options;
    }
    @name(".parse_ethernet") state parse_ethernet {
        packet.extract(hdr.ethernet);
        transition select(hdr.ethernet.etherType) {
            16w0x800: parse_ipv4;
            default: accept;
        }
    }
    @name(".parse_ipv4") state parse_ipv4 {
        packet.extract(hdr.ipv4);
        transition select(hdr.ipv4.protocol) {
            8w6: parse_tcp;
            default: accept;
        }
    }
    @name(".parse_mss") state parse_mss {
        packet.extract(hdr.options_mss);
        meta.my_metadata.parse_tcp_options_counter = meta.my_metadata.parse_tcp_options_counter - 8w4;
        transition parse_tcp_options;
    }
    @name(".parse_nop") state parse_nop {
        packet.extract(hdr.options_nop.next);
        meta.my_metadata.parse_tcp_options_counter = meta.my_metadata.parse_tcp_options_counter - 8w1;
        transition parse_tcp_options;
    }
    @name(".parse_sack") state parse_sack {
        packet.extract(hdr.options_sack);
        meta.my_metadata.parse_tcp_options_counter = meta.my_metadata.parse_tcp_options_counter - 8w2;
        transition parse_tcp_options;
    }
    @name(".parse_tcp") state parse_tcp {
        packet.extract(hdr.tcp);
        meta.my_metadata.parse_tcp_options_counter = (bit<8>)(hdr.tcp.dataOffset * 4w4 - 4w4);
        transition select(hdr.tcp.syn) {
            1w1: parse_tcp_options;
            default: accept;
        }
    }
    @name(".parse_tcp_options") state parse_tcp_options {
        transition select(meta.my_metadata.parse_tcp_options_counter, (packet.lookahead<bit<8>>())[7:0]) {
            (8w0x0 &&& 8w0xff, 8w0x0 &&& 8w0x0): accept;
            (8w0x0 &&& 8w0x0, 8w0x0 &&& 8w0xff): parse_end;
            (8w0x0 &&& 8w0x0, 8w0x1 &&& 8w0xff): parse_nop;
            (8w0x0 &&& 8w0x0, 8w0x2 &&& 8w0xff): parse_mss;
            (8w0x0 &&& 8w0x0, 8w0x3 &&& 8w0xff): parse_wscale;
            (8w0x0 &&& 8w0x0, 8w0x4 &&& 8w0xff): parse_sack;
            (8w0x0 &&& 8w0x0, 8w0x8 &&& 8w0xff): parse_ts;
        }
    }
    @name(".parse_ts") state parse_ts {
        packet.extract(hdr.options_ts);
        meta.my_metadata.parse_tcp_options_counter = meta.my_metadata.parse_tcp_options_counter - 8w10;
        transition parse_tcp_options;
    }
    @name(".parse_wscale") state parse_wscale {
        packet.extract(hdr.options_wscale);
        meta.my_metadata.parse_tcp_options_counter = meta.my_metadata.parse_tcp_options_counter - 8w3;
        transition parse_tcp_options;
    }
    @header_ordering("ethernet", "ipv4", "tcp", "options_mss", "options_sack", "options_ts", "options_nop", "options_wscale", "options_end") @name(".start") state start {
        transition parse_ethernet;
    }
}

control egress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".rewrite_mac") action rewrite_mac(bit<48> smac) {
        hdr.ethernet.srcAddr = smac;
    }
    @name("._drop") action _drop() {
        mark_to_drop();
    }
    @name(".send_frame") table send_frame {
        actions = {
            rewrite_mac;
            _drop;
        }
        key = {
            standard_metadata.egress_port: exact;
        }
        size = 256;
    }
    apply {
        send_frame.apply();
    }
}

control ingress(inout headers hdr, inout metadata meta, inout standard_metadata_t standard_metadata) {
    @name(".MSS") register<bit<16>>(32w4) MSS;
    @name(".ack_time") register<bit<32>>(32w4) ack_time;
    @name(".app_reaction_time") register<bit<32>>(32w4) app_reaction_time;
    @name(".check_map") register<bit<2>>(32w2) check_map;
    @name(".dstIP") register<bit<32>>(32w4) dstIP;
    @name(".flight_size") register<bit<32>>(32w4) flight_size;
    @name(".flow_last_ack_rcvd") register<bit<32>>(32w4) flow_last_ack_rcvd;
    @name(".flow_last_seq_sent") register<bit<32>>(32w4) flow_last_seq_sent;
    @name(".flow_pkts_dup") register<bit<32>>(32w4) flow_pkts_dup;
    @name(".flow_pkts_rcvd") register<bit<32>>(32w4) flow_pkts_rcvd;
    @name(".flow_pkts_retx") register<bit<32>>(32w4) flow_pkts_retx;
    @name(".flow_pkts_sent") register<bit<32>>(32w4) flow_pkts_sent;
    @name(".flow_rtt_sample_seq") register<bit<32>>(32w4) flow_rtt_sample_seq;
    @name(".flow_rtt_sample_time") register<bit<32>>(32w4) flow_rtt_sample_time;
    @name(".flow_rwnd") register<bit<16>>(32w4) flow_rwnd;
    @name(".flow_srtt") register<bit<32>>(32w4) flow_srtt;
    @name(".metaIP") register<bit<32>>(32w4) metaIP;
    @name(".mincwnd") register<bit<32>>(32w4) mincwnd;
    @name(".rtt_samples") register<bit<32>>(32w4) rtt_samples;
    @name(".sendIP") register<bit<32>>(32w4) sendIP;
    @name(".srcIP") register<bit<32>>(32w4) srcIP;
    @name(".wscale") register<bit<8>>(32w4) wscale;
    @name(".save_source_IP") action save_source_IP() {
        srcIP.write((bit<32>)meta.stats_metadata.flow_map_index, (bit<32>)hdr.ipv4.srcAddr);
        dstIP.write((bit<32>)meta.stats_metadata.flow_map_index, (bit<32>)hdr.ipv4.dstAddr);
        metaIP.write((bit<32>)meta.stats_metadata.flow_map_index, (bit<32>)meta.stats_metadata.senderIP);
    }
    @name(".get_sender_IP") action get_sender_IP() {
	@assert("if(hdr.tcp.ack, traverse)"){}
        sendIP.read(meta.stats_metadata.senderIP, (bit<32>)meta.stats_metadata.flow_map_index);
        flow_last_seq_sent.read(meta.stats_metadata.seqNo, (bit<32>)meta.stats_metadata.flow_map_index);
        flow_last_ack_rcvd.read(meta.stats_metadata.ackNo, (bit<32>)meta.stats_metadata.flow_map_index);
        flow_rtt_sample_seq.read(meta.stats_metadata.sample_rtt_seq, (bit<32>)meta.stats_metadata.flow_map_index);
        rtt_samples.read(meta.stats_metadata.rtt_samples, (bit<32>)meta.stats_metadata.flow_map_index);
        mincwnd.read(meta.stats_metadata.mincwnd, (bit<32>)meta.stats_metadata.flow_map_index);
        flow_pkts_dup.read(meta.stats_metadata.dupack, (bit<32>)meta.stats_metadata.flow_map_index);
    }
    @name(".use_sample_rtt_first") action use_sample_rtt_first() {
        flow_rtt_sample_time.read(meta.stats_metadata.dummy, (bit<32>)meta.stats_metadata.flow_map_index);
        meta.stats_metadata.dummy2 = (bit<32>)meta.intrinsic_metadata.ingress_global_timestamp;
        meta.stats_metadata.dummy2 = meta.stats_metadata.dummy2 - meta.stats_metadata.dummy;
        flow_rtt_sample_seq.write((bit<32>)meta.stats_metadata.flow_map_index, (bit<32>)0);
        flow_srtt.write((bit<32>)meta.stats_metadata.flow_map_index, (bit<32>)meta.stats_metadata.dummy2);
        rtt_samples.write((bit<32>)meta.stats_metadata.flow_map_index, (bit<32>)1);
    }
    @name(".update_flow_dupack") action update_flow_dupack() {
        flow_pkts_dup.read(meta.stats_metadata.dummy, (bit<32>)meta.stats_metadata.flow_map_index);
        meta.stats_metadata.dummy = meta.stats_metadata.dummy + 32w1;
        flow_pkts_dup.write((bit<32>)meta.stats_metadata.flow_map_index, (bit<32>)meta.stats_metadata.dummy);
    }
    @name(".update_flow_rcvd") action update_flow_rcvd() {
        flow_pkts_rcvd.read(meta.stats_metadata.dummy, (bit<32>)meta.stats_metadata.flow_map_index);
        meta.stats_metadata.dummy = meta.stats_metadata.dummy + 32w1;
        flow_pkts_rcvd.write((bit<32>)meta.stats_metadata.flow_map_index, (bit<32>)meta.stats_metadata.dummy);
        flow_last_ack_rcvd.write((bit<32>)meta.stats_metadata.flow_map_index, (bit<32>)hdr.tcp.ackNo);
        flow_pkts_dup.write((bit<32>)meta.stats_metadata.flow_map_index, (bit<32>)0);
        flow_rwnd.write((bit<32>)meta.stats_metadata.flow_map_index, (bit<16>)hdr.tcp.window);
        ack_time.write((bit<32>)meta.stats_metadata.flow_map_index, (bit<32>)meta.intrinsic_metadata.ingress_global_timestamp);
    }
    @name(".update_flow_retx_3dupack") action update_flow_retx_3dupack() {
	@assert("if(meta.stats_metadata.dupack < 3, !traverse)"){}
        flow_pkts_retx.read(meta.stats_metadata.dummy, (bit<32>)meta.stats_metadata.flow_map_index);
        meta.stats_metadata.dummy = meta.stats_metadata.dummy + 32w1;
        flow_pkts_retx.write((bit<32>)meta.stats_metadata.flow_map_index, (bit<32>)meta.stats_metadata.dummy);
        flow_rtt_sample_seq.write((bit<32>)meta.stats_metadata.flow_map_index, (bit<32>)0);
        flow_rtt_sample_time.write((bit<32>)meta.stats_metadata.flow_map_index, (bit<32>)0);
        mincwnd.read(meta.stats_metadata.dummy, (bit<32>)meta.stats_metadata.flow_map_index);
        meta.stats_metadata.dummy = meta.stats_metadata.dummy >> 1;
        mincwnd.write((bit<32>)meta.stats_metadata.flow_map_index, (bit<32>)meta.stats_metadata.dummy);
    }
    @name(".update_flow_retx_timeout") action update_flow_retx_timeout() {
        flow_pkts_retx.read(meta.stats_metadata.dummy, (bit<32>)meta.stats_metadata.flow_map_index);
        meta.stats_metadata.dummy = meta.stats_metadata.dummy + 32w1;
        flow_pkts_retx.write((bit<32>)meta.stats_metadata.flow_map_index, (bit<32>)meta.stats_metadata.dummy);
        flow_rtt_sample_seq.write((bit<32>)meta.stats_metadata.flow_map_index, (bit<32>)0);
        flow_rtt_sample_time.write((bit<32>)meta.stats_metadata.flow_map_index, (bit<32>)0);
        mincwnd.write((bit<32>)meta.stats_metadata.flow_map_index, (bit<32>)14600);
    }
    @name(".update_flow_sent") action update_flow_sent() {
        flow_pkts_sent.read(meta.stats_metadata.dummy, (bit<32>)meta.stats_metadata.flow_map_index);
        meta.stats_metadata.dummy = meta.stats_metadata.dummy + 32w1;
        flow_pkts_sent.write((bit<32>)meta.stats_metadata.flow_map_index, (bit<32>)meta.stats_metadata.dummy);
        flow_last_seq_sent.write((bit<32>)meta.stats_metadata.flow_map_index, (bit<32>)hdr.tcp.seqNo);
        meta.stats_metadata.dummy = (bit<32>)meta.intrinsic_metadata.ingress_global_timestamp;
        ack_time.read(meta.stats_metadata.dummy2, (bit<32>)meta.stats_metadata.flow_map_index);
        meta.stats_metadata.dummy = meta.stats_metadata.dummy - meta.stats_metadata.dummy2;
        app_reaction_time.write((bit<32>)meta.stats_metadata.flow_map_index, (bit<32>)meta.stats_metadata.dummy);
        flow_last_seq_sent.read(meta.stats_metadata.dummy, (bit<32>)meta.stats_metadata.flow_map_index);
        flow_last_ack_rcvd.read(meta.stats_metadata.dummy2, (bit<32>)meta.stats_metadata.flow_map_index);
        meta.stats_metadata.dummy = meta.stats_metadata.dummy - meta.stats_metadata.dummy2;
        flight_size.write((bit<32>)meta.stats_metadata.flow_map_index, (bit<32>)meta.stats_metadata.dummy);
    }
    @name(".set_dmac") action set_dmac(bit<48> dmac) {
        hdr.ethernet.dstAddr = dmac;
    }
    @name("._drop") action _drop() {
        mark_to_drop();
    }
    @name(".increase_mincwnd") action increase_mincwnd() {
        mincwnd.write((bit<32>)meta.stats_metadata.flow_map_index, (bit<32>)meta.stats_metadata.dummy);
    }
    @name(".record_IP") action record_IP() {
        sendIP.write((bit<32>)meta.stats_metadata.flow_map_index, (bit<32>)hdr.ipv4.dstAddr);
        sendIP.read(meta.stats_metadata.senderIP, (bit<32>)meta.stats_metadata.flow_map_index);
        MSS.write((bit<32>)meta.stats_metadata.flow_map_index, (bit<16>)hdr.options_mss.MSS);
        wscale.write((bit<32>)meta.stats_metadata.flow_map_index, (bit<8>)hdr.options_wscale.wscale);
        mincwnd.write((bit<32>)meta.stats_metadata.flow_map_index, (bit<32>)14600);
    }
    @name(".set_nhop") action set_nhop(bit<32> nhop_ipv4, bit<9> port) {
        meta.routing_metadata.nhop_ipv4 = nhop_ipv4;
        standard_metadata.egress_spec = port;
        hdr.ipv4.ttl = hdr.ipv4.ttl + 8w255;
    }
    @name(".lookup_flow_map") action lookup_flow_map() {
        hash(meta.stats_metadata.flow_map_index, HashAlgorithm.crc32, (bit<2>)0, { hdr.ipv4.srcAddr, hdr.ipv4.dstAddr, hdr.ipv4.protocol, hdr.tcp.srcPort, hdr.tcp.dstPort }, (bit<4>)2);
        check_map.write((bit<32>)0, (bit<2>)meta.stats_metadata.flow_map_index);
    }
    @name(".lookup_flow_map_reverse") action lookup_flow_map_reverse() {
        hash(meta.stats_metadata.flow_map_index, HashAlgorithm.crc32, (bit<2>)0, { hdr.ipv4.dstAddr, hdr.ipv4.srcAddr, hdr.ipv4.protocol, hdr.tcp.dstPort, hdr.tcp.srcPort }, (bit<4>)2);
        check_map.write((bit<32>)1, (bit<2>)meta.stats_metadata.flow_map_index);
    }
    @name(".use_sample_rtt") action use_sample_rtt() {
        flow_rtt_sample_time.read(meta.stats_metadata.dummy, (bit<32>)meta.stats_metadata.flow_map_index);
        meta.stats_metadata.dummy2 = (bit<32>)meta.intrinsic_metadata.ingress_global_timestamp;
        meta.stats_metadata.dummy2 = meta.stats_metadata.dummy2 - meta.stats_metadata.dummy;
        flow_rtt_sample_seq.write((bit<32>)meta.stats_metadata.flow_map_index, (bit<32>)0);
        flow_srtt.read(meta.stats_metadata.dummy, (bit<32>)meta.stats_metadata.flow_map_index);
        meta.stats_metadata.dummy = 32w7 * meta.stats_metadata.dummy + meta.stats_metadata.dummy2;
        meta.stats_metadata.dummy = meta.stats_metadata.dummy >> 3;
        flow_srtt.write((bit<32>)meta.stats_metadata.flow_map_index, (bit<32>)meta.stats_metadata.dummy);
        rtt_samples.read(meta.stats_metadata.dummy, (bit<32>)meta.stats_metadata.flow_map_index);
        meta.stats_metadata.dummy = meta.stats_metadata.dummy + 32w1;
        rtt_samples.write((bit<32>)meta.stats_metadata.flow_map_index, (bit<32>)meta.stats_metadata.dummy);
    }
    @name(".sample_new_rtt") action sample_new_rtt() {
        flow_rtt_sample_seq.write((bit<32>)meta.stats_metadata.flow_map_index, (bit<32>)hdr.tcp.seqNo);
        flow_rtt_sample_time.write((bit<32>)meta.stats_metadata.flow_map_index, (bit<32>)meta.intrinsic_metadata.ingress_global_timestamp);
    }
    @name(".debug") table debug {
        actions = {
            save_source_IP;
        }
    }
    @name(".direction") table direction {
        actions = {
            get_sender_IP;
        }
    }
    @name(".first_rtt_sample") table first_rtt_sample {
        actions = {
            use_sample_rtt_first;
        }
    }
    @name(".flow_dupack") table flow_dupack {
        actions = {
            update_flow_dupack;
        }
    }
    @name(".flow_rcvd") table flow_rcvd {
        actions = {
            update_flow_rcvd;
        }
    }
    @name(".flow_retx_3dupack") table flow_retx_3dupack {
        actions = {
            update_flow_retx_3dupack;
        }
    }
    @name(".flow_retx_timeout") table flow_retx_timeout {
        actions = {
            update_flow_retx_timeout;
        }
    }
    @name(".flow_sent") table flow_sent {
        actions = {
            update_flow_sent;
        }
    }
    @name(".forward") table forward {
        actions = {
            set_dmac;
            _drop;
        }
        key = {
            meta.routing_metadata.nhop_ipv4: exact;
        }
        size = 512;
    }
    @name(".increase_cwnd") table increase_cwnd {
        actions = {
            increase_mincwnd;
        }
    }
    @name(".init") table init {
        actions = {
            record_IP;
        }
    }
    @name(".ipv4_lpm") table ipv4_lpm {
        actions = {
            set_nhop;
            _drop;
        }
        key = {
            hdr.ipv4.dstAddr: lpm;
        }
        size = 1024;
    }
    @name(".lookup") table lookup {
        actions = {
            lookup_flow_map;
        }
    }
    @name(".lookup_reverse") table lookup_reverse {
        actions = {
            lookup_flow_map_reverse;
        }
    }
    @name(".sample_rtt_rcvd") table sample_rtt_rcvd {
        actions = {
            use_sample_rtt;
        }
    }
    @name(".sample_rtt_sent") table sample_rtt_sent {
        actions = {
            sample_new_rtt;
        }
    }
    apply {
	@assert("if(hdr.ipv4.ttl == 0, !forward)"){}

    @assert("constant(hdr.tcp.dstPort)"){}
    @assert("constant(hdr.tcp.seqNo)"){}
    @assert("constant(hdr.tcp.ackNo)"){}
    @assert("constant(hdr.tcp.dataOffset)"){}
    @assert("constant(hdr.tcp.res)"){}
    @assert("constant(hdr.tcp.ecn)"){}
    @assert("constant(hdr.tcp.urg)"){}
    @assert("constant(hdr.tcp.ack)"){}
    @assert("constant(hdr.tcp.push)"){}
    @assert("constant(hdr.tcp.rst)"){}
    @assert("constant(hdr.tcp.syn)"){}
    @assert("constant(hdr.tcp.fin)"){}
    @assert("constant(hdr.tcp.window)"){}
    @assert("constant(hdr.tcp.checksum)"){}
    @assert("constant(hdr.tcp.urgentPtr)"){}

        if (hdr.ipv4.protocol == 8w0x6) {
            if (hdr.ipv4.srcAddr > hdr.ipv4.dstAddr) {
                lookup.apply();
            }
            else {
                lookup_reverse.apply();
            }
            if (hdr.tcp.syn == 1w1 && hdr.tcp.ack == 1w0) {
                init.apply();
            }
            else {
                direction.apply();
            }
            if (hdr.ipv4.srcAddr == meta.stats_metadata.senderIP) {
                if (hdr.tcp.seqNo > meta.stats_metadata.seqNo) {
                    flow_sent.apply();
                    if (meta.stats_metadata.sample_rtt_seq == 32w0) {
                        sample_rtt_sent.apply();
                    }
                    if (meta.stats_metadata.dummy > meta.stats_metadata.mincwnd) {
                        increase_cwnd.apply();
                    }
                }
                else {
                    if (meta.stats_metadata.dupack == 32w3) {
                        flow_retx_3dupack.apply();
                    }
                    else {
                        flow_retx_timeout.apply();
                    }
                }
            }
            else {
                if (hdr.ipv4.dstAddr == meta.stats_metadata.senderIP) {
                    if (hdr.tcp.ackNo > meta.stats_metadata.ackNo) {
                        flow_rcvd.apply();
                        if (hdr.tcp.ackNo >= meta.stats_metadata.sample_rtt_seq && meta.stats_metadata.sample_rtt_seq > 32w0) {
                            if (meta.stats_metadata.rtt_samples == 32w0) {
                                first_rtt_sample.apply();
                            }
                            else {
                                sample_rtt_rcvd.apply();
                            }
                        }
                    }
                    else {
                        flow_dupack.apply();
                    }
                }
                else {
                    debug.apply();
                }
            }
        }
        ipv4_lpm.apply();
        forward.apply();
    }
}

control DeparserImpl(packet_out packet, in headers hdr) {
    apply {
        packet.emit(hdr.ethernet);
        packet.emit(hdr.ipv4);
        packet.emit(hdr.tcp);
        packet.emit(hdr.options_end);
        packet.emit(hdr.options_nop);
        packet.emit(hdr.options_mss);
        packet.emit(hdr.options_wscale);
        packet.emit(hdr.options_sack);
        packet.emit(hdr.options_ts);
    }
}

control verifyChecksum(inout headers hdr, inout metadata meta) {
    apply {
        verify_checksum(true, { hdr.ipv4.version, hdr.ipv4.ihl, hdr.ipv4.diffserv, hdr.ipv4.totalLen, hdr.ipv4.identification, hdr.ipv4.flags, hdr.ipv4.fragOffset, hdr.ipv4.ttl, hdr.ipv4.protocol, hdr.ipv4.srcAddr, hdr.ipv4.dstAddr }, hdr.ipv4.hdrChecksum, HashAlgorithm.csum16);
    }
}

control computeChecksum(inout headers hdr, inout metadata meta) {
    apply {
        update_checksum(true, { hdr.ipv4.version, hdr.ipv4.ihl, hdr.ipv4.diffserv, hdr.ipv4.totalLen, hdr.ipv4.identification, hdr.ipv4.flags, hdr.ipv4.fragOffset, hdr.ipv4.ttl, hdr.ipv4.protocol, hdr.ipv4.srcAddr, hdr.ipv4.dstAddr }, hdr.ipv4.hdrChecksum, HashAlgorithm.csum16);
    }
}

V1Switch(ParserImpl(), verifyChecksum(), ingress(), egress(), computeChecksum(), DeparserImpl()) main;
