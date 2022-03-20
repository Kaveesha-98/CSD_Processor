`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/20/2022 05:50:10 PM
// Design Name: 
// Module Name: kav720
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module kav720(
    input clk,
    input reset,
    input [3:0] io_rs1,
    input [3:0] io_rs2,
    input io_read_registers,
    input [31:0] io_immediate,
    input io_choose_PC
    );
    
    reg [31:0] PC;
    
    reg [31:0] registerFile [15:0];
    reg [31:0] rs1;
    reg [31:0] rs2;
    
    always @(posedge clk)begin
        if(io_read_registers)begin
            rs1 <= registerFile[io_rs1];
            rs2 <= registerFile[io_rs2];
        end
    end
    
    //for register register instruction alu_in1-rs1 and alu_in2-rs2
    //for register immediate instruction alu_in1-rs1 and alu_in2-immediate
    //for mov instruction alu_in1-0 and alu_in2-rs2
    //for link instruction alu_in1-PC and alu_in2-0
    //for jum and link instruction alu_in1-PC and alu_in2-0
    
    wire [31:0] alu_in1 = io_choose_PC ? PC : rs1;
    wire [31:0] alu_in2;
endmodule
