module raisin64_tb();

    reg clk, rst_n;
    defparam cpu.imem.INIT_FILE = "/home/christopher/git/raisin64-cpu/support/imem.hex";

    raisin64 cpu (
        .clk(clk),
        .rst_n(rst_n)
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
