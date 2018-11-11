//Raisin64 - Pipeline

module pipeline(
    //# {{clocks|Clocking}}
    input clk,
    input rst_n
    );

    //////////  FETCH    //////////
    wire[63:0] fe_inst;
    wire fe_advance16;
    wire fe_advance32;
    wire fe_advance64;

    //////////  DECODE   //////////

    wire de_type;
    wire[2:0] de_unit;
    wire[1:0] de_op;
    wire[5:0] de_rd_rn;
    wire[5:0] de_rd2_rn;
    wire[5:0] de_rs1_rn;
    wire[5:0] de_rs2_rn;
    wire[55:0] de_imm_data;

    decode decode1(
        .clk(clk), .rst_n(rst_n), .instIn(fe_inst), .advance16(fe_advance16),
        .advance32(fe_advance32), .advance64(fe_advance64), .type(de_type),
        .unit(de_unit), .op(de_op), .rs1_rn(de_rs1_rn), .rs2_rn(de_rs2_rn),
        .rd_rn(de_rd_rn), .rd2_rn(de_rd2_rn), .imm_data(de_imm_data)
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
        .r2_data(rf_data2), .r1_rn(de_rs1_rn), .r2_rn(de_rs2_rn),
        .w_rn(rf_writeback_rn), .w_en(rf_writeback_en)
        );

    ////////// SCHEDULE  //////////
    //Concurrent with Register File

    //Delay the relevant decode data into the schedule phase
    reg[55:0] sc_imm_data;
    reg sc_type;
    always @(posedge clk or negedge rst_n)
    begin
        if(~rst_n) begin
            sc_type <= 0;
            sc_imm_data <= 56'h0;
        else begin
            sc_type <= de_type;
            sc_imm_data <= de_imm_data;
        end
    end

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

    pr_table #(
        NUM_READ_PORTS = 2
        ) pr_table1 (
        .clk(clk), .rst_n(rst_n), .reg_busy(), .busy_rn(),
        .busy_en, .free_rn[0](), .free_en[0](), .free_rn[1](),
        .free_en[1]()
        );

    schedule schedule1(
        .clk(clk), .rst_n(rst_n), .type(de_type), .unit(de_unit),
        .rd_in_rn(), .rd2_in_rn(), .rd_in_rn_en(), .rd2_in_rn_en(),
        .instIssued(), .reg_busy(), .rd_out_rn(),
        .rd2_out_rn(), .alu1_en(), .alu2_en(), .advint_en(),
        .memunit_en(), .branch_en(), alu1_busy(sc_alu1_busy), .alu2_busy(), 
        .advint_busy(), .memunit_busy(), .branch_busy()
        );

    //////////  EXECUTE  //////////
    ex_alu ex_alu1(
        .clk(clk), .rst_n(rst_n), .in1(rf_data1), .in2(sc_type ? sc_imm_data[31:0] : rf_data2), .out(),
        .ex_enable(sc_alu1_en), .ex_busy(sc_alu1_busy), .rd_in_rn(), .unit(),
        .op(), .rd_out_rn(), .stall()
        );

    //////////  COMMIT   //////////
    

endmodule
