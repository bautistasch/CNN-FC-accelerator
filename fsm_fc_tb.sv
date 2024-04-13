`timescale 1ns/10ps

module fsm_fc_tb;

    parameter INPUTS_MAC = 6;
    parameter ADDRESS_BITS = 6;
    parameter COLS_MAC = 4;

	reg clk;
	reg rst;
    reg start;

// ########### FC  ####################

    wire [7:0] cant_inputs;
    wire [15:0] iters_per_neuron;
    wire [7:0] modulo;
    wire [7:0] cant_neurons;
    wire [7:0] last;
    wire [15:0] of_offset;
    wire [7:0] n;
    wire [7:0] frac;

	wire struct_ready;  

	wire next_layer;
    wire next_neuron;
    wire get_weight;

	wire [7:0] kernel [0:INPUTS_MAC-1];
	wire [31:0] bias;    

// ### kernel weights to MAC array ###	
	wire [7:0] weights2arr [0:INPUTS_MAC-1];
	wire write_kernel;
// ###################################	
	
    reg [0:ADDRESS_BITS-1] if_base_in;

// ############### Mem ####################	
	wire signed [31:0] macs_result;
	wire en_w [0:COLS_MAC-1];

	wire [7:0] if_data [0:INPUTS_MAC - 1]; 
	wire [7:0] if_data_memory [0:INPUTS_MAC - 1];
	wire [ADDRESS_BITS-1:0] if_address [0:INPUTS_MAC - 1];
	
	wire [7:0] of_write [0:COLS_MAC-1];
	wire [ADDRESS_BITS-1:0] of_w_address [0:COLS_MAC-1];

	wire [7:0] of_read [0:COLS_MAC-1];
	wire [ADDRESS_BITS-1:0] of_r_address [0:COLS_MAC-1];
// ############	


fsm_fc #(.ADDRESS_BITS(ADDRESS_BITS), .COLS_MAC(COLS_MAC), .INPUTS_MAC(INPUTS_MAC)) fsm_fc_instance(
	.clk(clk),
	.rst(rst),
	.start(start),

// ### package from rn_struct ###	
    .cant_inputs(cant_inputs),
    .iters_per_neuron(iters_per_neuron),
    .modulo(modulo),
    .cant_neurons(cant_neurons),
    .last(last),
    .of_offset(of_offset),
	.n(n),
	.frac(frac),

	.struct_ready(struct_ready),
	
	.next_layer(next_layer),
    .next_neuron(next_neuron),
    .get_weight(get_weight),

	.kernel(kernel),
	.bias(bias),    

// ###################################	

// ### kernel weights to MAC array ###	
	.weights2arr(weights2arr), 
	.write_kernel(write_kernel),
// ###################################	
	
    .if_base_in(if_base_in),

// ############### Mem ####################	
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

	PE_FC_array PE_FC_array_instance(
    .clk(clk),
    .rst(rst),
    .write_kernel(write_kernel),
    .inputs_mac(if_data), // 6 rows
    .weights(weights2arr),
    .output_mac(macs_result)
);

    rn_FC_struct rn_FC_struct_instance (
	.clk(clk),
	.rst(rst),

    .cant_inputs(cant_inputs),
    .iters_per_neuron(iters_per_neuron),
    .modulo(modulo),
    .cant_neurons(cant_neurons),
    .last(last),
    .of_offset(of_offset),
	.n(n),
	.frac(frac),
	// 10 bytes

	.next_layer(next_layer),
    .next_neuron(next_neuron),
    .get_weight(get_weight),

	.kernel_FC(kernel),
	.bias_FC(bias),    

	.struct_ready(struct_ready)
    );
    
	mem #(.ADDRESS_BITS(ADDRESS_BITS), .COLS_MAC(COLS_MAC), .INPUTS_MAC(INPUTS_MAC)) mem_instance(
		.of_write(of_write),
		.of_w_address(of_w_address),

		.of_read(of_read),
		.of_r_address(of_r_address),

		.ifmap_r(if_data_memory),
		.if_address(if_address), 

		.en_w(en_w),
		.clk(clk), 
		.rst(rst)
	);


    always #5 clk = ~clk;

    initial begin
        rst = 0;
        clk = 0;
        if_base_in = 0;
        #10;
        start = 1;
        #10;
        start = 0;
        #10;
        #10;
		#3000;
        $finish;
    end

endmodule 