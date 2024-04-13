module PE_FC_array_tb;

    parameter INPUTS_MAC = 6;
    parameter COLS_MAC = 4;
    reg clk;
    reg rst;
    reg write_kernel;
    reg [7:0] inputs_mac [0:5]; // 6 rows
    reg [7:0] weights [0:5];
    wire [31:0] output_mac;


    PE_FC_array dut (
        .clk(clk),
        .rst(rst),
        .write_kernel(write_kernel),
        .inputs_mac(inputs_mac),
        .weights(weights),
        .output_mac(output_mac)  
    );


    always #5 clk = ~clk;

    initial begin
        inputs_mac[0] = 0;
        inputs_mac[1] = 0;
        inputs_mac[2] = 0;
        inputs_mac[3] = 0;
        inputs_mac[4] = 0;
        inputs_mac[5] = 0;

        rst = 1;
        clk = 0;
        write_kernel = 0;
        #10;
        rst = 0;
        write_kernel = 127;
        weights[0] = 127;
        weights[1] = 127;
        weights[2] = 127;
        weights[3] = 127;
        weights[4] = 127;
        weights[5] = 127;
        #10;
        write_kernel = 0;

        inputs_mac[0] = 127;
        inputs_mac[1] = 127;
        inputs_mac[2] = 127;
        inputs_mac[3] = 127;
        inputs_mac[4] = 127;
        inputs_mac[5] = 127;

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