`timescale 1ns/1ns

module raisin64_tb();

    reg clk, rst_n;
    defparam cpu.imem.INIT_FILE = "/home/christopher/git/raisin64-nexys4ddr/cpu/support/imem.hex";

    raisin64 cpu (
        .clk(clk),
        .rst_n(rst_n)
        );

    initial begin
        clk = 1;
        forever #5 clk = ~clk;
    end

    initial begin
        $dumpfile("raisin64.vcd");
        $dumpvars;
    end

    initial
    begin
        rst_n = 0;

        #15 rst_n = 1;

        #1000 $finish;
    end

endmodule
