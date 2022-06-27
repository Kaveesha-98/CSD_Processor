#include <stdio.h>
#include <stdlib.h>
#include "Vcpu.h"
#include "verilated.h"
#include "verilated_vcd_c.h"

void tick(int tickcount, Vcpu *tb, VerilatedVcdC* tfp){
	tb->eval();
	if (tfp){
		tfp->dump(tickcount*10 - 2);
	}
	tb->clk = 1;
	tb->eval();
	if(tfp){
		tfp->dump(tickcount*10);
	}
	tb->clk = 0;
	tb->eval();
	if(tfp){
		tfp->dump(tickcount*10 + 5);
		tfp->flush();
	}
}

int main(int argc, char **argv){

    //0010111100010110
    //0001001000010010
    //00010000_00100111

	unsigned tickcount = 0;

    int instructions[6] = {22, 47, 22, 47, 39, 16};

	// Call commandArgs first!
	Verilated::commandArgs(argc, argv);
	
	//Instantiate our design
	Vcpu *tb = new Vcpu;
	
	Verilated::traceEverOn(true);
	VerilatedVcdC* tfp = new VerilatedVcdC;
	tb->trace(tfp, 99);
	tfp->open("cpu.vcd");

    tick(++tickcount, tb, tfp);

    tb -> reset = 1;

    tick(++tickcount, tb, tfp);

    tb -> reset = 0;
	
	for(int i = 0; i < 30; i++){
        if(tb -> address > 5){
            tb -> read_data = 0;
        }else{
            tb -> read_data = instructions[tb -> address];
        }
        tick(++tickcount, tb, tfp);
	}

}