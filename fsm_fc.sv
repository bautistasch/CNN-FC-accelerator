module fsm_fc #(parameter ADDRESS_BITS = 12, parameter COLS_MAC = 4, parameter INPUTS_MAC = 6) (
	input wire clk,
	input reg rst,
	input wire start,

// ### package from rn_struct ###	
    input wire [15:0] cant_inputs,
    input wire [15:0] iters_per_neuron,
    input wire [7:0] modulo,
    input wire [7:0] cant_neurons,
    input wire [7:0] last,
    input wire [15:0] of_offset,
    input wire [7:0] n,
    input wire [7:0] frac,

	input wire struct_ready,
	
	output reg next_layer,
    output reg next_neuron,
    output wire get_weight,

	input wire [7:0] kernel [0:INPUTS_MAC-1],
	input wire signed [31:0] bias,    

// ###################################	

// ### kernel weights to MAC array ###	
	output reg [7:0] weights2arr [0:INPUTS_MAC-1], 
	output reg write_kernel,
// ###################################	
	
    input wire [0:ADDRESS_BITS-1] if_base_in,

// ############### Mem ####################	
	input wire signed [31:0] macs_result,
	output reg en_w [0:COLS_MAC-1],

	output reg [7:0] if_data [0:INPUTS_MAC - 1],  
	input wire [7:0] if_data_memory [0:INPUTS_MAC - 1],
	output reg [ADDRESS_BITS-1:0] if_address [0:INPUTS_MAC - 1],
	
	output reg [7:0] of_write [0:COLS_MAC-1],
	output reg [ADDRESS_BITS-1:0] of_w_address [0:COLS_MAC-1]
// ############	
);


parameter IDLE = 0;
parameter STATE_A = 1;
parameter STATE_B = 2;
parameter RUN = 3;
parameter STATE_C = 4;
parameter WAIT_STATE = 6;
parameter STATE_FINISH = 5; 

reg [3:0] state;

reg [0:ADDRESS_BITS-1] if_base;
reg [0:ADDRESS_BITS-1] of_base;
reg [0:ADDRESS_BITS-1] if_address_next [0:INPUTS_MAC-1];


// #########################
// ####### rn_struct #######
reg [15:0] reg_cant_inputs;
reg [15:0] reg_iters_per_neuron;
reg [7:0] reg_modulo;
reg [7:0] reg_cant_neurons;
reg [7:0] reg_last;
reg [15:0] reg_of_offset;
reg [7:0] reg_n;
reg [7:0] reg_frac;

// #########################

reg signed [32:0] sum_of;
reg signed [31:0] latch_of_1;
reg [7:0] latch_of_2;

always @(*) begin
	of_write[0] = latch_of_2;
    for (int i = 1; i < COLS_MAC-1; i++) begin
        of_write[i] = 0;
    end
end
// #########################################
// ############ Contadores #################
// #########################################
reg [15:0] counter; 
reg counter_en;
wire counter_full;

reg [7:0] neurons_counter;
reg [3:0] wait_counter;
// #########################################
// #########################################
// #########################################

always @(*) begin
    for (int i = i; i < INPUTS_MAC; i++) begin
        if_data[i] = if_data_memory[i];
    end
end

assign get_weight = state == RUN ? 1 : 0;

// #########################################
// ######## OF Register Control ############
// #########################################
parameter LAGS_TIL_OFW = 11;
parameter BIAS_LAGS = 8;
parameter RELU_LAGS = 10;
reg [ADDRESS_BITS-1:0] of_address [0:COLS_MAC-1];
reg [ADDRESS_BITS-1:0] of_sr [0:COLS_MAC-1][0:LAGS_TIL_OFW-1];
reg en_w_sr [0:LAGS_TIL_OFW-1];


reg [7:0] last_sr [0:RELU_LAGS-1];
reg [7:0] n_sr [0:RELU_LAGS-1];
reg signed [7:0] frac_sr [0:RELU_LAGS-1];

wire signed [31:0] bias_sum;
reg [31:0] bias_sr [0:BIAS_LAGS-1];
assign bias_sum = bias_sr[BIAS_LAGS-1];


wire mux;

// #########################################
// #########################################
// #########################################

// #########################################
// ############# OF control ################
// #########################################
always @(posedge clk) begin
    if (rst == 1) begin
        for (int i = i; i < COLS_MAC; i++) begin
            for (int j = 0; j < LAGS_TIL_OFW; j++) begin
                of_sr[i][j] <= 0;
            end
        end
    end
    else begin
        for (int i = 0; i < COLS_MAC; i++) begin
            of_sr[i][0] <= of_address[i];
        end
        for (int i = 0; i < COLS_MAC; i++) begin
            for (int j = 1; j < LAGS_TIL_OFW; j++) begin
                of_sr[i][j] <= of_sr[i][j-1];
            end
        end
    end
end

always @(*) begin
	for (int i = 0; i < COLS_MAC; i++) begin
		of_w_address[i] = of_sr[i][LAGS_TIL_OFW-1];			
	end
end

// #########################################
// #########################################
// #########################################

always @(posedge clk) begin
    if (rst == 1) begin
        for (int i = 0; i < LAGS_TIL_OFW; i++) begin
            en_w_sr[i] <= 0;
        end
    end
    else begin
        en_w_sr[0] <= (state == RUN) ? 1 : 0;
        for (int i = 1; i < LAGS_TIL_OFW; i++) begin
            en_w_sr[i] <= en_w_sr[i-1];
        end
    end
end

always @(posedge clk) begin
    if (rst == 1) begin
        for (int i = 0; i < RELU_LAGS; i++) begin
            n_sr[i] <= 0;
            frac_sr[i] <= 0;
            last_sr[i] <= 0;
        end
    end
    else begin
        n_sr[0] <= reg_n;
        frac_sr[0] <= reg_frac;
        last_sr[0] <= reg_last;
        for (int i = 1; i < RELU_LAGS; i++) begin
            n_sr[i] <= n_sr[i-1];
            frac_sr[i] <= frac_sr[i-1];
            last_sr[i] <= last_sr[i-1];
        end
    end
end

always @(posedge clk) begin
    if (rst == 1) begin
        for (int i = 0; i < BIAS_LAGS; i++) begin
            bias_sr[i] <= 0;
        end
    end
    else begin
        bias_sr[0] <= bias;
        for (int i = 1; i < BIAS_LAGS; i++) begin
            bias_sr[i] <= bias_sr[i-1];
        end
    end
end


always @(*) begin
	en_w[0] = en_w_sr[LAGS_TIL_OFW-1];
	for (int i = 1; i < COLS_MAC; i++) begin
        en_w[i] = 0;
	end
end

assign mux = (en_w_sr[9] == 0) && (en_w_sr[8] == 1) ? 1 : 0;  

always @ (*) begin
    if (mux == 0) begin
        sum_of = macs_result + latch_of_1;
    end 
    else begin
        sum_of = macs_result + bias_sum;
    end

    if (sum_of > 33'sd2147483647)  
        sum_of = 33'sd2147483647;
    else if (sum_of < -33'sd2147483648) 
        sum_of = -33'sd2147483648;
end

reg signed [31:0] aux;
reg signed [39:0] mul_res;
reg signed [7:0] z;

always @(*) begin
    aux = 32'sd1 + (latch_of_1 >>> n_sr[RELU_LAGS-1]);
    mul_res = {aux, 8'sd0} * {32'sd0, frac_sr[RELU_LAGS-1]};

    if ($signed(mul_res[39:16]) > 24'sd127)  
        z = 8'd127;
    else if ($signed(mul_res[39:16]) < -24'sd128 ) 
        z = -8'd128;
    else 
	    z = mul_res[23:16];
end

always @ (posedge clk) begin
	if (rst == 1) begin
        latch_of_1 <= 0;
        latch_of_2 <= 0;
	end
	else begin  
        latch_of_1 <= sum_of[31:0];
        if((en_w_sr[LAGS_TIL_OFW-1 - 1] == 1) && (en_w_sr[LAGS_TIL_OFW-1 - 2] == 0) && (last_sr[RELU_LAGS-1] == 0)) begin 
            latch_of_2 <= $signed(z) > 0 ? z : 0; // ReLU
        end
        else begin
            latch_of_2 <= z;  
        end
	end
end

// #########################################
// #########################################
// #########################################

always @(posedge clk) begin
    if (rst == 1) begin
    end
    else begin
        case (state)
            IDLE: begin
                if (start == 1) begin
                    next_layer <= 1;
                    if_base <= if_base_in;
                    state <= STATE_A;
                end   
            end
            STATE_A: begin
                next_layer <= 0;
                if (struct_ready == 1) begin
                    reg_cant_inputs <= cant_inputs;
                    reg_iters_per_neuron <= iters_per_neuron;
                    reg_modulo <= modulo;
                    reg_cant_neurons <= cant_neurons;
                    reg_last <= last;
                    reg_of_offset <= of_offset;
                    reg_n <= n;
                    reg_frac <= frac;

                    state <= STATE_B;
                end
            end
            STATE_B: begin
				for (int i = 0; i < INPUTS_MAC; i++) begin
					if_address[i] <= if_base + i;
				end
				of_base <= if_base + reg_of_offset;
				for (int i = 0; i < COLS_MAC; i++) begin
					of_address[i] <= if_base + reg_of_offset + i;
				end
				counter_en <= 1;
                write_kernel <= 1;
				state <= RUN;
            end
            RUN: begin
				if (counter_full == 1) begin
					counter_en <= 0;
                    next_neuron <= 1;
                    neurons_counter <= neurons_counter + 1;
					state <= STATE_C;
				end
				else begin
					for (int i = 0; i < 6; i++) begin
						if_address[i] <= if_address_next[i];
					end
				end
            end
            STATE_C: begin
                next_neuron <= 0;
                if (neurons_counter == reg_cant_neurons) begin
                    neurons_counter <= 0;
                    if (reg_last == 1) begin
                        state <= STATE_FINISH;
                    end
                    else begin
                        wait_counter <= 0;
                        state <= WAIT_STATE;
                    end
                end
                else begin
                    for (int i = 0; i < 6; i++) begin
                        if_address[i] <= if_base + i;
                    end
                    for (int i = 0; i < 4; i++) begin
                        of_address[i] <= of_address[i] + i + 1;
                    end
                    counter_en <= 1;
                    state <= RUN;
                end
            end
            WAIT_STATE: begin
                if(wait_counter == 5) begin
                    next_layer <= 1;
                    if_base <= of_base;
                    state <= STATE_A;
                end
                else begin
                    wait_counter <= wait_counter + 1;
                end
            end
            STATE_FINISH: begin
            end
        endcase
    end

end

// #########################################
// ########## Weights control  ############
// #########################################


always @(*) begin
    if ((en_w_sr[0] == 1) && (state != RUN)) begin
        for (int i = 0; i < INPUTS_MAC; i++) begin
            weights2arr[i] = (INPUTS_MAC-i) > reg_modulo ? kernel[i] : 0;
        end
    end
    else begin
        weights2arr = kernel;
    end
end

// #########################################
// #### next if address   ####
// #########################################

always @(*) begin
	for (int i = 0; i < 6; i++) begin
		if_address_next[i] = if_address[i] + 6;
	end
end

// #########################################
// ############# Counter ##################
// #########################################
assign counter_full = counter == reg_iters_per_neuron ? 1 : 0;
always @(posedge clk) begin
	if (counter_en == 1) begin
		counter <= counter + 1;
	end
	else 
		counter <= 1;
end


initial begin
    state = IDLE;
    neurons_counter = 0;
    latch_of_1 = 0;
    wait_counter = 0;

    for (int i = 0; i < LAGS_TIL_OFW; i++) begin
        en_w_sr[i] = 0;
    end
    for (int i = 0; i < BIAS_LAGS; i++) begin
        bias_sr[i] = 0;
    end   

end


endmodule