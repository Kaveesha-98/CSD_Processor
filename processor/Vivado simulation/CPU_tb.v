module testbench_tb ();
    `timescale 1ns/1ps

    localparam CLK_PERIOD = 10;

    reg startProgram = 0;
    reg [31:0] programAddress = 0;
    reg [7:0] programByte = 0;
    reg programWrEn = 1;

    reg reset = 1;
    reg clk = 0;

    wire PC_out;

    
    integer inputArray[0:200206];   //change array size(end line number of input file)
    integer i = 0;
    integer value;
    integer fd;
    integer stage = 1;

    reg[8*45:1] str;

    initial begin
        fd = $fopen("input.txt", "r");

        while (! $feof(fd)) begin 
  
        // Get current line into the variable 'str'  
        $fgets(str, fd);
        //convert to integer type
        $sscanf(str, "%d", value);
        inputArray[i] = value;
        // Display contents of the variable 
        //$display("%8d", value);  
        i = i + 1;
        end  
        $fclose(fd); 
    end
    
    always #(CLK_PERIOD/2) clk <= ~clk;

    testbench testtestbench(
        .startProgram(startProgram),
        .programAddress(programAddress),
        .programByte(programByte),
        .programWrEn(programWrEn),
        .PC_out(PC_out),
        .reset(reset),
        .clk(clk)
    );

    integer int_address = 0;
    integer final_inst_address = 201;        //final instruction line no - 1
    integer final_pixel_address = 200206;        //input array size value  integer inputArray[0:x];  (x)
    integer mem_pixel_address = 256;          //first pixel address
    

    always @(posedge clk) begin
        if (stage == 1) begin
            programAddress <= int_address;
            programByte <= inputArray[int_address];
            int_address <= int_address + 1;
            if (int_address == final_inst_address) begin
                stage <= 2;
            end
        end
        
        else if(stage == 2)begin
            programAddress <= mem_pixel_address;
            programByte <= inputArray[int_address];
            mem_pixel_address <= mem_pixel_address + 1;
            int_address <= int_address + 1;
            if (int_address == final_pixel_address) begin
                stage <= 3;
                startProgram <= 1;
                programWrEn <= 0;
                reset <= 0;
            end
        end
    end
endmodule
