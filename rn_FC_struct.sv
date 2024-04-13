module rn_FC_struct #(parameter INPUTS_MAC = 6)(
	input wire clk,
	input wire rst,

// ########### FC  ####################

    output reg [15:0] cant_inputs,
    output reg [15:0] iters_per_neuron,
    output reg [7:0] modulo,
    output reg [7:0] cant_neurons,
    output reg [7:0] last,
    output reg [15:0] of_offset,
	output reg [7:0] n,
	output reg [7:0] frac,
	// 11 bytes

	input wire next_layer,
    input wire next_neuron,
    input wire get_weight,

	output reg [7:0] kernel_FC [0:INPUTS_MAC-1],
	output reg [31:0] bias_FC,    

	output reg struct_ready 
);

parameter SIZE_FC_BUFFER = 20;
parameter WEIGHTS_FC_AMOUNT = 32768; 
parameter BIAS_FC_AMOUNT = 4096;

parameter IDLE = 0;
parameter STATE_A = 1;
parameter STATE_B = 2;
parameter ADDRESS_BITS = 15;

reg [7:0] state;

reg [7:0] rn_buffer [0:SIZE_FC_BUFFER * 11 - 1];
reg [7:0] kernel_buffer [0:WEIGHTS_FC_AMOUNT - 1];
reg [31:0] bias_buffer [0:BIAS_FC_AMOUNT - 1];


reg [ADDRESS_BITS-1:0] ptr_rn;
reg [ADDRESS_BITS-1:0] ptr_kernel;
reg [ADDRESS_BITS-1:0] ptr_next_base_neuron;
reg [ADDRESS_BITS-1:0] ptr_bias;

reg first_iter;

initial begin

	$readmemh("rn_bufferFC_init.mem", rn_buffer);
	$readmemh("kernel_bufferFC_init.mem", kernel_buffer);
	$readmemh("bias_bufferFC_init.mem", bias_buffer);

	state = IDLE;

	ptr_rn = 0;
	ptr_kernel = 0;
    ptr_next_base_neuron = 0;
	ptr_bias = 0;
	first_iter = 1;

    cant_inputs = 0;
    iters_per_neuron = 0;
    modulo = 0;
    cant_neurons = 0;
    last = 0;
    of_offset = 0;
	n = 0;
	frac = 0;

	for (int i = 0; i < INPUTS_MAC; i++) begin
		kernel_FC[i] <= 0;
	end
    bias_FC = 0;
	struct_ready = 0;
end

always @(posedge clk) begin
    if (rst == 1) begin
        for (int i = 0; i < INPUTS_MAC; i++) begin
            kernel_FC[i] <= 0;
        end
    end
    else begin
        if (next_neuron == 1) begin
            ptr_next_base_neuron <= ptr_next_base_neuron + cant_inputs;
            ptr_kernel <= ptr_next_base_neuron;
            ptr_bias <= ptr_bias + 1;
        end
        else if (state == STATE_A) begin
            ptr_next_base_neuron <= ptr_kernel + {rn_buffer[ptr_rn + 1], rn_buffer[ptr_rn]}; 
        end
        else if (get_weight == 1) begin
            ptr_kernel <= ptr_kernel + 6; 
            kernel_FC <= kernel_buffer[ptr_kernel+: 6];
            bias_FC <= bias_buffer[ptr_bias];
        end
        else begin
            for (int i = 0; i < INPUTS_MAC; i++) begin
                kernel_FC[i] <= 0;
            end
            bias_FC <= 0;
        end
    end
end

always @(posedge clk) begin
	if (rst == 1) begin
		state <= IDLE;
		ptr_rn <= 0;
		ptr_bias <= 0;
		first_iter <= 1;

        cant_inputs = 0;
        iters_per_neuron = 0;
        modulo = 0;
        cant_neurons = 0;
        last = 0;
        of_offset = 0;

		for (int i = 0; i < INPUTS_MAC; i = i + 1) begin
			kernel_FC[i] = 0;
		end
		bias_FC = 0;
		struct_ready <= 0; 
	end
	else begin
		if (state == IDLE) begin
			struct_ready <= 0;
			if (next_layer == 1) begin
				if (first_iter == 1) begin
					first_iter <= 0;
				end
				else begin
					ptr_rn <= ptr_rn + 11;
				end
				state <= STATE_A;
			end
		end
		else if (state == STATE_A) begin
			cant_inputs <= {rn_buffer[ptr_rn + 1], rn_buffer[ptr_rn]}; 
			iters_per_neuron <= {rn_buffer[ptr_rn + 3], rn_buffer[ptr_rn + 2]}; 
			modulo <= rn_buffer[ptr_rn + 4]; 
			cant_neurons <= rn_buffer[ptr_rn + 5]; 
			last <= rn_buffer[ptr_rn + 6]; 
			of_offset <= {rn_buffer[ptr_rn + 8], rn_buffer[ptr_rn + 7]};  
			n <= rn_buffer[ptr_rn + 9];
			frac <= rn_buffer[ptr_rn + 10];

			struct_ready <= 1;
			state <= IDLE;
		end
	end
end


endmodule