module rn_struct (
	input wire clk,
	input wire rst,

	output reg [7:0] last_stage, // 0
	output reg [7:0] amount_channels, // 8
	output reg [7:0] kernel_size, // 16
	output reg [7:0] stride, // 24
	output reg [7:0] if_size, // 32
	output reg [7:0] kernel_size_2, // 40
	output reg [15:0] ifsize_2, // 48
	output reg [7:0] amount_filters, // 64
	output reg [7:0] of_size, // 72
	output reg [15:0] ofsize_2, // 80
	output reg [15:0] of_offset, // 96
								// 112

	output reg [7:0] kernel [0:8],
    output reg [31:0] bias,
	output reg [7:0] n,
	output reg [7:0] frac,

	output reg struct_ready,  
							
	input wire next,
	input wire next_channel,
	input wire next_filter
);

parameter SIZE_BUFFER = 20; 
parameter WEIGHTS_AMOUNT = 4096; 
parameter BIAS_AMOUNT = 4096; 
parameter IDLE = 0;
parameter STATE_A = 1;
parameter STATE_B = 2;
parameter ADDRESS_BITS = 11;

reg [7:0] state;

reg [7:0] rn_buffer [0:SIZE_BUFFER * 112 - 1];
reg [7:0] kernel_buffer [0:WEIGHTS_AMOUNT - 1];
reg [31:0] bias_buffer [0:BIAS_AMOUNT - 1];
reg [7:0] n_frac_buffer [0:BIAS_AMOUNT*2 - 1];

reg [ADDRESS_BITS-1:0] ptr_rn;
reg [ADDRESS_BITS-1:0] ptr_kernel;
reg [ADDRESS_BITS-1:0] ptr_bias;
reg [ADDRESS_BITS-1:0] ptr_n_frac;

reg first_iter;

initial begin

	$readmemh("rn_bufferCNN_init.mem", rn_buffer);
	$readmemh("kernel_bufferCNN_init.mem", kernel_buffer);
	$readmemh("bias_bufferCNN_init.mem", bias_buffer);
	$readmemh("n_frac_bufferCNN_init.mem", n_frac_buffer);

	state = IDLE;

	ptr_rn = 0;
	ptr_kernel = 0;
	ptr_bias = 0;
	ptr_n_frac = 0;
	first_iter = 1;

	last_stage = 0; 
	amount_channels = 0; 
	kernel_size = 0; 
	stride = 0; 
	if_size = 0; 
	kernel_size_2 = 0; 
	ifsize_2 = 0; 
	amount_filters = 0; 
	of_size = 0; 
	ofsize_2 = 0; 
	of_offset = 0;

	for (int i = 0; i < 9; i = i + 1) begin
		kernel[i] = 0;
	end
    bias = 0;
	n = 0;
	frac = 0;
	struct_ready = 0;
end


always @(posedge clk) begin
	if (rst == 1) begin
		state <= IDLE;
		ptr_rn <= 0;
		ptr_kernel <= 0;
		ptr_bias <= 0;
		ptr_n_frac <= 0;
		first_iter <= 1;
		last_stage = 0; 
		amount_channels = 0; 
		kernel_size = 0; 
		stride = 0; 
		if_size = 0; 
		kernel_size_2 = 0; 
		ifsize_2 = 0; 
		amount_filters = 0; 
		of_size = 0; 
		ofsize_2 = 0; 
		of_offset = 0;

		for (int i = 0; i < 9; i = i + 1) begin
			kernel[i] = 0;
		end
		bias = 0;
		struct_ready <= 0; 
	end
	else begin
		if (state == IDLE) begin
			struct_ready <= 0;
			if (next == 1) begin
				if (first_iter == 1) begin
					ptr_rn <= ptr_rn;
					ptr_kernel <= ptr_kernel;
					first_iter <= 0;
					ptr_bias <= 0;
					ptr_n_frac <= 0;
				end
				else begin
					ptr_rn <= ptr_rn + 14;
					ptr_kernel <= ptr_kernel + 9;
					ptr_bias <= ptr_bias + 1;
					ptr_n_frac <= ptr_n_frac + 2;
				end
				state <= STATE_A;
			end
			else if (next_channel == 1) begin
				ptr_kernel <= ptr_kernel + 9;
				state <= STATE_A;
			end 
			else if (next_filter == 1) begin
				ptr_kernel <= ptr_kernel + 9;
				ptr_bias <= ptr_bias + 1; 
				ptr_n_frac <= ptr_n_frac + 2;
				state <= STATE_A;
			end
		end
		else if (state == STATE_A) begin

			kernel <= kernel_buffer[ptr_kernel+: 9];
			bias <= bias_buffer[ptr_bias];
			n <= n_frac_buffer[ptr_n_frac];
			frac <=	n_frac_buffer[ptr_n_frac + 1];

			last_stage <= rn_buffer[ptr_rn]; 
			amount_channels <= rn_buffer[ptr_rn + 1]; 
			kernel_size <= rn_buffer[ptr_rn + 2]; 
			stride <= rn_buffer[ptr_rn + 3]; 
			if_size <= rn_buffer[ptr_rn + 4]; 
			kernel_size_2 <= rn_buffer[ptr_rn + 5]; 
			ifsize_2 <= {rn_buffer[ptr_rn + 7], rn_buffer[ptr_rn + 6]}; 
			amount_filters <= rn_buffer[ptr_rn + 8];
			of_size <= rn_buffer[ptr_rn + 9];
			ofsize_2 <= {rn_buffer[ptr_rn + 11], rn_buffer[ptr_rn + 10]};  
			of_offset <= {rn_buffer[ptr_rn + 13], rn_buffer[ptr_rn + 12]};  

			struct_ready <= 1;
			state <= IDLE;
		end
	end
end


endmodule