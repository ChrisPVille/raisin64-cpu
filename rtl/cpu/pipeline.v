//Raisin64 - Pipeline

module pipeline(
    //# {{clocks|Clocking}}
    input clk,
    input rst_n,

    //# {{data|Instruction Memory Bus}}
    output[63:0] imem_addr,
    input[63:0] imem_data,

    //# {{control|Instruction Memory Bus Control}}
    input imem_data_valid,
    output imem_addr_valid,

    //# {{data|Data Memory Bus}}
    output[63:0] dmem_addr,
    output[63:0] dmem_dout,
    input[63:0] dmem_din,

    //# {{control|Data Memory Bus Control}}
    input dmem_cycle_complete,
    output dmem_rstrobe,
    output dmem_wstrobe
    );

    wire will_issue;

    //////////  FETCH    //////////
    wire[63:0] fe_inst;

    fetch fetch1(
        .clk(clk),
        .rst_n(rst_n),
        .imem_addr(imem_addr),
        .imem_data(imem_data),
        .imem_data_valid(imem_data_valid),
        .imem_addr_valid(imem_addr_valid),
        .instData(fe_inst),
        .stall(~will_issue)
        );

    //////////  DECODE   //////////

    wire de_type;
    wire[2:0] de_unit;
    wire[1:0] de_op;
    wire[5:0] de_rd_rn;
    wire[5:0] de_rd2_rn;
    wire[5:0] de_rs1_rn;
    wire[5:0] de_rs2_rn;
    wire[63:0] de_imm_data;

    wire[5:0] de_r1_rn;
    wire[5:0] de_r2_rn;

    decode decode1(
        .clk(clk), .rst_n(rst_n),
        .instIn(fe_inst),
        .type(de_type),
        .unit(de_unit),
        .op(de_op),
        .rs1_rn(de_rs1_rn), .rs2_rn(de_rs2_rn),
        .rd_rn(de_rd_rn), .rd2_rn(de_rd2_rn),
        .imm_data(de_imm_data),
        .r1_rn(de_r1_rn), .r2_rn(de_r2_rn),
        .stall(~will_issue)
        );

    ////////// REG FILE  //////////
    //Concurrent with Schedule phase

    wire[63:0] rf_writeback;
    wire[63:0] rf_data1;
    wire[63:0] rf_data2;
    wire[5:0] rf_writeback_rn;

    //Register file selected by the scheduler, registered in the execute stage
    //and written to during commit.
    regfile regfile1(
        .clk(clk), .rst_n(rst_n), .w_data(rf_writeback), .r1_data(rf_data1),
        .r2_data(rf_data2), .r1_rn(de_r1_rn), .r2_rn(de_r2_rn),
        .w_rn(rf_writeback_rn), .w_en(|rf_writeback_rn)
        );

    ////////// SCHEDULE  //////////
    //Concurrent with Register File

    wire sc_alu1_en;
    wire sc_alu2_en;
    wire sc_advint_en;
    wire sc_memunit_en;
    wire sc_branch_en;

    wire sc_alu1_busy;
    wire sc_alu2_busy;
    wire sc_advint_busy;
    wire sc_memunit_busy;
    wire sc_branch_busy;

    wire[5:0] sc_rd_rn;
    wire[5:0] sc_rd2_rn;

    schedule schedule1(
        .clk(clk), .rst_n(rst_n),
        .type(de_type), .unit(de_unit),
        .r1_in_rn(de_r1_rn), .r2_in_rn(de_r2_rn),
        .rd_in_rn(de_rd_rn), .rd2_in_rn(de_rd2_rn),
        .will_issue(will_issue),
        .rd_out_rn(sc_rd_rn), .rd2_out_rn(sc_rd2_rn),

        .reg1_finished(rf_writeback_rn), .reg2_finished(6'h0),

        .alu1_en(sc_alu1_en), .alu2_en(sc_alu2_en), .advint_en(sc_advint_en),
        .memunit_en(sc_memunit_en), .branch_en(sc_branch_en),

        .alu1_busy(sc_alu1_busy), .alu2_busy(sc_alu2_busy),
        .advint_busy(sc_advint_busy), .memunit_busy(sc_memunit_busy),
        .branch_busy(sc_branch_busy)
        );

    //Delay the relevant decode data used by execution through the schedule phase
    reg sc_type;
    reg[2:0] sc_unit;
    reg[1:0] sc_op;
    reg[63:0] sc_imm_data;

    always @(posedge clk or negedge rst_n)
    begin
        if(~rst_n) begin
            sc_type <= 0;
            sc_unit <= 3'h0;
            sc_op <= 2'h0;
            sc_imm_data <= 64'h0;
        end else begin
            sc_type <= de_type;
            sc_unit <= de_unit;
            sc_op <= de_op;
            sc_imm_data <= de_imm_data;
        end
    end

    //////////  EXECUTE  //////////

    wire[63:0] ex_alu1_result;
    wire[63:0] ex_alu2_result;
    wire[63:0] ex_advint_result;
    wire[63:0] ex_advint_result2;
    wire[63:0] ex_memunit_result;

    wire[5:0] ex_alu1_rd_rn;
    wire[5:0] ex_alu2_rd_rn;
    wire[5:0] ex_advint_rd_rn;
    wire[5:0] ex_advint_rd2_rn;
    wire[5:0] ex_memunit_rd_rn;

    wire ex_alu1_valid;
    wire ex_alu2_valid;
    wire ex_advint_valid;
    wire ex_memunit_valid;

    wire ex_alu1_stall;
    wire ex_alu2_stall;
    wire ex_advint_stall;
    wire ex_memunit_stall;
    wire ex_branch_stall;

    ex_alu ex_alu1(
        .clk(clk), .rst_n(rst_n), .in1(rf_data1), .in2(sc_type ? sc_imm_data : rf_data2), .out(ex_alu1_result),
        .ex_enable(sc_alu1_en), .ex_busy(sc_alu1_busy), .rd_in_rn(sc_rd_rn), .unit(sc_unit),
        .op(sc_op), .rd_out_rn(ex_alu1_rd_rn), .valid(ex_alu1_valid), .stall(ex_alu1_stall)
        );

    ex_alu ex_alu2(
        .clk(clk), .rst_n(rst_n), .in1(rf_data1), .in2(sc_type ? sc_imm_data : rf_data2), .out(ex_alu2_result),
        .ex_enable(sc_alu2_en), .ex_busy(sc_alu2_busy), .rd_in_rn(sc_rd_rn), .unit(sc_unit),
        .op(sc_op), .rd_out_rn(ex_alu2_rd_rn), .valid(ex_alu2_valid), .stall(ex_alu2_stall)
        );

    ex_memory ex_memory1(
        .clk(clk), .rst_n(rst_n),
        .dmem_din(dmem_din), .dmem_dout(dmem_dout), .dmem_addr(dmem_addr),
        .dmem_cycle_complete(dmem_cycle_complete),
        .dmem_rstrobe(dmem_rstrobe), .dmem_wstrobe(dmem_wstrobe),
        .base(rf_data1), .data(rf_data2), .offset(sc_imm_data[31:0]),
        .out(ex_memunit_result),
        .ex_enable(sc_memunit_en), .ex_busy(sc_memunit_busy),
        .rd_in_rn(sc_rd_rn), .unit(sc_unit), .op(sc_op),
        .rd_out_rn(ex_memunit_rd_rn), .valid(ex_memunit_valid),
        .stall(ex_memunit_stall)
        );

    //////////  COMMIT   //////////

    commit commit1(
        .clk(clk), .rst_n(rst_n),
        .alu1_result(ex_alu1_result), .alu2_result(ex_alu2_result),
        .advint_result(ex_advint_result), .advint_result2(ex_advint_result2),
        .memunit_result(ex_memunit_result),
        .alu1_rn(ex_alu1_rd_rn), .alu2_rn(ex_alu2_rd_rn),
        .advint_rn(ex_advint_rd_rn), .advint_rn2(ex_advint_rd2_rn),
        .memunit_rn(ex_memunit_rd_rn),
        .alu1_valid(ex_alu1_valid), .alu2_valid(ex_alu2_valid),
        .advint_valid(ex_advint_valid),
        .memunit_valid(ex_memunit_valid),
        .alu1_stall(ex_alu1_stall), .alu2_stall(ex_alu2_stall),
        .advint_stall(ex_advint_stall),
        .memunit_stall(ex_memunit_stall),
        .branch_stall(ex_branch_stall),
        .write_data(rf_writeback), .write_rn(rf_writeback_rn)
        );

endmodule
