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

    wire[63:0] dmem_addr;
    wire[63:0] dmem_to_ram;
    wire[63:0] dmem_from_ram;
    reg dmem_cycle_complete;
    wire dmem_rstrobe;
    wire dmem_wstrobe;

    pipeline pipeline1(
        .clk(clk),
        .rst_n(rst_n),
        .imem_addr(imem_addr),
        .imem_data(imem_data),
        .imem_data_valid(imem_data_ready),
        .imem_addr_valid(imem_addr_valid),
        .dmem_addr(dmem_addr), .dmem_dout(dmem_to_ram),
        .dmem_din(dmem_from_ram),
        .dmem_cycle_complete(dmem_cycle_complete),
        .dmem_rstrobe(dmem_rstrobe),
        .dmem_wstrobe(dmem_wstrobe)
        );

    assign imem_data_ready = 1;

    ram #(
        .NUM_BYTES(256)
        ) imem (
        .clk(clk),
        .we(1'b0), .cs(imem_addr_valid),
        .addr(imem_addr),
        .data_in(64'h0),
        .data_out(imem_data)
        );

    always @(posedge clk or negedge rst_n)
    begin
        if(~rst_n) dmem_cycle_complete <= 0;
        else if(dmem_rstrobe) dmem_cycle_complete <= 1;
        else if(dmem_wstrobe) dmem_cycle_complete <= 1;
        else dmem_cycle_complete <= 0;
    end

    ram #(
        .NUM_BYTES(256)
        ) dmem (
        .clk(clk),
        .we(dmem_wstrobe), .cs(dmem_wstrobe|dmem_rstrobe),
        .addr(dmem_addr),
        .data_in(dmem_to_ram),
        .data_out(dmem_from_ram)
        );

endmodule
