`timescale 1ns/10ps

module fsm_rn_tb;

    parameter COLS_MAC = 4;
    parameter INPUTS_MAC = 6;
    parameter ADDRESS_BITS = 12;

    reg clk;
    reg rst;
    reg start;

    // ###############################################
    // ################  ####################
    // ###############################################

    reg [7:0] last_stage;
    reg [7:0] amount_channels;
    reg [7:0] kernel_size;
    reg [7:0] stride;
    reg [7:0] if_size;
    reg [7:0] kernel_size_2;
    reg [15:0] ifsize_2;
    reg [7:0] amount_filters;
    reg [7:0] of_size;
    reg [15:0] ofsize_2;
    reg [15:0] of_offset;
    
    reg [7:0] kernel [0:8];
    reg [7:0] bias;

    reg struct_ready;
    
    wire next;
    wire next_channel;
    wire next_filter;	
    
	wire [7:0] kernel_weigths [0:8];
    wire [7:0] bias_mac; 
	wire write_kernel;


	wire [7:0] macs_result [0:COLS_MAC-1];
	wire en_w [0:COLS_MAC-1];

	wire [7:0] if_data [0:INPUTS_MAC-1];  // 6 filas 
    reg [7:0] if_data_memory [0:INPUTS_MAC-1];
	wire [ADDRESS_BITS-1:0] if_address [0:INPUTS_MAC-1];
	
	wire [7:0] of_write [0:COLS_MAC-1];
	wire [ADDRESS_BITS-1:0] of_w_address [0:COLS_MAC-1];

	reg [7:0] of_read [0:COLS_MAC-1];
	wire [ADDRESS_BITS-1:0] of_r_address [0:COLS_MAC-1];

    // ###############################################
    // ################  ####################
    // ###############################################

    
    fsm_rn #(.ADDRESS_BITS(ADDRESS_BITS), .COLS_MAC(COLS_MAC), .INPUTS_MAC(INPUTS_MAC)) fsm_rn_instance(
        .clk(clk),
        .rst(rst),
        .start(start),

        .last_stage(last_stage),
        .amount_channels(amount_channels), 
        .kernel_size(kernel_size), 
        .stride(stride), 
        .if_size(if_size), 
        .kernel_size_2(kernel_size_2), 
        .ifsize_2(ifsize_2), 
        .amount_filters(amount_filters), 
        .of_size(of_size),
        .ofsize_2(ofsize_2), 
        .of_offset(of_offset), 

        .kernel(kernel),
        .bias(bias),

        .struct_ready(struct_ready),  
                                
        .next(next),
        .next_channel(next_channel),
        .next_filter(next_filter),	
    // ###############################	

    // ### kernel weights to MAC array ###	
        .kernel_weigths(kernel_weigths),
        .bias_mac(bias_mac),
        .write_kernel(write_kernel),
    // ###################################	
        
    // ############### Mem  ####################	
        .macs_result(macs_result),
        .en_w(en_w),

        .if_data(if_data),  // 6 filas 
        .if_data_memory(if_data_memory),
        .if_address(if_address),
        
        .of_write(of_write),
        .of_w_address(of_w_address),

        .of_read(of_read),
        .of_r_address(of_r_address)
    // ############	
    );


    PE_array PE_array_instance (
        .clk(clk),
        .rst(rst),
        .write_kernel(write_kernel),
        .inputs_mac(if_data),
        .weights(kernel_weigths),
        .outputs_mac(macs_result)  
    );

    always #5 clk = ~clk;

    initial begin
        rst = 0;
        clk = 0;
        start = 0;

        for (int i = 0; i < COLS_MAC; i++) begin
            of_read[i] = 0;
        end

        last_stage = 0;
        amount_channels = 2;
        kernel_size = 3;
        stride = 0;
        if_size = 12;
        kernel_size_2 = 9;
        ifsize_2 = 144;
        amount_filters = 2;
        of_size = 12 - 3 + 1;
        ofsize_2 = (12 - 3 + 1)*(12 - 3 + 1);
        of_offset = 144*2;
        
        for (int i = 0; i < 9; i++) begin
            kernel[i] = 1;
        end

        for (int i = 0; i < INPUTS_MAC; i++) begin
            if_data_memory[i] = 1;
        end
        bias = 0;

        struct_ready = 0;

        #10;
        start = 1;
        #10;
        start = 0;
        struct_ready = 1;
        #10;
        struct_ready = 0;
        #10;

        /*
        #10;
        for (int i = 0; i < INPUTS_MAC; i++) begin
            if_data_memory[i] = 2;
        end
        #10;
        for (int i = 0; i < INPUTS_MAC; i++) begin
            if_data_memory[i] = 3;
        end
        #10;
        for (int i = 0; i < INPUTS_MAC; i++) begin
            if_data_memory[i] = 4;
        end
        #10;
        for (int i = 0; i < INPUTS_MAC; i++) begin
            if_data_memory[i] = 5;
        end
        #10;
        for (int i = 0; i < INPUTS_MAC; i++) begin
            if_data_memory[i] = 6;
        end
        #10;
        for (int i = 0; i < INPUTS_MAC; i++) begin
            if_data_memory[i] = 7;
        end
        #10;
        for (int i = 0; i < INPUTS_MAC; i++) begin
            if_data_memory[i] = 8;
        end
        #10;
        for (int i = 0; i < INPUTS_MAC; i++) begin
            if_data_memory[i] = 9;
        end
        #10;
        for (int i = 0; i < INPUTS_MAC; i++) begin
            if_data_memory[i] = 10;
        end
        #10;
        for (int i = 0; i < INPUTS_MAC; i++) begin
            if_data_memory[i] = 11;
        end
        #10;
        for (int i = 0; i < INPUTS_MAC; i++) begin
            if_data_memory[i] = 12;
        end*/
        #30;    
        struct_ready = 1;
        #6000;
        $finish;
    end

endmodule