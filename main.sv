`timescale 1ns/100ps

module main;

    parameter COLS_MAC = 4;
    parameter INPUTS_MAC = 6;
    parameter ADDRESS_BITS = 16;

    reg clk;
    wire rst;
    reg start;
    wire start_fc;
// ########################################################
// ################## fsm_fc ##############################
// ########################################################

// ### package from rn_struct ###	
    wire [15:0] cant_inputs_fc;
    wire [15:0] iters_per_neuron_fc;
    wire [7:0] modulo_fc;
    wire [7:0] cant_neurons_fc;
    wire [7:0] last_fc;
    wire [15:0] of_offset_fc;
    wire [7:0] n_fc;
    wire [7:0] frac_fc;

	wire struct_ready_fc;
	
	wire next_layer_fc;
    wire next_neuron_fc;
    wire get_weight_fc;

	wire [7:0] kernel_fc [0:INPUTS_MAC-1];
	wire signed [31:0] bias_fc;    

// ###################################	

// ### kernel weights to MAC array ###	
	wire [7:0] weights2arr_fc [0:INPUTS_MAC-1]; 
	wire write_kernel_fc;
// ###################################	
	
    wire [0:ADDRESS_BITS-1] if_base_in_fc;

// ############### Mem ####################	
	wire signed [31:0] macs_result_fc;
	wire en_w_fc [0:COLS_MAC-1];

	wire [7:0] if_data_fc [0:INPUTS_MAC - 1];  // 6 filas 
	reg [7:0] if_data_memory_fc [0:INPUTS_MAC - 1];
	wire [ADDRESS_BITS-1:0] if_address_fc [0:INPUTS_MAC - 1];
	
	wire [7:0] of_write_fc [0:COLS_MAC-1];
	wire [ADDRESS_BITS-1:0] of_w_address_fc [0:COLS_MAC-1];

// ############	



    fsm_fc #(.ADDRESS_BITS(ADDRESS_BITS), .COLS_MAC(COLS_MAC), .INPUTS_MAC(INPUTS_MAC)) fsm_fc_instance(
        .clk(clk),
        .rst(rst),
        .start(start_fc),

    // ### package from rn_struct ###	
        .cant_inputs(cant_inputs_fc),
        .iters_per_neuron(iters_per_neuron_fc),
        .modulo(modulo_fc),
        .cant_neurons(cant_neurons_fc),
        .last(last_fc),
        .of_offset(of_offset_fc),
        .n(n_fc),
        .frac(frac_fc),

        .struct_ready(struct_ready_fc),
        
        .next_layer(next_layer_fc),
        .next_neuron(next_neuron_fc),
        .get_weight(get_weight_fc),

        .kernel(kernel_fc),
        .bias(bias_fc),    

    // ###################################	

    // ### kernel weights to MAC array ###	
        .weights2arr(weights2arr_fc), 
        .write_kernel(write_kernel_fc),
    // ###################################	
        
        .if_base_in(if_base_in_fc),

    // ############### Mem ####################	
        .macs_result(macs_result_fc),
        .en_w(en_w_fc),

        .if_data(if_data_fc),  
        .if_data_memory(if_data_memory_fc),
        .if_address(if_address_fc),
        
        .of_write(of_write_fc),
        .of_w_address(of_w_address_fc)
    // ############	
    );

    rn_FC_struct #(.INPUTS_MAC(INPUTS_MAC)) rn_FC_struct_instance(
        .clk(clk),
        .rst(rst),

    // ########### FC  ####################

        .cant_inputs(cant_inputs_fc),
        .iters_per_neuron(iters_per_neuron_fc),
        .modulo(modulo_fc),
        .cant_neurons(cant_neurons_fc),
        .last(last_fc),
        .of_offset(of_offset_fc),
        .n(n_fc),
        .frac(frac_fc),
        // 10 bytes

        .next_layer(next_layer_fc),
        .next_neuron(next_neuron_fc),
        .get_weight(get_weight_fc),

        .kernel_FC(kernel_fc),
        .bias_FC(bias_fc),    

        .struct_ready(struct_ready_fc) 
    );

	PE_FC_array PE_FC_array_instance(
    .clk(clk),
    .rst(rst),
    .write_kernel(write_kernel_fc),
    .inputs_mac(if_data_fc), 
    .weights(weights2arr_fc),
    .output_mac(macs_result_fc)
    );


// ########################################################
// ################## wire fsm_fc ##############################
// ########################################################


    wire [7:0] last_stage;
    wire [7:0] amount_channels;
    wire [7:0] kernel_size;
    wire [7:0] stride;
    wire [7:0] if_size;
    wire [7:0] kernel_size_2;
    wire [15:0] ifsize_2;
    wire [7:0] amount_filters;
    wire [7:0] of_size;
    wire [15:0] ofsize_2;
    wire [15:0] of_offset;
    
    wire [7:0] kernel [0:8];
    wire [31:0] bias;
	wire [7:0] n;
	wire [7:0] frac;

    wire struct_ready;
    
    wire next;
    wire next_channel;
    wire next_filter;	
    
	wire [7:0] kernel_weigths [0:8];
	wire write_kernel;

	wire [31:0] macs_result [0:COLS_MAC-1];
	wire en_w [0:COLS_MAC-1];

	wire [7:0] if_data [0:INPUTS_MAC-1];  
    reg [7:0] if_data_memory [0:INPUTS_MAC-1];
	wire [ADDRESS_BITS-1:0] if_address [0:INPUTS_MAC-1];
	
	wire [7:0] of_write [0:COLS_MAC-1];
	wire [ADDRESS_BITS-1:0] of_w_address [0:COLS_MAC-1];

	wire [7:0] of_read [0:COLS_MAC-1];
	wire [ADDRESS_BITS-1:0] of_r_address [0:COLS_MAC-1];

    // ###############################################
    // ###############################################
    // ###############################################
    reg [7:0] of_write_in [0:COLS_MAC-1];
    reg [ADDRESS_BITS-1:0] of_w_address_in [0:COLS_MAC-1];

    wire [7:0] if_data_memory_in [0:INPUTS_MAC-1];
    reg [ADDRESS_BITS-1:0] if_address_in [0:INPUTS_MAC-1];

    reg en_w_in [0:COLS_MAC-1];

    always @(*) begin
        if(start_fc == 0) begin
            of_write_in = of_write;
            of_w_address_in = of_w_address;

            if_data_memory = if_data_memory_in;
            if_address_in = if_address;

            en_w_in = en_w;
        end
        else begin
            of_write_in = of_write_fc;
            of_w_address_in = of_w_address_fc;

            if_data_memory_fc = if_data_memory_in;
            if_address_in = if_address_fc;

            en_w_in = en_w_fc;
        end
    end


    // ###############################################
    // ################ fsm_rn #######################
    // ###############################################
    
    fsm_rn #(.ADDRESS_BITS(ADDRESS_BITS), .COLS_MAC(COLS_MAC), .INPUTS_MAC(INPUTS_MAC)) fsm_rn_instance(
        .clk(clk),
        .rst(rst),
        .start(start),
        .start_fc(start_fc),
    // ###############################	
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
        .n(n),
        .frac(frac),

        .struct_ready(struct_ready),  
                                
        .next(next),
        .next_channel(next_channel),
        .next_filter(next_filter),	
    // ###############################	

    // ### kernel weights to MAC array ###	
        .kernel_weigths(kernel_weigths),
        .write_kernel(write_kernel),
    // ###################################	
        .of_base_out(if_base_in_fc),
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
    // ###################################	
    );


    // ###############################################
    // ################ PE array #####################
    // ###############################################

    PE_array PE_array_instance (
        .clk(clk),
        .rst(rst),
        .write_kernel(write_kernel),
        .inputs_mac(if_data),
        .weights(kernel_weigths),
        .outputs_mac(macs_result)  
    );

    // ###############################################
    // ################ mem ##########################
    // ###############################################


    mem #(.ADDRESS_BITS(ADDRESS_BITS), .COLS_MAC(COLS_MAC), .INPUTS_MAC(INPUTS_MAC)) mem_instance(
        .of_write(of_write_in),
        .of_w_address(of_w_address_in),

        .of_read(of_read),
        .of_r_address(of_r_address),

        .ifmap_r(if_data_memory_in),
        .if_address(if_address_in), 

        .en_w(en_w_in),
        .clk(clk), 
        .rst(rst)
    );

    // ###############################################
    // ###############################################
    // ###############################################


    // ###############################################
    // ################ rn_struct ####################
    // ###############################################

    rn_struct rn_struct_instance(
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
        .n(n),
        .frac(frac),

        .struct_ready(struct_ready),  
                                
        .next(next),
        .next_channel(next_channel),
        .next_filter(next_filter)
    );

    // ###############################################
    // ###############################################
    // ###############################################


    always #5 clk = ~clk;

    initial begin
        clk = 0;
        start = 0;
        #10;
        start = 1;
        #10;
        start = 0;
        #350000;
        $finish;
    end

endmodule