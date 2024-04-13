`timescale 1ns/10ps

module mem_tb;

    parameter ADDRESS_BITS = 8;
    parameter COLS_MAC = 4;
    parameter INPUTS_MAC = 6;

	reg [7:0] of_write [0:COLS_MAC-1];
	reg [ADDRESS_BITS-1:0] of_w_address [0:COLS_MAC-1];

	wire [7:0] of_read [0:COLS_MAC-1];
	reg [ADDRESS_BITS-1:0] of_r_address [0:COLS_MAC-1];

	wire [7:0] ifmap_r [0:INPUTS_MAC-1];
	reg [ADDRESS_BITS-1:0] if_address [0:INPUTS_MAC-1]; 

	reg en_w [0:3];
	reg clk;
	reg rst;

    mem #(.ADDRESS_BITS(ADDRESS_BITS), .COLS_MAC(COLS_MAC), .INPUTS_MAC(INPUTS_MAC)) dut(
	.of_write(of_write),
	.of_w_address(of_w_address),

	.of_read(of_read),
	.of_r_address(of_r_address),

	.ifmap_r(ifmap_r),
	.if_address(if_address), 

	.en_w(en_w),
	.clk(clk), 
	.rst(rst)
    );

    always #5 clk = ~clk;

    initial begin
        rst = 0;
        clk = 0;
        en_w[0] = 0;
        #10;
        #10;
        #10;
        #10;
        #10;
        #10;
        #10;
        #10;
        #10;
        en_w[0] = 1;
        for (int i = 0; i < COLS_MAC; i = i + 1) begin
            of_w_address[i] = i;
            of_write[i] = i + 1;    
        end
        #10;
        en_w[0] = 0;
        for (int i = 0; i < COLS_MAC; i = i + 1) begin
            of_r_address[i] = i;
        end
        #10;
        en_w[0] = 1;
        of_w_address[0] = 4;
        of_w_address[1] = 5;
        of_w_address[2] = 6;
        of_w_address[3] = 7;
        of_write[0] = 10;    
        of_write[1] = 11;
        of_write[2] = 12;
        of_write[3] = 13;
        #10;
        for (int i = 0; i < INPUTS_MAC  ; i = i + 1) begin
            if_address[i] = i + 2;
        end
        en_w[0] = 0;
        #10;
        #10;
        #10;
        #10;
        #10;
        #10;
        #10;
        #10;
        #10;
        #10;
        #10;
        #10;
        $finish;
    end

endmodule 