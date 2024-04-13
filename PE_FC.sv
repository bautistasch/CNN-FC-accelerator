module PE_FC (
	input wire signed [7:0] ifmap_in,
	input wire signed [31:0] partial_sum_in,
	input wire signed [7:0] weight_in,
	input wire clk,
	input wire rst,
	input wire write_kernel,
	output wire signed [31:0] output_sum
);

reg signed [7:0] inLatch;
reg signed [7:0] weightLatch;
reg signed [31:0] mulLatch;
reg signed [31:0] outLatch;

reg signed [32:0] mul_res;
reg signed [32:0] add_res;

initial begin 
    inLatch = 0;
    weightLatch = 0;
    mulLatch = 0;
    outLatch = 0;     

    mul_res = 0;
    add_res = 0;
end


always @(posedge clk) begin
    if (rst == 1) begin
        inLatch <= 0;
        weightLatch <= 0;
        mulLatch <= 0;
        outLatch <= 0; 

        mul_res <= 0;
        add_res <= 0;
    end
    else begin
        inLatch <= ifmap_in;
        weightLatch <= weight_in;
        mulLatch <= mul_res[31:0];
        outLatch <= add_res[31:0];

        if(write_kernel == 1) 
            weightLatch <= weight_in;
    end
end
always @ (*) begin
    mul_res = weightLatch * inLatch;
    if (mul_res > 33'sd2147483647)  
        mul_res = 33'sd2147483647;
    else if (mul_res < -33'sd2147483648 ) 
        mul_res = -33'sd2147483648;
end

always @ (*) begin
	add_res = mulLatch + partial_sum_in;
    if (add_res > 33'sd2147483647)  
        add_res = 33'sd2147483647;
    else if (add_res < -33'sd2147483648 ) 
        add_res = -33'sd2147483648;
end

assign output_sum = outLatch;

endmodule 