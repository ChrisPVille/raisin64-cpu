module pipeline_tb();

    reg clk, rst_n;
    reg[63:0] imem_data;
    reg imem_data_valid;

    wire imem_addr_valid;
    wire[63:0] imem_addr;

    pipeline my_pipeline(
        .clk(clk),
        .rst_n(rst_n),
        .imem_addr(imem_addr),
        .imem_data(imem_data),
        .imem_data_valid(imem_data_valid),
        .imem_addr_valid(imem_addr_valid)
        );

    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    //initial begin
    //    $dumpfile("pipeline.vcd");
    //    $dumpvars;
    //end

    initial
    begin
        rst_n = 0;
        imem_data = 64'h0; //ADD R0, R0, R0 (NOP)
        imem_data_valid = 1;

        #30 rst_n = 1;

        //#3000 $finish;
    end

endmodule
