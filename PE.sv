module PE #(parameter TOTAL_WEIGHTS = 3)
(
	input wire signed [7:0] ifmap_in,
	input wire signed [31:0] partial_sum_in,
	input wire signed [7:0] weights_in [0:TOTAL_WEIGHTS-1],
	input wire clk,
	input wire rst,
	input wire write_kernel,
	output wire signed [31:0] output_sum
);

reg signed [7:0] weight [0:TOTAL_WEIGHTS-1];
reg signed [7:0] ifmap [0:TOTAL_WEIGHTS-1];
reg signed [32:0] mul_res [0:TOTAL_WEIGHTS-1];
reg signed [31:0] pip_stg1 [0:2];
reg signed [31:0] pip_stg2 [0:1];
reg signed [31:0] pip_stg3;
reg signed [31:0] pip_stg4;
reg signed [32:0] sum_1;
reg signed [32:0] sum_2;
reg signed [32:0] sum_3;

initial begin
	for (int i = 0; i < TOTAL_WEIGHTS; i = i + 1) begin
		weight[i] <= 0;
		ifmap[i] <= 0;
	end
	pip_stg1[0] <= 0;
	pip_stg1[1] <= 0;
	pip_stg1[2] <= 0;
	pip_stg2[0] <= 0;
	pip_stg2[1] <= 0;
	pip_stg3 <= 0;
	pip_stg4 <= 0;
end

// reset
always @(posedge clk) begin
	if (rst == 1) begin 
		for (int i = 0; i < TOTAL_WEIGHTS; i = i + 1) begin
			weight[i] <= 0;
			ifmap[i] <= 0;
		end
		pip_stg1[0] <= 0;
		pip_stg1[1] <= 0;
		pip_stg1[2] <= 0;
		pip_stg2[0] <= 0;
		pip_stg2[1] <= 0;
		pip_stg3 <= 0;
		pip_stg4 <= 0;
	end
end

// pusheo de weights
always @(posedge clk) begin
	if (write_kernel == 1) begin
		for (int i = 0; i < TOTAL_WEIGHTS; i++) begin
			weight[TOTAL_WEIGHTS-1 - i] <= weights_in[i];
		end
	end
end

// pusheo de ifmap 
always @(posedge clk) begin
	ifmap[0] <= ifmap_in;
	for (int i = 0; i < TOTAL_WEIGHTS-1; i++) begin
		ifmap[i+1] <= ifmap[i];
	end
end

// producto. Async
always @(*) begin
	for (int i = 0; i < TOTAL_WEIGHTS; i = i + 1) begin 
		mul_res[i] = weight[i] * ifmap[i];
		if (mul_res[i] > 33'sd2147483647)  
			mul_res[i] = 33'sd2147483647;
		else if (mul_res[i] < -33'sd2147483648 ) 
			mul_res[i] = -33'sd2147483648;
	end
end

// pipelining 
always @(posedge clk) begin
	for (int i = 0; i < TOTAL_WEIGHTS; i = i + 1) begin 
		pip_stg1[i] <= mul_res[i][31:0];
	end
	pip_stg2[1] <= pip_stg1[2];
	pip_stg2[0] <= sum_1[31:0];
	pip_stg3 <= sum_2[31:0];
	pip_stg4 <= sum_3[31:0];
end

// Async sum 1
always @(*) begin
	sum_1 = pip_stg1[0] + pip_stg1[1]; 
    if (sum_1 > 33'sd2147483647)  
        sum_1 = 33'sd2147483647;
    else if (sum_1 < -33'sd2147483648 ) 
        sum_1 = -33'sd2147483648;

	sum_2 = pip_stg2[0] + pip_stg2[1];
    if (sum_2 > 33'sd2147483647)  
        sum_2 = 33'sd2147483647;
    else if (sum_2 < -33'sd2147483648 ) 
        sum_2 = -33'sd2147483648;

	sum_3 = pip_stg3 + partial_sum_in;
    if (sum_3 > 33'sd2147483647)  
        sum_3 = 33'sd2147483647;
    else if (sum_3 < -33'sd2147483648 ) 
        sum_3 = -33'sd2147483648;
end

assign output_sum = pip_stg4;

endmodule
