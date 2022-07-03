/* verilator lint_off DECLFILENAME */
/* verilator lint_off UNUSED */

module registerFile(

    input [3:0] rs1, 
    input [3:0] rs2,
    output [31:0] out_rs1,
    output [31:0] out_rs2,
    input wrEn,

    input clk,
    input reset,
    input [3:0] rd,
    input [31:0] wr_data,
    
    input changeConvolve,
    input convolve,
    input calcLoopOverhead
    );
    
    reg [2:0] convolveState;
    
    reg [31:0] register_file [15:0];
    
    wire [31:0] loopLength = convolveState == 3'b010 ? register_file[2] : register_file[1];
    wire [31:0] convolve1 = register_file[4] == loopLength ? 32'h00000000 : register_file[9];
    wire [31:0] convolve3 = register_file[4] == 32'h00000001 ? 32'h00000000 : register_file[7];
    wire [31:0] convolve2 = {register_file[8][30:0], 1'b0};
    wire [31:0] convolvedValue = convolve1 + convolve2 + convolve3;
    
    wire [31:0] nextPixel = register_file[3] + (convolveState == 3'b010 ? 32'h00000001 : register_file[2]);
    
    assign out_rs1 = register_file[rs1];
    assign out_rs2 = register_file[rs2];

    always@(posedge clk)begin
    	if (changeConvolve && wrEn)begin
    		convolveState <= {convolveState[1:0], convolveState[2]};
    	end
    
    	if(reset)begin
    		convolveState <= 3'b001;
        end else if(wrEn) begin
            register_file[rd] <= wr_data;
        end else if(convolve & (convolveState != 3'b001)) begin
        	register_file[9] <= {2'b00, convolvedValue[31:2]};
        end else if(calcLoopOverhead & (convolveState != 3'b001)) begin
        	register_file[4] <= register_file[4] - 32'h00000001;
        	register_file[3] <= nextPixel;
        	register_file[11] <= register_file[11] + register_file[2];
        	register_file[9] <= register_file[8];
        	register_file[8] <= register_file[7];
        end
    end

endmodule

module alu(

    input [3:0] alu_op,
    input [31:0] op1, 
    input [31:0] op2,
    output [31:0] alu_out,

    output is_zero
    );

    wire [31:0] result_xor = op1 ^ op2;
    wire [31:0] result_sra = $signed(op1) >>> op2;
    wire [31:0] result_or = op1 | op2;
    wire [31:0] result_sll = op1 << op2;
    wire [31:0] result_add = op1 + op2;

    wire isXOR = alu_op == 4'b0011;
    wire isSRA = alu_op == 4'b1001;
    wire isOR  = alu_op == 4'b1000;
    wire isSLL = alu_op == 4'b0111;
    wire isADD = alu_op == 4'b1111;

    //wire [31:0] output =

    assign alu_out = 
    (isXOR ? result_xor : 32'b0)|
    (isSRA ? result_sra : 32'b0)|
    (isOR  ? result_or  : 32'b0)|
    (isSLL ? result_sll : 32'b0)|
    (isADD ? result_add : 32'b0);
    
    assign is_zero = ~|op1;

endmodule

module datapath(

	input reset,

    input wrEn,
    input [3:0] rs1,
    input [3:0] rs2,
    input [3:0] rd,
    input [31:0] alu_imm,
    input choose_alu_imm,
    input [3:0] alu_op,

    input clk,
    input update_1,
    input update_2,

    input [31:0] load_data,
    input choose_load_data,
    output [31:0] mem_address,
    output [31:0] write_data,
    
    input changeConvolve,
    input convolve,
    input calcLoopOverhead,

    input isBranch,
    output [31:0] nextPC,
    input [31:0] branch_imm,
    input [31:0] PC
);

    reg [31:0] op1;
    reg [31:0] op2;
    reg [31:0] writeback_buffer;
    reg [31:0] branch_imm_buffer;
    reg [31:0] PC_buffer;
    reg [31:0] new_PC_buffer;

    wire [31:0] out_rs1;
    wire [31:0] out_rs2;
    wire [31:0] op2_wire = choose_alu_imm ? alu_imm : out_rs2;
    wire [31:0] alu_result;
    wire is_zero;

    wire [31:0] link_address = PC_buffer + 32'h00000002;
    wire [31:0] branch_address = PC_buffer + branch_imm_buffer;

    wire [31:0] writeback_data = choose_load_data ? load_data : alu_result;
    wire [31:0] branch_result = is_zero ? link_address : branch_address;
    wire [31:0] new_PC = isBranch ? branch_result : link_address;

    registerFile datapath_register_file(
        .rs1(rs1),
        .rs2(rs2),
        .out_rs1(out_rs1),
        .out_rs2(out_rs2),
        .wrEn(wrEn),

        .clk(clk),
        .rd(rd),
        .wr_data(writeback_data),
        
        .reset(reset),
        
        .changeConvolve(changeConvolve),
    	.convolve(convolve),
    	.calcLoopOverhead(calcLoopOverhead)
    );

    alu datapath_alu(
        .alu_op(alu_op),
        .op1(op1),
        .op2(op2),
        .alu_out(alu_result),
        .is_zero(is_zero)
    );

    assign mem_address = alu_result;
    assign write_data = out_rs2;
    assign nextPC = new_PC; 

    always@(posedge clk)begin
        if(update_1)begin
            op1 <= out_rs1;
            op2 <= op2_wire;
            branch_imm_buffer <= branch_imm;
            PC_buffer <= PC;  
        end

        if(update_2)begin
            writeback_buffer <= writeback_data;
        end

        /* if(update_new_PC)begin
            new_PC_buffer <= newPC;
        end */
    end

endmodule

module controlStore(

    output wrEn,
    output [3:0] rs1,
    output [3:0] rs2,
    output [3:0] rd,
    output [31:0] alu_imm,
    output choose_alu_imm,
    output [3:0] alu_op,

    input clk,
    output update_1,
    output update_2,

    output choose_PC,//load instruction not data

    output is_branch,
    output choose_load_data,
    input [31:0] nextPC,//from data path

    output [31:0] branch_imm,
    output [31:0] current_PC,

    input reset,

    input [7:0] instByte,
    
    output changeConvolve,
    output convolve,
    output calcLoopOverhead,

    output write_back_mem

);

    reg [31:0] PC;
    reg [15:0] inst;
    reg [3:0] stateReg;

    wire [3:0] fetch_inst_1 = 4'd0;
    wire [3:0] fetch_inst_2 = 4'd1;
    wire [3:0] set_signals = 4'd2;
    wire [3:0] read_registers = 4'd3;
    wire [3:0] get_result = 4'd4;
    wire [3:0] write_back = 4'd5;
    wire [3:0] calc_new_PC = 4'd6;
    wire [3:0] buffer_request = 4'd7;
    wire [3:0] read_mem = 4'd8;
    wire [3:0] mem_write = 4'd9;

    wire isRegReg = inst[2:0] == 3'b010;
    wire isRegImm = inst[2:0] == 3'b110;
    wire isLoad = inst[2:0] == 3'b100;
    wire isStore = inst[2:0] == 3'b101;
    wire isMove = inst[2:0] == 3'b111;

    wire isMemAccess = inst[2:1] == 2'b10;
    wire isBranch = inst[2:0] == 3'b011;
    wire isMemWrite = inst[0];
    wire isMove = inst[2:0] == 3'b111;
    wire isArithmatic = inst[1:0] == 2'b10;

    wire [31:0] negative = 32'hffffffff;
    wire [31:0] positive = 32'h00000000;

    wire [3:0] register1 = inst[15:12];
    wire [3:0] ALU_op = inst[11:8];
    wire [3:0] base_addr = inst[11:8];
    wire [3:0] register2 = inst[7:4];
    wire [31:0] immediate = {(inst[7] ? negative[31:4] : positive[31:4]), inst[6:3]};
    wire [31:0] branch_immediate = {(inst[11] ? negative[31:9] : positive[31:9]), inst[11:3]};

    assign rs1 = isMemAccess ? base_addr : (isMove ? register2 : register1);
    assign rs2 = isStore ? register1 : register2;
    assign rd = register1;
    assign alu_imm = (isMove? 32'h00000000 : immediate);
    assign choose_alu_imm = inst[2];
    assign alu_op = isArithmatic ? ALU_op : 4'b1111;
    assign branch_imm = branch_immediate;
    assign is_branch = isBranch;

    assign current_PC = PC;

    assign choose_PC = (stateReg == fetch_inst_1) || (stateReg == fetch_inst_2);

    assign choose_load_data = isMemAccess;

    assign update_1 = stateReg == read_registers;
    assign update_2 = stateReg == get_result;
    assign wrEn = stateReg == write_back;

    assign write_back_mem = stateReg == mem_write;
    
    assign changeConvolve = inst == 16'b0000100000000010;
    assign convolve = (inst[2:0] == 3'b101) & (stateReg == fetch_inst_2);
    assign calcLoopOverhead = (inst[2:0] == 3'b101) & (stateReg == calc_new_PC);

    always@(posedge clk)begin
        if(reset)begin
            PC <= 0;
            stateReg <= fetch_inst_1;

        end else if(stateReg == fetch_inst_1) begin
            inst <= {inst[15:8], instByte};
            stateReg <= fetch_inst_2;
            PC <= PC | 32'h00000001;

        end else if(stateReg == fetch_inst_2) begin
            inst <= {instByte, inst[7:0]};
            stateReg <= set_signals;

        end else if(stateReg == set_signals) begin
            stateReg <= read_registers;

        end else if(stateReg == read_registers) begin
            if(isMemAccess)begin
                stateReg <= buffer_request;
            end else begin
                stateReg <= get_result;
            end

        end else if(stateReg == get_result)begin
            if(isBranch) begin
                stateReg <= calc_new_PC;
            end else begin
                stateReg <= write_back;
            end

        end else if(stateReg == write_back)begin
            stateReg <= calc_new_PC;

        end else if(stateReg == buffer_request)begin
            if(isMemWrite) begin
                stateReg <= mem_write;
            end else begin
                stateReg <= read_mem;
            end

        end else if(stateReg == mem_write)begin
            stateReg <= calc_new_PC;

        end else if (stateReg == read_mem)begin
            stateReg <= get_result;

        end else if(stateReg == calc_new_PC)begin
            stateReg <= fetch_inst_1;
            PC <= nextPC;

        end

    end


endmodule

module cpu(
    input clk,
    input reset,

    output [31:0] PC_out,

    input [7:0] read_data,
    output [7:0] write_data_mem,
    output [31:0] address,

    output writeBack
);

    wire wrEn;
    wire [3:0] rs1;
    wire [3:0] rs2;
    wire [3:0] rd;
    wire [31:0] alu_imm;
    wire choose_alu_imm;
    wire [3:0] alu_op;

    wire update_1;
    wire update_2;

    wire [31:0] load_data = {24'h000, read_data};
    wire choose_load_data;
    wire [31:0] mem_address;
    wire [31:0] write_data;

    wire isBranch;
    wire [31:0] nextPC;
    wire [31:0] branch_imm;
    wire [31:0] PC;
    
    wire changeConvolve;
    wire convolve;
    wire calcLoopOverhead;

    datapath datapath(
    
    	.reset(reset),
    
        .wrEn(wrEn),
        .rs1(rs1),
        .rs2(rs2),
        .rd(rd),
        .alu_imm(alu_imm),
        .choose_alu_imm(choose_alu_imm),
        .alu_op(alu_op),

        .clk(clk),
        .update_1(update_1),
        .update_2(update_2),

        .load_data(load_data),
        .choose_load_data(choose_load_data),
        .mem_address(mem_address),
        .write_data(write_data),

        .isBranch(isBranch),
        .nextPC(nextPC),
        .branch_imm(branch_imm),
        .PC(PC & 32'hfffffffe),
        
        .changeConvolve(changeConvolve),
    	.convolve(convolve),
    	.calcLoopOverhead(calcLoopOverhead)
    );

    wire choose_PC;
    wire write_back_mem;

    controlStore controlStore(
        .wrEn(wrEn),
        .rs1(rs1),
        .rs2(rs2),
        .rd(rd),
        .alu_imm(alu_imm),
        .choose_alu_imm(choose_alu_imm),
        .alu_op(alu_op),
        .clk(clk),

        .update_1(update_1),
        .update_2(update_2),

        .choose_PC(choose_PC),//load instruction not data

        .is_branch(isBranch),
        .choose_load_data(choose_load_data),
        .nextPC(nextPC),//from data path
        .branch_imm(branch_imm),
        .current_PC(PC),

        .reset(reset),

        .instByte(read_data),

        .write_back_mem(write_back_mem),
        
        .changeConvolve(changeConvolve),
    	.convolve(convolve),
    	.calcLoopOverhead(calcLoopOverhead)
    );

    assign address = choose_PC ? PC : mem_address;
    assign write_data_mem = write_data[7:0];

    assign writeBack = write_back_mem;

    assign PC_out = PC & 32'hfffffffe;

endmodule

module testbench(
    output [31:0] writeAddress,
    output [7:0] writeData,
    output wrEnMem,

    input startProgram,
    input [31:0] programAddress,
    input [7:0] programByte,
    input programWrEn,

    output [31:0] PC_out,

    output decimated_out,

    input reset,
    input clk
);

    wire [7:0] write_data_mem;
    reg [7:0] memory [1048576:0];
    wire [31:0] address;

    reg filtered;

    wire writeBack;

    cpu cpu(
        .reset(reset),
        .clk(clk),

        .read_data(memory[address]),
        .address(address),

        .writeBack(writeBack),
        .write_data_mem(write_data_mem),

        .PC_out(PC_out)
    );

    always@(posedge clk)begin
        if(reset)begin
            filtered <= 1'b0;
        end else if(writeBack & address == 32'h0000ffff)begin
            filtered <= ~filtered;
        end
        if(!startProgram)begin
            if(programWrEn)begin
                memory[programAddress] <= programByte;
            end
        end else begin
            if(writeBack)begin
                memory[address] <= write_data_mem;
            end
        end
    end

    assign writeAddress = address;
    assign wrEnMem = writeBack;
    assign writeData = write_data_mem;

    assign decimated_out = filtered;

endmodule
