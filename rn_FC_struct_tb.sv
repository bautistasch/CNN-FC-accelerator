`timescale 1ns/10ps

module rn_FC_struct_tb;

    parameter INPUTS_MAC = 6;

	reg clk;
	reg rst;

// ########### FC  ####################

    wire [7:0] cant_inputs;
    wire [15:0] iters_per_neuron;
    wire [7:0] modulo;
    wire [7:0] cant_neurons;
    wire [7:0] last;
    wire [15:0] of_offset;
	// 8 bytes

	reg next_layer;
    reg next_neuron;
    reg get_weight;

	wire [7:0] kernel_FC [0:INPUTS_MAC-1];
	wire [7:0] bias_FC;    

	wire struct_ready;  

    rn_FC_struct dut (
	.clk(clk),
	.rst(rst),

// ########### FC  ####################

    .cant_inputs(cant_inputs),
    .iters_per_neuron(iters_per_neuron),
    .modulo(modulo),
    .cant_neurons(cant_neurons),
    .last(last),
    .of_offset(of_offset),
	// 8 bytes

	.next_layer(next_layer),
    .next_neuron(next_neuron),
    .get_weight(get_weight),

	.kernel_FC(kernel_FC),
	.bias_FC(bias_FC),    

	.struct_ready(struct_ready)
    );
    
    always #5 clk = ~clk;

    initial begin
        rst = 0;
        clk = 0;
        next_layer = 0;
        next_neuron = 0;
        get_weight = 0;
        #10;

        next_layer = 1;
        #10;
        next_layer = 0;
        #10;
        #10;
        #10;
        get_weight = 1;
        #10;
        #10;
        get_weight = 0;
        next_neuron = 1;
        #10;
        next_neuron = 0;
        get_weight = 1;
        #10;
        #10;
        #10;
        $finish;
    end

endmodule 