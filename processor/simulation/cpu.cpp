#include <stdio.h>
#include <stdlib.h>
#include "Vtestbench.h"
#include "verilated.h"
#include "verilated_vcd_c.h"

#include <iostream>
#include <fstream>

#include <cstdlib>

using namespace std;

void tick(int tickcount, Vtestbench *tb, VerilatedVcdC* tfp){
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
	Vtestbench *tb = new Vtestbench;
	
	Verilated::traceEverOn(true);
	VerilatedVcdC* tfp = new VerilatedVcdC;
	tb->trace(tfp, 99);
	tfp->open("testbench.vcd");

	tb -> startProgram = 0;

    tick(++tickcount, tb, tfp);

    tb -> reset = 1;

    tick(++tickcount, tb, tfp);
	
	/* for(int i = 0; i < 30; i++){
        if(tb -> address > 5){
            tb -> read_data = 0;
        }else{
            tb -> read_data = instructions[tb -> address];
        }
        tick(++tickcount, tb, tfp);
	} */

	tb -> programWrEn = 1;

	string myText;

	// Read from the text file
	ifstream MyReadFile("instructions.txt");

	int address = 0; 

	// Use a while loop together with the getline() function to read the file line by line
	while (getline (MyReadFile, myText)) {
	// Output the text from the file
		tb -> programAddress = address;
		tb -> programByte = stoi(myText);
		tick(++tickcount, tb, tfp);
		address++;
	}

	// Close the file
	MyReadFile.close(); 

	//programming
	/* for(int i = 0; i < 6; i++){
		tb -> programAddress = i;
		tb -> programByte = instructions[i];

		tick(++tickcount, tb, tfp);
	} */

	//loading image
	tb -> programAddress = 256;
	tb -> programByte = 9;

	tick(++tickcount, tb, tfp);

	tb -> programAddress = 257;
	tb -> programByte = 0;

	tick(++tickcount, tb, tfp);

	tb -> programAddress = 258;
	tb -> programByte = 7;

	tick(++tickcount, tb, tfp);

	tb -> programAddress = 259;
	tb -> programByte = 0;

	tick(++tickcount, tb, tfp);

	for(int imageAddress = 260; imageAddress < 260 + 7*9; imageAddress++){
		tb -> programAddress = imageAddress;
		tb -> programByte = imageAddress - 256;

		tick(++tickcount, tb, tfp);
	}

	tb -> programWrEn = 0;
	tb -> reset = 0;

	tick(++tickcount, tb, tfp);

	/* for (int i = 0; i < 1000; i++){
		tick(++tickcount, tb, tfp);
	} */

	while(tb-> PC_out < 68){
		//cout << tb -> PC_out << endl;
		tick(++tickcount, tb, tfp);
	}

}