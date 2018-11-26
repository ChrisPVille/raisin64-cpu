`timescale 1ns/1ns

module raisin64_tb();

    reg clk, rst_n;
    defparam cpu.imem.INIT_FILE = "/home/christopher/git/raisin64-cpu/support/imem.hex";
    defparam cpu.dmem.INIT_FILE = "/home/christopher/git/raisin64-cpu/support/dmem.hex";

    raisin64 cpu (
        .clk(clk),
        .rst_n(rst_n),
        .jtag_tck(1'b0),
        .jtag_tms(1'b0),
        .jtag_tdi(1'b0),
        .jtag_trst(1'b0)
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
