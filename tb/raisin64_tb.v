module raisin64_tb();

    reg clk, rst_n;

    raisin64 raisin64_1(
        .clk(clk),
        .rst_n(rst_n),
        );

    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    initial begin
        $dumpfile("raisin64.vcd");
        $dumpvars;
    end

    initial
    begin
        rst_n = 0;

        #30 rst_n = 1;

        #3000 $finish;
    end

endmodule
