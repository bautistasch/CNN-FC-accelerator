module PE_FC_array (
    input clk,
    input rst,
    input write_kernel,
    input wire [7:0] inputs_mac [0:5], // 6 rows
    input wire [7:0] weights [0:5],
    output wire [31:0] output_mac
);


wire [31:0] partial_sum [0:4]; 

reg [7:0] latch1 [0:4];
reg [7:0] latch2 [0:3];
reg [7:0] latch3 [0:2];
reg [7:0] latch4 [0:1];
reg [7:0] latch5;

reg [7:0] Wlatch1 [0:4];
reg [7:0] Wlatch2 [0:3];
reg [7:0] Wlatch3 [0:2];
reg [7:0] Wlatch4 [0:1];
reg [7:0] Wlatch5;

always @(posedge clk) begin
	if (rst == 1) begin
		latch1[0] <= 0;
		latch1[1] <= 0;
		latch1[2] <= 0;
		latch1[3] <= 0;
		latch1[4] <= 0;

		latch2[0] <= 0;
		latch2[1] <= 0;
		latch2[2] <= 0;
		latch2[3] <= 0;

		latch3[0] <= 0;
		latch3[1] <= 0;
		latch3[2] <= 0;

		latch4[0] <= 0;
		latch4[1] <= 0;

		latch5 <= 0;

// W
		Wlatch1[0] <= 0;
		Wlatch1[1] <= 0;
		Wlatch1[2] <= 0;
		Wlatch1[3] <= 0;
		Wlatch1[4] <= 0;

		Wlatch2[0] <= 0;
		Wlatch2[1] <= 0;
		Wlatch2[2] <= 0;
		Wlatch2[3] <= 0;

		Wlatch3[0] <= 0;
		Wlatch3[1] <= 0;
		Wlatch3[2] <= 0;

		Wlatch4[0] <= 0;
		Wlatch4[1] <= 0;

		Wlatch5 <= 0;		
	end
	else begin
		latch1[0] <= inputs_mac[0];
		latch1[1] <= latch1[0];
		latch1[2] <= latch1[1];
		latch1[3] <= latch1[2];
		latch1[4] <= latch1[3];

		latch2[0] <= inputs_mac[1];
		latch2[1] <= latch2[0];
		latch2[2] <= latch2[1];
		latch2[3] <= latch2[2];

		latch3[0] <= inputs_mac[2];
		latch3[1] <= latch3[0];
		latch3[2] <= latch3[1];

		latch4[0] <= inputs_mac[3];
		latch4[1] <= latch4[0];

		latch5 <= inputs_mac[4];

// W

		Wlatch1[0] <= weights[0];
		Wlatch1[1] <= Wlatch1[0];
		Wlatch1[2] <= Wlatch1[1];
		Wlatch1[3] <= Wlatch1[2];
		Wlatch1[4] <= Wlatch1[3];

		Wlatch2[0] <= weights[1];
		Wlatch2[1] <= Wlatch2[0];
		Wlatch2[2] <= Wlatch2[1];
		Wlatch2[3] <= Wlatch2[2];

		Wlatch3[0] <= weights[2];
		Wlatch3[1] <= Wlatch3[0];
		Wlatch3[2] <= Wlatch3[1];

		Wlatch4[0] <= weights[3];
		Wlatch4[1] <= Wlatch4[0];

		Wlatch5 <= weights[4];
	end
end


PE_FC PE_FC_1(
	.ifmap_in(latch1[4]),
	.partial_sum_in(partial_sum[0]),
	.weight_in(Wlatch1[4]),
	.clk(clk),
	.rst(rst),
	.write_kernel(write_kernel),
	.output_sum(output_mac)
);

PE_FC PE_FC_2(
	.ifmap_in(latch2[3]),
	.partial_sum_in(partial_sum[1]),
	.weight_in(Wlatch2[3]),
	.clk(clk),
	.rst(rst),
	.write_kernel(write_kernel),
	.output_sum(partial_sum[0])
);

PE_FC PE_FC_3(
	.ifmap_in(latch3[2]),
	.partial_sum_in(partial_sum[2]),
	.weight_in(Wlatch3[2]),
	.clk(clk),
	.rst(rst),
	.write_kernel(write_kernel),
	.output_sum(partial_sum[1])
);

PE_FC PE_FC_4(
	.ifmap_in(latch4[1]),
	.partial_sum_in(partial_sum[3]),
	.weight_in(Wlatch4[1]),
	.clk(clk),
	.rst(rst),
	.write_kernel(write_kernel),
	.output_sum(partial_sum[2])
);

PE_FC PE_FC_5(
	.ifmap_in(latch5),
	.partial_sum_in(partial_sum[4]),
	.weight_in(Wlatch5),
	.clk(clk),
	.rst(rst),
	.write_kernel(write_kernel),
	.output_sum(partial_sum[3])
);

PE_FC PE_FC_6(
	.ifmap_in(inputs_mac[5]),
	.partial_sum_in(32'b0),
	.weight_in(weights[5]),
	.clk(clk),
	.rst(rst),
	.write_kernel(write_kernel),
	.output_sum(partial_sum[4])
);
endmodule