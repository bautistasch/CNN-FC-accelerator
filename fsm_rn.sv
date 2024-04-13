module fsm_rn #(parameter ADDRESS_BITS = 12, parameter COLS_MAC = 4, parameter INPUTS_MAC = 6) (
	input wire clk,
	output reg rst,
	input wire start,
	output reg start_fc,
// ### package from rn_struct ###	
	input wire [7:0] last_stage,
	input wire [7:0] amount_channels,
	input wire [7:0] kernel_size,
	input wire [7:0] stride,
	input wire [7:0] if_size,
	input wire [7:0] kernel_size_2,
	input wire [15:0] ifsize_2,
	input wire [7:0] amount_filters,
	input wire [7:0] of_size,
	input wire [15:0] ofsize_2,
	input wire [15:0] of_offset,
	
	input wire [7:0] kernel [0:8],
	input wire [31:0] bias,
	input reg [7:0] n,
	input reg [7:0] frac,

	input wire struct_ready,
	
	output reg next,
	output reg next_channel,
	output reg next_filter,	
// ###############################	

// ### kernel weights to MAC array ###	
	output wire [7:0] kernel_weigths [0:8], 
	output reg write_kernel,
// ###################################	
	output wire [ADDRESS_BITS-1:0] of_base_out,  
// ############### Mem  ####################	
	input wire signed [31:0] macs_result [0:COLS_MAC-1],
	output reg en_w [0:COLS_MAC-1],

	output reg [7:0] if_data [0:INPUTS_MAC - 1],  // 6 filas 
	input wire [7:0] if_data_memory [0:INPUTS_MAC - 1],
	output reg [ADDRESS_BITS-1:0] if_address [0:INPUTS_MAC - 1],
	
	output reg [7:0] of_write [0:COLS_MAC-1],
	output reg [ADDRESS_BITS-1:0] of_w_address [0:COLS_MAC-1],

	input wire signed [7:0] of_read [0:COLS_MAC-1],
	output reg [ADDRESS_BITS-1:0] of_r_address [0:COLS_MAC-1]
// ############	
);

// #########################################
// ############ Constantes ################
// #########################################

parameter IDLE = 0;
parameter STATE_A = 1;
parameter STATE_B = 2;
parameter RUN = 3;
parameter STATE_D = 4;
parameter STATE_E = 5;
parameter SUBSTATE_E2 = 7;
parameter STATE_F = 6;
reg [3:0] state;
reg [3:0] substate;

// #########################################
// #########################################
// #########################################

reg [0:ADDRESS_BITS-1] if_base;
reg [0:ADDRESS_BITS-1] of_base;
reg [0:ADDRESS_BITS-1] if_address_next [0:INPUTS_MAC-1];
reg [0:ADDRESS_BITS-1] of_address_next [0:COLS_MAC-1];

assign of_base_out = of_base;

// #########################################
// ############ rn_struct ################## 
// #########################################
reg [7:0] reg_last_stage;
reg [7:0] reg_amount_channels;
reg [7:0] reg_kernel_size;
reg [7:0] reg_stride;
reg [7:0] reg_if_size;
reg [7:0] reg_kernel_size_2;
reg [15:0] reg_ifsize_2;
reg [7:0] reg_amount_filters;
reg [7:0] reg_of_size;
reg [15:0] reg_ofsize_2;
reg [15:0] reg_of_offset;

reg [7:0] reg_kernel [0:8];
reg signed [31:0] reg_bias;
reg [7:0] reg_n;
reg [7:0] reg_frac;
wire [7:0] n_out;
wire [7:0] frac_out;
wire signed [31:0] bias_out;

parameter LAGS_TIL_MAC_RES = 10;
reg [7:0] n_sr [0:LAGS_TIL_MAC_RES-1];
reg [7:0] frac_sr [0:LAGS_TIL_MAC_RES-1];
reg [31:0] bias_sr [0:LAGS_TIL_MAC_RES-1];

assign n_out = n_sr[LAGS_TIL_MAC_RES-1];
assign frac_out = frac_sr[LAGS_TIL_MAC_RES-1];
assign bias_out = bias_sr[LAGS_TIL_MAC_RES-1];
// #########################################
// #########################################
// #########################################

// #########################################
// ############ Counters #################
// #########################################
reg [7:0] col_counter; 
reg col_counter_en;
reg [7:0] channel_counter; 
reg channel_counter_en;
reg [7:0] filter_counter; 
reg filter_counter_en;

reg [7:0] b_counter;
reg [7:0] d_counter;
reg [7:0] e_counter;
reg [7:0] f_counter;
// #########################################
// #########################################
// #########################################


// #########################################
// ######## OF Register Control ############
// #########################################
parameter LAGS_TIL_OFW = 12;

reg [ADDRESS_BITS-1:0] of_address [0:COLS_MAC-1];
reg [ADDRESS_BITS-1:0] of_sr [0:COLS_MAC-1][0:LAGS_TIL_OFW-1];
reg en_w_sr [0:COLS_MAC-1][0:LAGS_TIL_OFW-1];

reg channel_is_first_sr [0:LAGS_TIL_OFW-1 - 2];
reg channel_is_last_sr [0:LAGS_TIL_OFW-1 - 1];


wire mux;
// #########################################
// #########################################
// #########################################

reg if_enable;

always @(posedge clk) begin
	if(rst == 1) begin
		if_enable <= 0;
	end
	else begin
		if(state == RUN) begin
			if_enable <= 1;
		end
		else begin
			if_enable <= 0;
		end
	end
end

wire col_counter_full;

reg collision;
reg aux_silence_1;
reg aux_silence_2;
reg aux_silence_3;

reg aux_silence_1_ff;
reg aux_silence_2_ff;
reg aux_silence_3_ff;

wire [3:0] silence_cols;
assign silence_cols[0] = 0;
assign silence_cols[1] = aux_silence_1_ff;
assign silence_cols[2] = aux_silence_2_ff;
assign silence_cols[3] = aux_silence_3_ff;

assign kernel_weigths = reg_kernel;

always @(*) begin
	if (if_enable == 1) begin
		if_data = if_data_memory;
	end
	else begin
		for (int i = 0; i < INPUTS_MAC; i++) begin
			if_data[i] = 0;
		end
	end
end

// #########################################
// ############# OF control ################
// #########################################
always @ (posedge clk) begin
	if (rst == 1) begin
		for (int i = 0; i < COLS_MAC; i++) begin
			for (int j = 0; j < LAGS_TIL_OFW; j++) begin
				of_sr[i][j] <= 0;
			end
		end
	end
	else begin
		if ((state != RUN) && (en_w_sr[0][0] == 1)) begin  
			for (int i = 0; i < COLS_MAC; i++) begin
				for (int j = 0; j < 3; j++) begin
					en_w_sr[i][j] <= 0; 
				end
			end	
			for (int i = 0; i < COLS_MAC; i++) begin
				for (int j = 3; j < LAGS_TIL_OFW; j++) begin
					en_w_sr[i][j] <= en_w_sr[i][j-1]; 
				end
			end	
		end
		else begin
			for (int i = 0; i < COLS_MAC; i++) begin
				en_w_sr[i][0] <= ((state == RUN) && ~silence_cols[i]) ? 1 : 0;
			end
			for (int i = 0; i < COLS_MAC; i++) begin
				for (int j = 1; j < LAGS_TIL_OFW; j++) begin
					en_w_sr[i][j] <= en_w_sr[i][j-1]; 
				end
			end
		end
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

always @(*) begin
	for (int i = 0; i < COLS_MAC; i++) begin
		of_r_address[i] = of_sr[i][LAGS_TIL_OFW-1 - 3];			
	end
end
// ################ n frac context #################

always @(posedge clk) begin
	if(rst == 1) begin
		for (int i = 0; i < LAGS_TIL_MAC_RES; i++) begin
			n_sr[i] <= 0;
			frac_sr[i] <= 0;
			bias_sr[i] <= 0;
		end
	end
	else begin
		n_sr[0] <= reg_n;
		frac_sr[0] <= reg_frac;
		bias_sr[0] <= reg_bias;
		for (int i = 1; i < LAGS_TIL_MAC_RES; i++) begin
			n_sr[i] <= n_sr[i-1];
			frac_sr[i] <= frac_sr[i-1];
			bias_sr[i] <= bias_sr[i-1];
		end
	end
end

// ################ Channel context ################
always @(posedge clk) begin
	if(rst == 1) begin
		for (int i = 0; i < LAGS_TIL_OFW-1 - 1; i = i + 1) begin
			channel_is_first_sr[i] <= 0;
		end
		for (int i = 0; i < LAGS_TIL_OFW-1; i++) begin
			channel_is_last_sr[i] <= 0;
		end
	end
	else begin
		channel_is_first_sr[0] <= (channel_counter == 0) && (state == RUN) ? 1 : 0;
		channel_is_last_sr[0] <= (channel_counter == (reg_amount_channels - 1)) && (state == RUN) ? 1 : 0;
		for (int i = 1; i < LAGS_TIL_OFW-1 - 1; i = i + 1) begin
			channel_is_first_sr[i] <= channel_is_first_sr[i-1];
		end
		for (int i = 1; i < LAGS_TIL_OFW-1; i = i + 1) begin
			channel_is_last_sr[i] <= channel_is_last_sr[i-1];
		end
	end
end

assign mux = channel_is_first_sr[LAGS_TIL_OFW-1 - 2];
// ##################################################

always @(*) begin
	for (int i = 0; i < COLS_MAC; i++) begin
		en_w[i] = en_w_sr[i][LAGS_TIL_OFW-1];
	end
end


reg signed [8:0] sum_of [0:COLS_MAC-1];
reg signed [7:0] latch_of_1 [0:COLS_MAC-1];
reg [7:0] latch_of_2 [0:COLS_MAC-1];

always @(*) begin
	for (int i = 0; i < COLS_MAC; i++) begin
		of_write[i] = latch_of_2[i];
	end
end

reg signed [31:0] aux [0:COLS_MAC];
reg signed [39:0] mul_res [0:COLS_MAC];
reg signed [8:0] z [0:COLS_MAC];

always @ (*) begin
	for (int i = 0; i < COLS_MAC; i++) begin
		if (mux == 0) begin
			sum_of[i] = z[i] + of_read[i];
		end
		else begin
			sum_of[i] = z[i] + z[COLS_MAC];
		end

		if (sum_of[i] > 127)  
			sum_of[i] = 127;
		else if (sum_of[i] < -128) 
			sum_of[i] = -128;
	end
end


always @(*) begin
	for (int i = 0; i < COLS_MAC; i++) begin
		aux[i] = 32'sd1 + (macs_result[i] >>> n_out);
		mul_res[i] = 40'sd1 + {aux[i], 8'sd0} * {32'sd0, frac_out};

		if ($signed(mul_res[i][39:16]) > 24'sd255)  
			z[i] = 9'sd255;
		else if ($signed(mul_res[i][39:16]) < -24'sd256 ) 
			z[i] = -9'sd256;
		else 
			z[i] = mul_res[i][24:16];	
	end

	aux[COLS_MAC] = 32'sd1 + (bias_out >>> n_out);
	mul_res[COLS_MAC] = 40'sd1 + {aux[COLS_MAC], 8'sd0} * {32'sd0, frac_out};

	if ($signed(mul_res[COLS_MAC][39:16]) > 24'sd255)  
		z[COLS_MAC] = 9'sd255;
	else if ($signed(mul_res[COLS_MAC][39:16]) < -24'sd256 ) 
		z[COLS_MAC] = -9'sd256;
	else 
		z[COLS_MAC] = mul_res[COLS_MAC][24:16];	
end

always @ (posedge clk) begin
	if (rst == 1) begin
		for (int i = 0; i < COLS_MAC; i++) begin
			latch_of_1[i] <= 0;
			latch_of_2[i] <= 0;
		end
	end
	else begin
		for (int i = 0; i < COLS_MAC; i++) begin
			latch_of_1[i] <= sum_of[i][7:0];
			if(channel_is_last_sr[LAGS_TIL_OFW-1 -1] == 1) begin
				latch_of_2[i] <= $signed(latch_of_1[i]) > 0 ? latch_of_1[i] : 0; // ReLU
			end
			else begin
				latch_of_2[i] <= latch_of_1[i];
			end
		end
	end
end

// #########################################
// #########################################
// #########################################


// #########################################
// #########################################
reg [ADDRESS_BITS-1:0] if_base_next_channel [0:INPUTS_MAC-1];

always @(*) begin
	for (int i = 0; i < INPUTS_MAC; i++) begin
		if_base_next_channel[i] = if_base + reg_ifsize_2*(channel_counter + 1) + i*reg_if_size;
	end
end

always @(*) begin
	if (state == STATE_D) begin
		for (int i = 0; i < INPUTS_MAC; i++) begin
			if( if_base_next_channel[i] == if_address[3] ) begin
				aux_silence_1 = 1;
				break;
			end
			else begin
				aux_silence_1 = 0;
			end
		end

		for (int i = 0; i < INPUTS_MAC; i++) begin
			if( if_base_next_channel[i] == if_address[4] ) begin
				aux_silence_2 = 1;
				break;
			end
			else begin
				aux_silence_2 = 0;
			end
		end

		for (int i = 0; i < INPUTS_MAC; i++) begin
			if( if_base_next_channel[i] == if_address[5] ) begin
				aux_silence_3 = 1;
				break;
			end
			else begin
				aux_silence_3 = 0;
			end
		end
	end
end


// #########################################
// #########################################
// #########################################


always @(posedge clk) begin
	if (rst == 1) begin
		state <= IDLE;
	end
	else begin
		case (state)
			IDLE: begin
				if (start == 1) begin
					state <= STATE_A;
					next <= 1;
				end
			end
			STATE_A: begin
				next <= 0;
				if (struct_ready == 1) begin
					state <= STATE_B;
					write_kernel <= 1;
					channel_counter_en <= 1;
					filter_counter_en <= 1;

					reg_last_stage <= last_stage;
					reg_amount_channels <= amount_channels;
					reg_kernel_size <= kernel_size;
					reg_stride <= stride;
					reg_if_size <= if_size;
					reg_kernel_size_2 <= kernel_size_2;
					reg_ifsize_2 <= ifsize_2;
					reg_amount_filters <= amount_filters;
					reg_of_size <= of_size;
					reg_ofsize_2 <= ofsize_2;
					reg_of_offset <= of_offset;	

					reg_kernel <= kernel;
					reg_bias <= bias;
					reg_n <= n;
					reg_frac <= frac;
				end
			end
			STATE_B: begin
				write_kernel <= 0;
				for (int i = 0; i < 6; i++) begin
					if_address[i] <= if_base + i*reg_if_size;
				end
				of_base <= if_base + of_offset;
				for (int i = 0; i < 4; i++) begin
					of_address[i] <= if_base + of_offset + i*reg_of_size;
				end

				col_counter_en <= 1;
				state <= RUN;
			end
			RUN: begin
				if (col_counter_full == 1) begin
					col_counter_en <= 0;
					state <= STATE_D;
				end
				else begin
					for (int i = 0; i < 6; i++) begin
						if_address[i] <= if_address_next[i];
					end
					for (int i = 0; i < 4; i++) begin
						of_address[i] <= of_address_next[i];
					end
				end
			end
			STATE_D: begin
				if (d_counter == 0) begin
					for (int i = 0; i < INPUTS_MAC; i++) begin
						if_address[i] <= if_address[i] + 3*reg_if_size + 1;
					end
					for (int i = 0; i < COLS_MAC; i++) begin
						of_address[i] <= of_address[i] + 3*reg_of_size - 1;
					end
					d_counter <= 1;
				end
				else if (d_counter == 1) begin
					collision = 0;
					for (int i = 0; i < INPUTS_MAC; i++) begin
						if( if_base_next_channel[i] == if_address[0] || 
							if_base_next_channel[i] == if_address[1] ||
							if_base_next_channel[i] == if_address[2] ) begin
							collision = 1;
							break;
						end
					end

					d_counter <= 0;
					if (collision == 1) begin
						aux_silence_1_ff <= 0;
						aux_silence_2_ff <= 0;
						aux_silence_3_ff <= 0;
						state <= STATE_E;
						channel_counter <= channel_counter + 1; 
					end
					else begin
						aux_silence_1_ff <= aux_silence_1;
						aux_silence_2_ff <= aux_silence_2;
						aux_silence_3_ff <= aux_silence_3;
						col_counter_en <= 1;
						state <= RUN;
					end
				end
			end
			STATE_E: begin
				if (e_counter == 0) begin
					if (channel_counter == reg_amount_channels) begin
						channel_counter <= 0;
						filter_counter <= filter_counter + 1;
						substate <= 0;
					end
					else begin
						next_channel <= 1; 
						substate <= SUBSTATE_E2;
					end
					e_counter <= 1;
				end
				if (e_counter == 1) begin 
					if (substate != SUBSTATE_E2) begin 
						if (filter_counter == reg_amount_filters) begin
							if (reg_last_stage == 1) begin
								state <= STATE_F;
							end
							else begin
								next <= 1;
								filter_counter <= 0; 

								e_counter <= 0;
								if_base <= of_base;
								state <= STATE_A;
							end
						end
						else begin
							next_filter <= 1;
							e_counter <= 2;
						end
					end
					else begin
						next_channel <= 0;
						for (int i = 0; i < 6; i++) begin
							if_address[i] <= if_base + i*reg_if_size + ifsize_2 * channel_counter;
						end
						for (int i = 0; i < 6; i++) begin
							of_address[i] <= of_base + i*reg_of_size + ofsize_2 * filter_counter;
						end
						e_counter <= 2;
					end
				end 
				if (e_counter == 2) begin
					if (substate != SUBSTATE_E2) begin
						for (int i = 0; i < 6; i++) begin
							if_address[i] <= if_base + i*reg_if_size;
						end
						for (int i = 0; i < 4; i++) begin
							of_address[i] <= of_base + i*reg_of_size + filter_counter * ofsize_2;
						end
						next_filter <= 0;
					end
					e_counter <= 3;
				end
				if (e_counter == 3) begin
					if (substate != SUBSTATE_E2) begin
						e_counter <= 4;
					end
					else begin
						if(struct_ready == 1) begin
							reg_kernel <= kernel;
							write_kernel <= 1;
						end
						e_counter <= 4;
					end
				end
				if (e_counter == 4) begin
					if (substate != SUBSTATE_E2) begin
						if(struct_ready == 1) begin
							reg_kernel <= kernel;
							reg_bias <= bias;
							reg_n <= n;
							reg_frac <= frac;
						end
						write_kernel <= 1;
						e_counter <= 5;
					end
					else begin
						write_kernel <= 0;
						e_counter <= 0;
						col_counter_en <= 1;
						state <= RUN;
					end
				end
				if (e_counter == 5) begin
					write_kernel <= 0;
					e_counter <= 0;
					col_counter_en <= 1;
					state <= RUN;
				end
			end 
			STATE_F: begin
				if(f_counter < 10) begin
					f_counter <= f_counter + 1;
				end
				else begin
					start_fc <= 1;
				end
			end
		endcase
	end 
end
// #########################################
// #### next add if y of ####
// #########################################

always @(*) begin
	for (int i = 0; i < 6; i++) begin
		if_address_next[i] = if_address[i] + 1;
	end
	for (int i = 0; i < 4; i++) begin
		of_address_next[i] = of_address[i] + 1;
	end
end

// #########################################
// #########################################
// #########################################


// #########################################
//  counter
// #########################################

assign col_counter_full = col_counter == reg_if_size ? 1 : 0;
always @(posedge clk) begin
	if (col_counter_en == 1) begin
		col_counter <= col_counter + 1;
	end
	else 
		col_counter <= 1;
end

// #########################################
// #########################################
// #########################################

initial begin
	rst = 0;
	if_base = 0;
	state = IDLE;
	next = 0;
	next_channel = 0;
	next_filter = 0;	
	write_kernel = 0;

	aux_silence_1 = 0;
	aux_silence_2 = 0;
	aux_silence_3 = 0;

	aux_silence_1_ff = 0;
	aux_silence_2_ff = 0;
	aux_silence_3_ff = 0;

	filter_counter_en = 0;
	filter_counter = 0;
	channel_counter = 0;
	channel_counter_en = 0;
	substate = 0;

	e_counter = 0;
	b_counter = 0;
	d_counter = 0;
	f_counter = 0;
	start_fc = 0;
	for (int i = 0; i < COLS_MAC; i++) begin
		for (int j = 0; j < LAGS_TIL_OFW; j++) begin
			en_w_sr[i][j] = 0; 
		end	
	end


	for (int i = 0; i < LAGS_TIL_OFW-1 - 1; i++) begin
		channel_is_first_sr[i] = 0; 
	end

	for (int i = 0; i < LAGS_TIL_OFW-1; i++) begin
		channel_is_last_sr[i] = 0;
	end

	for (int i = 0; i < INPUTS_MAC; i++) begin
		if_data[i] = 0;
		if_address[i] = 0;
	end

	for (int i = 0; i < COLS_MAC; i++) begin
		of_write[i] = 0;
		of_w_address[i] = 0;
		of_r_address[i] = 0;
	end

	for (int i = 0; i < COLS_MAC; i++) begin
		for (int j = 0; j < LAGS_TIL_OFW; j++) begin
			of_sr[i][j] = 0;
		end
	end

	collision = 0;

end
endmodule
