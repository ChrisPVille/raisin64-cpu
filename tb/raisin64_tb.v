`timescale 1ns/1ns

module raisin64_tb();

    reg clk, rst_n;
    wire[15:0] LED;
    reg[15:0] SW;

    defparam cpu.imem.INIT_FILE = "/home/christopher/git/raisin64-cpu/support/imem.hex";
    defparam cpu.dmem.INIT_FILE = "/home/christopher/git/raisin64-cpu/support/dmem.hex";

    //////////  CPU  //////////
    wire[63:0] mem_from_cpu;
    wire[63:0] mem_to_cpu;
    wire[63:0] mem_addr;
    wire mem_addr_valid;
    wire mem_from_cpu_write;
    wire mem_to_cpu_ready;

    raisin64 cpu(
        .clk(clk),
        .rst_n(rst_n),
        .mem_din(mem_to_cpu),
        .mem_dout(mem_from_cpu),
        .mem_addr(mem_addr),
        .mem_addr_valid(mem_addr_valid),
        .mem_dout_write(mem_from_cpu_write),
        .mem_din_ready(mem_to_cpu_ready),
        .jtag_tck(1'b0),
        .jtag_tms(1'b0),
        .jtag_tdi(1'b0),
        .jtag_trst(1'b0)
        );

    //////////  IO  //////////
    wire led_en, sw_en, vga_en;
    memory_map memory_map_external(
        .addr(mem_addr_valid ? mem_addr : 64'h0),
        .led(led_en),
        .sw(sw_en),
        .vga(vga_en)
        );

    //As noted in raisin64.v because our IO architecture will need to be completely
    //re-written with the introduction of caches, we only support 64-bit aligned
    //access to IO space for now.
    reg[15:0] led_reg;
    always @(posedge clk or negedge rst_n) begin
        if(~rst_n) led_reg <= 16'h0;
        else if(led_en & mem_addr_valid & mem_from_cpu_write) led_reg <= mem_from_cpu;
    end

    assign LED = led_reg;


    //SW uses a small synchronizer
    reg[15:0] sw_pre0, sw_pre1;
    always @(posedge clk or negedge rst_n) begin
        if(~rst_n) begin
            sw_pre0 <= 16'h0;
            sw_pre1 <= 16'h0;
        end else begin
            sw_pre0 <= sw_pre1;
            sw_pre1 <= SW;
        end
    end

    //Data selection
    assign mem_to_cpu_ready = mem_addr_valid;
    assign mem_to_cpu = sw_en ? sw_pre0 :
                        64'h0;

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
        SW = 16'h1234;

        #15 rst_n = 1;

        #1000 $finish;
    end

endmodule
