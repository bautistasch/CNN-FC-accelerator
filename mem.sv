module mem #(parameter ADDRESS_BITS = 6, parameter COLS_MAC = 4, parameter INPUTS_MAC = 6) (
	input wire [7:0] of_write [0:COLS_MAC-1],
	input wire [ADDRESS_BITS-1:0] of_w_address [0:COLS_MAC-1],

	output reg [7:0] of_read [0:COLS_MAC-1],
	input wire [ADDRESS_BITS-1:0] of_r_address [0:COLS_MAC-1],

	output reg [7:0] ifmap_r [0:INPUTS_MAC-1],
	input wire [ADDRESS_BITS-1:0] if_address [0:INPUTS_MAC-1], 

	input wire en_w [0:COLS_MAC-1],
	input wire clk, 
	input wire rst
);

reg [7:0] memory [0:(1<< ADDRESS_BITS) - 1];

initial begin
    $readmemh("ram_init.mem", memory);
end


always @(posedge clk) begin
	if (rst == 1) begin
		for(int i = 0; i < 1<<ADDRESS_BITS; i++) begin
			memory[i] = 0;
		end
		for(int i = 0; i < INPUTS_MAC; i++) begin
			ifmap_r[i] = 0;
		end	
		for(int i = 0; i < COLS_MAC; i++) begin
			of_read[i] = 0;
		end
	end
	else begin 
		for (int i = 0; i < COLS_MAC; i++) begin
			of_read[i] <= memory[of_r_address[i]];
		end
		for (int i = 0; i < INPUTS_MAC; i++) begin
			ifmap_r[i] <= memory[if_address[i]];
		end			
		for (int i = 0; i < COLS_MAC; i++) begin
			if (en_w[i] == 1) begin
				memory[of_w_address[i]] <= of_write[i];
			end
		end	
	end
end

endmodule