//Raisin64 - Pipeline

module pipeline(
    //# {{clocks|Clocking}}
    input clk,
    input rst_n,

    //# {{data|Instruction Memory Bus}}
    input[63:0] imem_addr,
    input[63:0] imem_data,

    //# {{control|Instruction Memory Bus Control}}
    input imem_data_valid,
    output imem_addr_valid
    );

    //////////  FETCH    //////////
    wire[63:0] fe_inst;
    wire fe_advance16;
    wire fe_advance32;
    wire fe_advance64;

    fetch fetch1(
        .clk(clk),
        .rst_n(rst_n),
        .imem_addr(imem_addr),
        .imem_data(imem_data),
        .imem_data_valid(imem_data_valid),
        .imem_addr_valid(imem_addr_valid),
        .instData(fe_inst),
        .advance16(fe_advance16),
        .advance32(fe_advance32),
        .advance64(fe_advance64)
    );

    //////////  DECODE   //////////

    wire de_type;
    wire[2:0] de_unit;
    wire[1:0] de_op;
    wire[5:0] de_rd_rn;
    wire[5:0] de_rd2_rn;
    wire[5:0] de_rs1_rn;
    wire[5:0] de_rs2_rn;
    wire[55:0] de_imm_data;

    wire de_r1_rn, de_r2_rn;

    wire de_allow_advance;

    decode decode1(
        .clk(clk), .rst_n(rst_n), .instIn(fe_inst), .advance16(fe_advance16),
        .advance32(fe_advance32), .advance64(fe_advance64), .type(de_type),
        .unit(de_unit), .op(de_op), .rs1_rn(de_rs1_rn), .rs2_rn(de_rs2_rn),
        .rd_rn(de_rd_rn), .rd2_rn(de_rd2_rn), .imm_data(de_imm_data),
        .r1_rn(de_r1_rn), .r2_rn(de_r2_rn),
        .allow_advance(de_allow_advance)
        );

    ////////// REG FILE  //////////
    //Concurrent with Schedule phase

    wire[63:0] rf_writeback;
    wire[63:0] rf_data1;
    wire[63:0] rf_data2;
    wire[5:0] rf_writeback_rn;
    wire rf_writeback_en;

    //Register file selected by the scheduler, registered in the execute stage
    //and written to during commit.
    regfile regfile1(
        .clk(clk), .rst_n(rst_n), .w_data(rf_writeback), .r1_data(rf_data1),
        .r2_data(rf_data2), .r1_rn(de_r1_rn), .r2_rn(de_r2_rn),
        .w_rn(rf_writeback_rn), .w_en(rf_writeback_en)
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

    wire[63:0] sc_busy_regs;

    wire[5:0] sc_free_rn[0:1];
    wire sc_free_rn_en[0:1];

    pr_table pr_table1 (
        .clk(clk), .rst_n(rst_n), .reg_busy(sc_busy_regs),
        .busy_rn[0](de_r1_rn), .busy_en[0](de_allow_advance),
        .busy_rn[1](de_r2_rn), .busy_en[1](de_allow_advance),
        .free_rn(sc_free_rn), .free_en(sc_free_rn_en),
//        .free_rn[1](sc_free_rn[1]), .free_en[1](sc_free_rn_en[1])
        );

    schedule schedule1(
        .clk(clk), .rst_n(rst_n),
        .type(de_type), .unit(de_unit),
        .r1_in_rn(de_r1_rn), .r2_in_rn(de_r2_rn),
        .rd_in_rn(de_rd_rn), .rd2_in_rn(de_rd2_rn),
        .instIssued(de_allow_advance), .reg_busy(sc_busy_regs),
        .rd_out_rn(sc_rd_rn), .rd2_out_rn(sc_rd2_rn),

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
    reg[55:0] sc_imm_data;

    always @(posedge clk or negedge rst_n)
    begin
        if(~rst_n) begin
            sc_type <= 0;
            sc_unit <= 3'h0;
            sc_op <= 2'h0;
            sc_imm_data <= 56'h0;
        else begin
            sc_type <= de_type;
            sc_unit <= de_unit;
            sc_op <= de_op;
            sc_imm_data <= de_imm_data;
        end
    end

    //////////  EXECUTE  //////////

    wire[63:0] ex_alu1_result;
    wire[63:0] ex_alu2_result;

    ex_alu ex_alu1(
        .clk(clk), .rst_n(rst_n), .in1(rf_data1), .in2(sc_type ? sc_imm_data[31:0] : rf_data2), .out(ex_alu1_result),
        .ex_enable(sc_alu1_en), .ex_busy(sc_alu1_busy), .rd_in_rn(sc_rd_rn), .unit(sc_unit),
        .op(sc_op), .rd_out_rn(), .stall()
        );

    ex_alu ex_alu2(
        .clk(clk), .rst_n(rst_n), .in1(rf_data1), .in2(sc_type ? sc_imm_data[31:0] : rf_data2), .out(ex_alu2_result),
        .ex_enable(sc_alu2_en), .ex_busy(sc_alu2_busy), .rd_in_rn(sc_rd_rn), .unit(sc_unit),
        .op(sc_op), .rd_out_rn(), .stall()
        );

    //////////  COMMIT   //////////


endmodule
