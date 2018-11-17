/*
 * Raisin64 CPU
 */

module raisin64 (
    //# {{clocks|Clocking}}
    input clk,
    input rst_n

    //# {{data|Memory Interface}}
    //input[63:0] mem_din,
    //output[63:0] mem_dout,
    //output[63:0] mem_addr,

    //# {{control|Control Signals}}
    //output mem_addr_valid,
    //output mem_dout_write
    //input mem_din_ready,

    //# {{debug|Debug Signals}}
    //input halt
    );

    wire imem_data_ready;
    wire imem_addr_valid;
    wire[63:0] imem_addr;
    wire[63:0] imem_data;

    pipeline my_pipeline(
        .clk(clk),
        .rst_n(rst_n),
        .imem_addr(imem_addr),
        .imem_data(imem_data),
        .imem_data_valid(imem_data_ready),
        .imem_addr_valid(imem_addr_valid)
        );

    assign imem_data_ready = 1;

    ram #(
        .NUM_BYTES(64),
        .INIT_FILE("~/git/raisin64-cpu/support/imem.hex")
        ) imem (
        .clk(clk),
        .we(0), .cs(imem_addr_valid),
        .addr(imem_addr),
        .data_in(64'h0),
        .data_out(imem_data)
        );

endmodule
