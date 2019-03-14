/*
 * Raisin64 CPU
 */

module raisin64 (
    //# {{clocks|Clocking}}
    input clk,
    input clk_100mhz, //For DDR2 memory
    input rst_n,

    //# {{data|Memory Interface}}
    input[63:0] mem_din,
    output[63:0] mem_dout,
    output[63:0] mem_addr,

    //# {{control|Control Signals}}
    output mem_addr_valid,
    output mem_dout_write,
    input mem_din_ready,

    //# {{data|DDR2 Memory Interface}}
    inout[15:0] ddr2_dq,
    inout[1:0] ddr2_dqs_n,
    inout[1:0] ddr2_dqs_p,
    output[12:0] ddr2_addr,
    output[2:0] ddr2_ba,
    output ddr2_ras_n,
    output ddr2_cas_n,
    output ddr2_we_n,
    output[0:0] ddr2_ck_p,
    output[0:0] ddr2_ck_n,
    output[0:0] ddr2_cke,
    output[0:0] ddr2_cs_n,
    output[1:0] ddr2_dm,
    output[0:0] ddr2_odt,

    //# {{debug|Debug Signals}}
    input jtag_tck,
    input jtag_tms,
    input jtag_tdi,
    input jtag_trst,
    output jtag_tdo
    );

    parameter IMEM_INIT = "";
    parameter DMEM_INIT = "";

    //// Debug Signals ////
    wire dbg_resetn_cpu, dbg_halt_cpu;
    wire cpu_rst_n;
    assign cpu_rst_n = rst_n & dbg_resetn_cpu;

    wire[63:0] dbg_imem_addr;
    wire[63:0] dbg_imem_to_ram;
    wire dbg_imem_ce;
    wire dbg_imem_we;

    wire[63:0] dbg_dmem_addr;
    wire[63:0] dbg_dmem_to_ram;
    wire dbg_dmem_rstrobe;
    wire dbg_dmem_wstrobe;


    //////////  Instruction RAM  //////////
    wire[63:0] effective_imem_addr;
    wire[63:0] effective_imem_data_to_cpu;

    reg imem_data_ready;
    wire imem_addr_valid;
    wire[63:0] imem_addr;
    wire[63:0] imem_data;

    assign effective_imem_addr        = dbg_halt_cpu ? dbg_imem_addr : imem_addr;
    assign effective_imem_data_to_cpu = dbg_halt_cpu ? 64'h0 : imem_data;

    always @(posedge clk or negedge rst_n) begin
        if(~rst_n) imem_data_ready <= 0;
        else imem_data_ready <= imem_addr_valid;
    end

    ram #(
        .NUM_BYTES(2*1024),
        .INIT_FILE(IMEM_INIT)
        ) imem (
        .clk(clk),
        .we(dbg_imem_we), .cs(1'b1),
        .write_width(2'h0),
        .addr(effective_imem_addr),
        .data_in(dbg_imem_to_ram),
        .data_out(imem_data)
        );


    //////////  Data RAM  //////////
    wire[63:0] effective_dmem_addr;
    wire[63:0] effective_dmem_to_ram;

    wire[63:0] dmem_addr;
    wire[63:0] dmem_to_ram;
    wire[63:0] dmem_to_cpu;
    wire[63:0] dmem_from_ram;
    wire[1:0] dmem_write_width;
    reg dmem_cycle_complete;
    wire dmem_rstrobe;
    wire dmem_wstrobe;

    wire io_space;

    assign effective_dmem_addr        = dbg_halt_cpu ? dbg_dmem_addr : dmem_addr;
    assign effective_dmem_to_ram      = dbg_halt_cpu ? dbg_dmem_to_ram : dmem_to_ram;

    //TODO For now, the external memory bus is just for data memory.  When the time
    //comes for caches, this will change to the unified external memory bus.
    assign dmem_to_cpu                = io_space ? mem_din : dmem_from_ram;
    assign mem_dout                   = effective_dmem_to_ram;
    assign mem_addr                   = effective_dmem_addr;
    assign mem_addr_valid             = 1;
    assign mem_dout_write             = dbg_halt_cpu ? dbg_dmem_wstrobe : dmem_wstrobe;

    //Because the memory interface will change dramatically in the next revision, there
    //is no reason to create special logic to handle misaligned accesses into data space
    //in case an IO unit requires it (the ram modules handle this condition internally).
    //Instead we simply state misaligned IO access it is unsupported (for now).
    always @(*) begin
        if((dmem_rstrobe|dmem_wstrobe) & io_space & |dmem_write_width & ~clk) begin
            $display("Unaligned data IO access not supported in this revision");
            $finish;
        end
    end

    memory_map memory_map_internal(
        .addr(mem_addr),
        .io(io_space)
        );

    wire mem_transaction_complete;

    always @(posedge clk or negedge cpu_rst_n)
    begin
        if(~cpu_rst_n) dmem_cycle_complete <= 0;
        else if(io_space & mem_din_ready) dmem_cycle_complete <= 1;
//        else if(dmem_rstrobe) dmem_cycle_complete <= 1;
//        else if(dmem_wstrobe) dmem_cycle_complete <= 1;
        else if(mem_transaction_complete) dmem_cycle_complete <= 1;
        else dmem_cycle_complete <= 0;
    end

//    ram #(
//        .NUM_BYTES(512),
//        .INIT_FILE(DMEM_INIT)
//        ) dmem (
//        .clk(clk),
//        .we(~io_space & (dmem_wstrobe|dbg_dmem_we)), .cs(~io_space & (dmem_wstrobe|dmem_rstrobe|dbg_dmem_ce)),
//        .write_width(dmem_write_width),
//        .addr(effective_dmem_addr),
//        .data_in(effective_dmem_to_ram),
//        .data_out(dmem_from_ram)
//        );

    ////////////////  Physical RAM ////////////////

    physical_ram ddr(
        .clk_100mhz(clk_100mhz),
        .rst_n(rst_n),

        .ddr2_addr(ddr2_addr),
        .ddr2_ba(ddr2_ba),
        .ddr2_cas_n(ddr2_cas_n),
        .ddr2_ck_n(ddr2_ck_n),
        .ddr2_ck_p(ddr2_ck_p),
        .ddr2_cke(ddr2_cke),
        .ddr2_ras_n(ddr2_ras_n),
        .ddr2_we_n(ddr2_we_n),
        .ddr2_dq(ddr2_dq),
        .ddr2_dqs_n(ddr2_dqs_n),
        .ddr2_dqs_p(ddr2_dqs_p),
        .ddr2_cs_n(ddr2_cs_n),
        .ddr2_dm(ddr2_dm),
        .ddr2_odt(ddr2_odt),

        .cpu_clk(clk),
        .addr(effective_dmem_addr[26:0]),
        .width(dmem_write_width),
        .data_in({64'h54545454_54545454, effective_dmem_to_ram}),
        .data_out(dmem_from_ram),
        .rstrobe(~io_space & (dmem_rstrobe|dbg_dmem_rstrobe)),
        .wstrobe(~io_space & (dmem_wstrobe|dbg_dmem_wstrobe)),
        .transaction_complete(mem_transaction_complete)
        );

    //////////  Raisin64 Execution Core  //////////
    pipeline pipeline1(
        .clk(clk),
        .rst_n(cpu_rst_n),
        .imem_addr(imem_addr),
        .imem_data(effective_imem_data_to_cpu),
        .imem_data_valid(imem_data_ready),
        .imem_addr_valid(imem_addr_valid),
        .dmem_addr(dmem_addr), .dmem_dout(dmem_to_ram),
        .dmem_din(dmem_to_cpu),
        .dmem_cycle_complete(dmem_cycle_complete & ~dmem_rstrobe & ~dmem_wstrobe),
        .dmem_write_width(dmem_write_width),
        .dmem_rstrobe(dmem_rstrobe),
        .dmem_wstrobe(dmem_wstrobe)
        );


    //////////  JTAG Module  //////////
    debug_control debug_if(
        .jtag_tck(jtag_tck),
        .jtag_tms(jtag_tms),
        .jtag_tdo(jtag_tdo),
        .jtag_tdi(jtag_tdi),
        .jtag_trst(jtag_trst),
        .cpu_clk(clk),
        .sys_rstn(rst_n),
        .cpu_imem_addr(dbg_imem_addr),
        .cpu_debug_to_imem_data(dbg_imem_to_ram),
        .cpu_imem_to_debug_data(imem_data),
        .cpu_imem_we(dbg_imem_we),
        .cpu_imem_ce(dbg_imem_ce),
        .cpu_dmem_addr(dbg_dmem_addr),
        .cpu_debug_to_dmem_data(dbg_dmem_to_ram),
        .cpu_imem_to_debug_data_ready(dbg_imem_ce & ~dbg_imem_we),
        .cpu_dmem_to_debug_data_ready(dmem_cycle_complete),
        .cpu_dmem_to_debug_data(dmem_to_cpu),
        .cpu_dmem_wstrobe(dbg_dmem_wstrobe),
        .cpu_dmem_rstrobe(dbg_dmem_rstrobe),
        .cpu_resetn_cpu(dbg_resetn_cpu),
        .cpu_halt_cpu(dbg_halt_cpu)
        );

endmodule
