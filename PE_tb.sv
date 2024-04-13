`timescale 1ns/10ps

module PE_tb;

    parameter TOTAL_WEIGHTS = 3;

    reg [7:0] ifmap_in;
    reg [7:0] partial_sum_in;
    reg [7:0] weights_in [0:TOTAL_WEIGHTS-1];
    reg clk;
    reg rst;
    reg write_kernel;
    wire [7:0] output_sum;

    PE #(.TOTAL_WEIGHTS(3)) dut(
        .ifmap_in(ifmap_in),
        .partial_sum_in(partial_sum_in),
        .weights_in(weights_in),
        .clk(clk),
        .rst(rst),
        .write_kernel(write_kernel),
        .output_sum(output_sum) 
    );

    always #5 clk = ~clk;

    initial begin
        rst = 0;
        clk = 0;
        partial_sum_in = 0;
        #5;

        weights_in[0] = 1;
        weights_in[1] = 2;
        weights_in[2] = 3;
        write_kernel = 1;

        #10;

        write_kernel = 0;
        ifmap_in = 1;

        #10;

        ifmap_in = 2;

        #10;

        ifmap_in = 3;

        #10;
        ifmap_in = 0;

        #10;
        #10;
        #10;
        #10;
        #10;
        #10;
        #10;
        #10;
        #10;
        #10;
        #10;

        $finish;
    end

endmodule 