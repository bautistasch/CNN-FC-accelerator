module PE_array #(parameter COLS_MAC = 4, parameter INPUTS_MAC = 6) (
    input clk,
    input rst,
    input write_kernel,
    input wire [7:0] inputs_mac[0:INPUTS_MAC-1],
    input wire [7:0] weights [0:8],
    output wire [31:0] outputs_mac[0:COLS_MAC-1]
);

reg [7:0] pe00_latch [0:1];
reg [7:0] pe10_latch;

reg [7:0] pe01_latch [0:1];
reg [7:0] pe11_latch;

reg [7:0] pe02_latch [0:1];
reg [7:0] pe12_latch;

reg [7:0] pe03_latch [0:1];
reg [7:0] pe13_latch;

wire [31:0] partial_sum [0:1][0:3];

initial begin

    pe00_latch[0] <= 0;
    pe00_latch[1] <= 0;
    pe10_latch <= 0;

    pe01_latch[0] <= 0;
    pe01_latch[1] <= 0;
    pe11_latch <= 0;

    pe02_latch[0] <= 0;
    pe02_latch[1] <= 0;
    pe12_latch <= 0;

    pe03_latch[0] <= 0;
    pe03_latch[1] <= 0;
    pe13_latch <= 0;

end


always @(posedge clk) begin
    if (rst == 1) begin
        pe00_latch[0] <= 0;
        pe00_latch[1] <= 0;
        pe10_latch <= 0;

        pe01_latch[0] <= 0;
        pe01_latch[1] <= 0;
        pe11_latch <= 0;

        pe02_latch[0] <= 0;
        pe02_latch[1] <= 0;
        pe12_latch <= 0;

        pe03_latch[0] <= 0;
        pe03_latch[1] <= 0;
        pe13_latch <= 0;
    end
    else begin
        pe00_latch[0] <= inputs_mac[0];
        pe00_latch[1] <= pe00_latch[0];
        pe10_latch <= inputs_mac[1];

        pe01_latch[0] <= inputs_mac[1];
        pe01_latch[1] <= pe01_latch[0];
        pe11_latch <= inputs_mac[2];

        pe02_latch[0] <= inputs_mac[2];
        pe02_latch[1] <= pe02_latch[0];
        pe12_latch <= inputs_mac[3];

        pe03_latch[0] <= inputs_mac[3];
        pe03_latch[1] <= pe03_latch[0];
        pe13_latch <= inputs_mac[4];
    end
end


PE PE00 (.ifmap_in(pe00_latch[1]), .partial_sum_in(partial_sum[0][0]), .weights_in(weights[0:2]), .clk(clk), .rst(rst), .write_kernel(write_kernel), .output_sum(outputs_mac[0]));
PE PE10 (.ifmap_in(pe10_latch), .partial_sum_in(partial_sum[1][0]), .weights_in(weights[3:5]), .clk(clk), .rst(rst), .write_kernel(write_kernel), .output_sum(partial_sum[0][0]));
PE PE20 (.ifmap_in(inputs_mac[2]), .partial_sum_in(32'b0), .weights_in(weights[6:8]), .clk(clk), .rst(rst), .write_kernel(write_kernel), .output_sum(partial_sum[1][0]));

PE PE01 (.ifmap_in(pe01_latch[1]), .partial_sum_in(partial_sum[0][1]), .weights_in(weights[0:2]), .clk(clk), .rst(rst), .write_kernel(write_kernel), .output_sum(outputs_mac[1]));
PE PE11 (.ifmap_in(pe11_latch), .partial_sum_in(partial_sum[1][1]), .weights_in(weights[3:5]), .clk(clk), .rst(rst), .write_kernel(write_kernel), .output_sum(partial_sum[0][1]));
PE PE21 (.ifmap_in(inputs_mac[3]), .partial_sum_in(32'b0), .weights_in(weights[6:8]), .clk(clk), .rst(rst), .write_kernel(write_kernel), .output_sum(partial_sum[1][1]));

PE PE02 (.ifmap_in(pe02_latch[1]), .partial_sum_in(partial_sum[0][2]), .weights_in(weights[0:2]), .clk(clk), .rst(rst), .write_kernel(write_kernel), .output_sum(outputs_mac[2]));
PE PE12 (.ifmap_in(pe12_latch), .partial_sum_in(partial_sum[1][2]), .weights_in(weights[3:5]), .clk(clk), .rst(rst), .write_kernel(write_kernel), .output_sum(partial_sum[0][2]));
PE PE22 (.ifmap_in(inputs_mac[4]), .partial_sum_in(32'b0), .weights_in(weights[6:8]), .clk(clk), .rst(rst), .write_kernel(write_kernel), .output_sum(partial_sum[1][2]));

PE PE03 (.ifmap_in(pe03_latch[1]), .partial_sum_in(partial_sum[0][3]), .weights_in(weights[0:2]), .clk(clk), .rst(rst), .write_kernel(write_kernel), .output_sum(outputs_mac[3]));
PE PE13 (.ifmap_in(pe13_latch), .partial_sum_in(partial_sum[1][3]), .weights_in(weights[3:5]), .clk(clk), .rst(rst), .write_kernel(write_kernel), .output_sum(partial_sum[0][3]));
PE PE23 (.ifmap_in(inputs_mac[5]), .partial_sum_in(32'b0), .weights_in(weights[6:8]), .clk(clk), .rst(rst), .write_kernel(write_kernel), .output_sum(partial_sum[1][3]));

endmodule