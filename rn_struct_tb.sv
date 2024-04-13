`timescale 1ns/10ps

module rn_struct_tb;

	reg clk;
	reg rst;

	wire [7:0] last_stage; // 0
	wire [7:0] amount_channels; // 8
	wire [7:0] kernel_size; // 16
	wire [7:0] stride; // 24
	wire [7:0] if_size; // 32
	wire [7:0] kernel_size_2; // 40
	wire [15:0] ifsize_2; // 48
	wire [7:0] amount_filters; // 64
	wire [7:0] of_size; // 72
	wire [7:0] ofsize_2; // 80
	wire [7:0] of_offset; // 88
								// 96

	wire [7:0] kernel [0:8];
    wire [7:0] bias;

	wire struct_ready;  
							
	reg next;
	reg next_channel;
	reg next_filter;	

    rn_struct dut (
        .clk(clk),
        .rst(rst),

        .last_stage(last_stage), // 0
        .amount_channels(amount_channels), // 8
        .kernel_size(kernel_size), // 16
        .stride(stride), // 24
        .if_size(if_size), // 32
        .kernel_size_2(kernel_size_2), // 40
        .ifsize_2(ifsize_2), // 48
        .amount_filters(amount_filters), // 64
        .of_size(of_size), // 72
        .ofsize_2(ofsize_2), // 80
        .of_offset(of_offset), // 88
                                    // 96

        .kernel(kernel),
        .bias(bias),

        .struct_ready(struct_ready),  
                                
        .next(next),
        .next_channel(next_channel),
        .next_filter(next_filter)	
    );

    
    always #5 clk = ~clk;

    initial begin
        rst = 0;
        clk = 0;
        next = 0;
        next_filter = 0;
        next_channel = 0;
        #10;

        next = 1;

        #10;

        next = 0;

        #10;
        #10;
        #10;
        #10;
        #10;
        #10;
        next_channel = 1;
        #10;
        next_channel = 0;
        #10;
        #10;
        #10;
        #10;
        #10;
        #10;
        #10;
        next_filter = 1;
        #10;
        next_filter = 0;
        #10;
        #10;
        #10;
        #10;
        #10;
        #10;
        next_channel = 1;
        #10;
        next_channel = 0;
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