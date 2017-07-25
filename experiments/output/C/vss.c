#include<stdio.h>
#include<stdint.h>
<Type_Error>16
<Type_Method>95
<Declaration_MatchKind>106
typedef uint8_t PortId;

typedef struct {
	PortId inputPort;
} InControl;

typedef struct {
	PortId outputPort;
} OutControl;

<Type_Parser>161
<Type_Control>179
<Type_Control>191
typedef uint64_t EthernetAddress;

typedef uint32_t IPv4Address;

typedef struct {
	uint8_t isValid : 1;
	EthernetAddress dstAddr: 48;
	EthernetAddress srcAddr: 48;
	uint32_t etherType : 16;
} Ethernet_h;

typedef struct {
	uint8_t isValid : 1;
	uint8_t version : 4;
	uint8_t ihl : 4;
	uint8_t diffserv : 8;
	uint32_t totalLen : 16;
	uint32_t identification : 16;
	uint8_t flags : 3;
	uint32_t fragOffset : 13;
	uint8_t ttl : 8;
	uint8_t protocol : 8;
	uint32_t hdrChecksum : 16;
	IPv4Address srcAddr: 32;
	IPv4Address dstAddr: 32;
} Ipv4_h;

typedef struct {
	Ethernet_h ethernet;
	Ipv4_h ip;
} Parsed_packet;

Parsed_packet p;

uint8_t tmp_10;
uint8_t tmp_11;
uint32_t tmp_12;
uint8_t tmp_13;
uint8_t tmp_14;


void start() {
	p.ethernet.isValid = 1;
	switch(p.ethernet.etherType){
		case 2048:	parse_ipv4(); break;
	}
}


void parse_ipv4() {
	p.ip.isValid = 1;
	tmp_10 = (p.ip.version == 4);
	if(tmp_10 == 0) { printf("IPv4IncorrectVersion"); exit(1); }
	tmp_11 = (p.ip.ihl == 5);
	if(tmp_11 == 0) { printf("IPv4OptionsNotSupported"); exit(1); }
	//Extern: ck.clear
	//Extern: ck.update
		klee_make_symbolic(&tmp_12, sizeof(tmp_12), "tmp_12");

	tmp_13 = (tmp_12 == 0);
	tmp_14 = tmp_13;
	if(tmp_14 == 0) { printf("IPv4ChecksumError"); exit(1); }
	accept();
}


void accept() {
	
}


void reject() {
	printf("Packet dropped");
	exit(0);
}


void TopParser() {
	klee_make_symbolic(&p, sizeof(p), "p");

	start();
}

//Control
IPv4Address nextHop_1;
uint8_t tmp_15;
uint8_t tmp_16;
uint8_t tmp_17;
uint8_t tmp_18;
uint8_t tmp_19;
IPv4Address nextHop_2;
IPv4Address nextHop_3;
uint8_t hasReturned_0;
IPv4Address nextHop_0;

void TopPipe() {
	tbl_act_101773();
	if(tmp_16) {
		tbl_Drop_action_101809();
	tbl_act_0_101840();

}
	if(!hasReturned_0) {
		ipv4_match_92978();
	tbl_act_1_101900();
	if(tmp_17) {
	tbl_act_2_101934();
}

}
	if(!hasReturned_0) {
		check_ttl_93039();
	tbl_act_3_101994();
	if(tmp_18) {
	tbl_act_4_102028();
}

}
	if(!hasReturned_0) {
		tbl_act_5_102065();
	dmac_1_93101();
	tbl_act_6_102119();
	if(tmp_19) {
	tbl_act_7_102153();
}

}
	if(!hasReturned_0) {
	smac_1_93165();
}
}

// Action
void NoAction_0_92881() {
	action_run = 92881;
	
}


// Action
void Drop_action_0_92891() {
	action_run = 92891;
		outCtrl.outputPort = 15;

}


// Action
void Drop_action_4_92906() {
	action_run = 92906;
		outCtrl.outputPort = 15;

}


// Action
void Drop_action_5_92913() {
	action_run = 92913;
		outCtrl.outputPort = 15;

}


// Action
void Drop_action_6_92920() {
	action_run = 92920;
		outCtrl.outputPort = 15;

}


// Action
void Set_nhop_0_94278() {
	action_run = 94278;
	IPv4Address ipv4_dest;
	klee_make_symbolic(&ipv4_dest, sizeof(ipv4_dest), "ipv4_dest");
PortId port;
	klee_make_symbolic(&port, sizeof(port), "port");
	nextHop_0 = ipv4_dest;
	tmp_15 = headers.ip.ttl + 255;
	headers.ip.ttl = headers.ip.ttl + 255;
	outCtrl.outputPort = port;
	nextHop_2 = ipv4_dest;

}


// Action
void Send_to_cpu_0_93024() {
	action_run = 93024;
		outCtrl.outputPort = 14;

}


// Action
void Set_dmac_0_93081() {
	action_run = 93081;
	EthernetAddress dmac;
	klee_make_symbolic(&dmac, sizeof(dmac), "dmac");
	headers.ethernet.dstAddr = dmac;

}


// Action
void Set_smac_0_93145() {
	action_run = 93145;
	EthernetAddress smac;
	klee_make_symbolic(&smac, sizeof(smac), "smac");
	headers.ethernet.srcAddr = smac;

}


// Action
void act_99936() {
	action_run = 99936;
		hasReturned_0 = 1;

}


// Action
void act_0_99948() {
	action_run = 99948;
		hasReturned_0 = 0;
	tmp_16 = (parseError != <TypeNameExpression>93223.NoError);

}


// Action
void act_1_99987() {
	action_run = 99987;
		hasReturned_0 = 1;

}


// Action
void act_2_100003() {
	action_run = 100003;
		nextHop_1 = nextHop_2;
	tmp_17 = (outCtrl.outputPort == 15);

}


// Action
void act_3_100044() {
	action_run = 100044;
		hasReturned_0 = 1;

}


// Action
void act_4_100060() {
	action_run = 100060;
		tmp_18 = (outCtrl.outputPort == 14);

}


// Action
void act_5_100096() {
	action_run = 100096;
		nextHop_3 = nextHop_1;

}


// Action
void act_6_100112() {
	action_run = 100112;
		hasReturned_0 = 1;

}


// Action
void act_7_100128() {
	action_run = 100128;
		tmp_19 = (outCtrl.outputPort == 15);

}


//Table
void ipv4_match_92978() {
	int symbol;
	klee_make_symbolic(&symbol, sizeof(symbol), "symbol");
	switch(symbol) {
		case 0: Drop_action_0_92891(); break;
		default: Set_nhop_0_94278(); break;
	}
	// size 1024
	// default_action Drop_action_0();
}


//Table
void check_ttl_93039() {
	int symbol;
	klee_make_symbolic(&symbol, sizeof(symbol), "symbol");
	switch(symbol) {
		case 0: Send_to_cpu_0_93024(); break;
		default: NoAction_0_92881(); break;
	}
	// default_action NoAction_0();
}


//Table
void dmac_1_93101() {
	int symbol;
	klee_make_symbolic(&symbol, sizeof(symbol), "symbol");
	switch(symbol) {
		case 0: Drop_action_4_92906(); break;
		default: Set_dmac_0_93081(); break;
	}
	// size 1024
	// default_action Drop_action_4();
}


//Table
void smac_1_93165() {
	int symbol;
	klee_make_symbolic(&symbol, sizeof(symbol), "symbol");
	switch(symbol) {
		case 0: Drop_action_5_92913(); break;
		default: Set_smac_0_93145(); break;
	}
	// size 16
	// default_action Drop_action_5();
}


//Table
void tbl_act_101773() {
	int symbol;
	klee_make_symbolic(&symbol, sizeof(symbol), "symbol");
	switch(symbol) {
		default: act_0_99948(); break;
	}
	// default_action act_0();
}


//Table
void tbl_Drop_action_101809() {
	int symbol;
	klee_make_symbolic(&symbol, sizeof(symbol), "symbol");
	switch(symbol) {
		default: Drop_action_6_92920(); break;
	}
	// default_action Drop_action_6();
}


//Table
void tbl_act_0_101840() {
	int symbol;
	klee_make_symbolic(&symbol, sizeof(symbol), "symbol");
	switch(symbol) {
		default: act_99936(); break;
	}
	// default_action act();
}


//Table
void tbl_act_1_101900() {
	int symbol;
	klee_make_symbolic(&symbol, sizeof(symbol), "symbol");
	switch(symbol) {
		default: act_2_100003(); break;
	}
	// default_action act_2();
}


//Table
void tbl_act_2_101934() {
	int symbol;
	klee_make_symbolic(&symbol, sizeof(symbol), "symbol");
	switch(symbol) {
		default: act_1_99987(); break;
	}
	// default_action act_1();
}


//Table
void tbl_act_3_101994() {
	int symbol;
	klee_make_symbolic(&symbol, sizeof(symbol), "symbol");
	switch(symbol) {
		default: act_4_100060(); break;
	}
	// default_action act_4();
}


//Table
void tbl_act_4_102028() {
	int symbol;
	klee_make_symbolic(&symbol, sizeof(symbol), "symbol");
	switch(symbol) {
		default: act_3_100044(); break;
	}
	// default_action act_3();
}


//Table
void tbl_act_5_102065() {
	int symbol;
	klee_make_symbolic(&symbol, sizeof(symbol), "symbol");
	switch(symbol) {
		default: act_5_100096(); break;
	}
	// default_action act_5();
}


//Table
void tbl_act_6_102119() {
	int symbol;
	klee_make_symbolic(&symbol, sizeof(symbol), "symbol");
	switch(symbol) {
		default: act_7_100128(); break;
	}
	// default_action act_7();
}


//Table
void tbl_act_7_102153() {
	int symbol;
	klee_make_symbolic(&symbol, sizeof(symbol), "symbol");
	switch(symbol) {
		default: act_6_100112(); break;
	}
	// default_action act_6();
}



//Control
uint32_t tmp_20;

void TopDeparser() {
	//Emit p.ethernet
	klee_print_expr("48, p.ethernet.dstAddr: ", p.ethernet.dstAddr);
	klee_print_expr("48, p.ethernet.srcAddr: ", p.ethernet.srcAddr);
	klee_print_expr("16, p.ethernet.etherType: ", p.ethernet.etherType);
	
	if(p.ip.isValid();) {
		tbl_act_8_102306();

}
	//Emit p.ip
	klee_print_expr("4, p.ip.version: ", p.ip.version);
	klee_print_expr("4, p.ip.ihl: ", p.ip.ihl);
	klee_print_expr("8, p.ip.diffserv: ", p.ip.diffserv);
	klee_print_expr("16, p.ip.totalLen: ", p.ip.totalLen);
	klee_print_expr("16, p.ip.identification: ", p.ip.identification);
	klee_print_expr("3, p.ip.flags: ", p.ip.flags);
	klee_print_expr("13, p.ip.fragOffset: ", p.ip.fragOffset);
	klee_print_expr("8, p.ip.ttl: ", p.ip.ttl);
	klee_print_expr("8, p.ip.protocol: ", p.ip.protocol);
	klee_print_expr("16, p.ip.hdrChecksum: ", p.ip.hdrChecksum);
	klee_print_expr("32, p.ip.srcAddr: ", p.ip.srcAddr);
	klee_print_expr("32, p.ip.dstAddr: ", p.ip.dstAddr);
	
}

// Action
void act_8_100296() {
	action_run = 100296;
		//Extern: ck_2.clear
	p.ip.hdrChecksum = 0;
	//Extern: ck_2.update
		klee_make_symbolic(&tmp_20, sizeof(tmp_20), "tmp_20");

	p.ip.hdrChecksum = tmp_20;

}


//Table
void tbl_act_8_102306() {
	int symbol;
	klee_make_symbolic(&symbol, sizeof(symbol), "symbol");
	switch(symbol) {
		default: act_8_100296(); break;
	}
	// default_action act_8();
}



int main() {
	TopParser();
	int action_run;
	TopPipe();
	TopDeparser();
	return 0;
}


