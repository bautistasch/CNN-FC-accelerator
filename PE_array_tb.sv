module PE_array_tb;

    parameter INPUTS_MAC = 6;
    parameter COLS_MAC = 4;
    reg clk;
    reg rst;
    reg write_kernel;
    reg [7:0] inputs_mac[0:INPUTS_MAC-1];
    reg [7:0] weights [0:8];
    wire [7:0] outputs_mac[0:COLS_MAC-1];


    PE_array dut (
        .clk(clk),
        .rst(rst),
        .write_kernel(write_kernel),
        .inputs_mac(inputs_mac),
        .weights(weights),
        .outputs_mac(outputs_mac)  
    );

    always #5 clk = ~clk;

    initial begin
        rst = 0;
        clk = 0;
        write_kernel = 0;
        rst = 1;

        inputs_mac[0] = 0;
        inputs_mac[1] = 0;
        inputs_mac[2] = 0;
        inputs_mac[3] = 0;
        inputs_mac[4] = 0;
        inputs_mac[5] = 0;
        
        #10;
        rst = 0;
        #10;

        weights[0] = 1;
        weights[1] = 2;
        weights[2] = 3;
        weights[3] = 1;
        weights[4] = 2;
        weights[5] = 3;
        weights[6] = 1;
        weights[7] = 2;
        weights[8] = 3;

        write_kernel = 1;

        #10;

        write_kernel = 0;

        #10;

        inputs_mac[0] = 0;
        inputs_mac[1] = 0;
        inputs_mac[2] = 0;
        inputs_mac[3] = 0;
        inputs_mac[4] = 0;
        inputs_mac[5] = 0;

        #10;

        inputs_mac[0] = 1;
        inputs_mac[1] = 1;
        inputs_mac[2] = 1;
        inputs_mac[3] = 1;
        inputs_mac[4] = 1;
        inputs_mac[5] = 1;

        #10;

        inputs_mac[0] = 2;
        inputs_mac[1] = 2;
        inputs_mac[2] = 2;
        inputs_mac[3] = 2;
        inputs_mac[4] = 2;
        inputs_mac[5] = 2;    

        #10;

        inputs_mac[0] = 3;
        inputs_mac[1] = 3;
        inputs_mac[2] = 3;
        inputs_mac[3] = 3;
        inputs_mac[4] = 3;
        inputs_mac[5] = 3;   

        #10;

        inputs_mac[0] = 0;
        inputs_mac[1] = 0;
        inputs_mac[2] = 0;
        inputs_mac[3] = 0;
        inputs_mac[4] = 0;
        inputs_mac[5] = 0;   

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