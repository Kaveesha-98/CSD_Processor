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

	cout << "loading instructions\n";

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

	bool realImage = true;

	if(!realImage){
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
	} else {
		cout << "loading image\n";

		ifstream imageFile("imageFile.txt");

		address = 256; 

		// Use a while loop together with the getline() function to read the file line by line
		while (getline (imageFile, myText)) {
		// Output the text from the file
			tb -> programAddress = address;
			tb -> programByte = stoi(myText);
			tick(++tickcount, tb, tfp);
			address++;
		}

		// Close the file
		imageFile.close();
	}
	int image[7*9]; 

	tb -> programWrEn = 0;
	tb -> reset = 0;
	tb -> startProgram = 1;

	tick(++tickcount, tb, tfp);

	/* for (int i = 0; i < 1000; i++){
		tick(++tickcount, tb, tfp);
	} */

	int row, col;

	ofstream outfile;
   	outfile.open("decimatedImage.txt");

	cout << "performing horizontal convolution\n";

	while(tb-> PC_out < 39*2){
		//cout << tb -> PC_out << endl;
		if(tb-> writeAddress > 259 && tb -> wrEnMem == 1){
			//image[tb-> writeAddress - 260] = tb -> writeData;
			//cout << tb-> writeAddress << " = " << (tb -> writeData + 0) <<'\n';
			//outfile << tb-> writeAddress << ' ' << (tb -> writeData + 0) << endl;
			address = (tb-> writeAddress) - 4;
			row = address/400;
			col = address%400;
			cout << "performing horizontal convolution on row:" << '\t' << row << " and col:" << '\t' << col << '\t' << '\r';

		}
		tick(++tickcount, tb, tfp);
	}

	cout << "performing vertical convolution                                                                \n";

	while(tb-> PC_out < 70*2){
		//cout << tb -> PC_out << endl;
		if(tb-> writeAddress > 259 && tb -> wrEnMem == 1){
			image[tb-> writeAddress - 260] = tb -> writeData;
			//cout << tb-> writeAddress << " = " << (tb -> writeData + 0) <<'\n';
			//outfile << tb-> writeAddress << ' ' << (tb -> writeData + 0) << endl;
			address = (tb-> writeAddress) - 4;
			row = address/400;
			col = address%400;
			cout << "performing vertical convolution on row:" << '\t' << row << " and col:" << '\t' << col << '\t' << '\r';

		}
		tick(++tickcount, tb, tfp);
	}

	cout << "convolution finished                                                                      \n";

	

	/* for(int row = 0; row < 9; row++){
		for(int col = 0; col < 7; col++){
			cout << image[row*7 + col] << ' ';
		}
		cout << endl;
	} */

	cout << "performing downsampling\n";

	while(tb-> PC_out < 102*2){
		//cout << tb -> PC_out << endl;
		if(tb-> writeAddress > 255 && tb -> wrEnMem == 1){
			//image[tb-> writeAddress - 260] = tb -> writeData;
			//cout << tb-> writeAddress << " = " << (tb -> writeData + 0) <<'\n';
			outfile << tb-> writeAddress << ' ' << (tb -> writeData + 0) << endl;
			address = (tb-> writeAddress);
			row = address/400;
			col = address%400;
			//cout << "performing vertical convolution on row:" << '\t' << row << " and col:" << '\t' << col << '\t' << '\r';

		}
		tick(++tickcount, tb, tfp);
	}

	outfile.close();

	//cout << ""

	/* for(int row = 0; row < 5; row++){
		for(int col = 0; col < 4; col++){
			cout << image[row*4 + col] << ' ';
		}
		cout << endl;
	} */

}