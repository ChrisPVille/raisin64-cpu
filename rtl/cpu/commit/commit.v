module commit(
    //# {{clocks|Clocking}}
    input clk,
    input rst_n,

    //# {{data|Execution Units Results}}
    input[63:0] alu1_result,
    input[63:0] alu2_result,
    input[63:0] advint_result,
    input[63:0] advint_result2,
    input[63:0] memunit_result,
    input[63:0] branch_result,

    input[5:0] alu1_rn,
    input[5:0] alu2_rn,
    input[5:0] advint_rn,
    input[5:0] advint_rn2,
    input[5:0] memunit_rn,

    //# {{control|Execution Units Control}}
    input alu1_valid,
    input alu2_valid,
    input advint_valid,
    input memunit_valid,
    input branch_valid,

    output alu1_stall,
    output alu2_stall,
    output advint_stall,
    output memunit_stall,
    output branch_stall,

    //# {{data|Register File Data}}
    output[63:0] write_data,
    output[5:0] write_rn
    );

    localparam STATE_IDLE = 3'h0;
    localparam STATE_P1 = 3'h1;
    localparam STATE_P2 = 3'h2;
    localparam STATE_P3 = 3'h3;
    localparam STATE_P4 = 3'h4;
    localparam STATE_P5 = 3'h5;
    localparam STATE_P6 = 3'h6;

    reg[2:0] state, next_state;

    reg[5:0] pending_rn[1:6];
    reg[63:0] pending_data[1:6];
    reg[6:1] pending_valid;

    //TODO Finish exception handling by un-stalling the ex units in strict order of issue (via external counting table)
    //For now, no exceptions are implemented.
    assign alu1_stall = pending_valid[1] && state != STATE_P1;
    assign alu2_stall = pending_valid[2] && state != STATE_P2;
    assign advint_stall = (pending_valid[3] && state != STATE_P3) | (pending_valid[4] && state != STATE_P4);
    assign memunit_stall = pending_valid[5] && state != STATE_P5;
    assign branch_stall = pending_valid[6] && state != STATE_P6;

    integer i;

    //The *unit*_valid signals need to remain high for only one cycle per transaction or all hell will break loose.
    always @(posedge clk or negedge rst_n)
    begin
        if(~rst_n) begin
            for(i = 1; i <= 6; i = i + 1) pending_valid[i] <= 0;
        end else begin
            case(state)
            STATE_P1: pending_valid[1] <= 0;
            STATE_P2: pending_valid[2] <= 0;
            STATE_P3: pending_valid[3] <= 0;
            STATE_P4: pending_valid[4] <= 0;
            STATE_P5: pending_valid[5] <= 0;
            STATE_P6: pending_valid[6] <= 0;
            endcase

            if(alu1_valid & |alu1_rn) begin
                pending_data[1] <= alu1_result;
                pending_rn[1] <= alu1_rn;
                pending_valid[1] <= 1;

            end if(alu2_valid & |alu2_rn) begin
                pending_data[2] <= alu2_result;
                pending_rn[2] <= alu2_rn;
                pending_valid[2] <= 1;

            end if(advint_valid & (|advint_rn | |advint_rn2)) begin
                pending_data[3] <= advint_result;
                pending_rn[3] <= advint_rn;
                pending_valid[3] <= 1;
                pending_data[4] <= advint_result2;
                pending_rn[4] <= advint_rn2;
                pending_valid[4] <= 1;

            end if(memunit_valid & |memunit_rn) begin
                pending_data[5] <= memunit_result;
                pending_rn[5] <= memunit_rn;
                pending_valid[5] <= 1;

            end if(branch_valid) begin
                pending_data[6] <= branch_result;
                pending_rn[6] <= 6'd63;
                pending_valid[6] <= 1;
            end
        end
    end

    always @(posedge clk or negedge rst_n)
    begin
        if(~rst_n) state <= STATE_IDLE;
        else state <= next_state;
    end

    always @(*)
    begin
        if(pending_valid[6] | branch_valid) next_state = STATE_P6;
        else if(pending_valid[5] | (memunit_valid & |memunit_rn)) next_state = STATE_P5;
        else if(pending_valid[4] | (advint_valid & |advint_rn2)) next_state = STATE_P4;
        else if(pending_valid[3] | (advint_valid & |advint_rn)) next_state = STATE_P3;
        else if(pending_valid[2] | (alu2_valid & |alu2_rn)) next_state = STATE_P2;
        else if(pending_valid[1] | (alu1_valid & |alu1_rn)) next_state = STATE_P1;
        else next_state = STATE_IDLE;
    end

    assign write_data = state == STATE_P1 ? pending_data[1] :
                        state == STATE_P2 ? pending_data[2] :
                        state == STATE_P3 ? pending_data[3] :
                        state == STATE_P4 ? pending_data[4] :
                        state == STATE_P5 ? pending_data[5] :
                        state == STATE_P6 ? pending_data[6] :
                        64'h0;

    assign write_rn = state == STATE_P1 ? pending_rn[1] :
                      state == STATE_P2 ? pending_rn[2] :
                      state == STATE_P3 ? pending_rn[3] :
                      state == STATE_P4 ? pending_rn[4] :
                      state == STATE_P5 ? pending_rn[5] :
                      state == STATE_P6 ? pending_rn[6] :
                      6'h0;

endmodule
