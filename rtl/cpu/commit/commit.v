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
    output reg[63:0] write_data,
    output reg[5:0] write_rn
    );

    reg state, next_state;

    localparam STATE_NORMAL = 1'h0;
    localparam STATE_DEFERRED_REGW = 1'h1;

    //TODO Finish exception handling by un-stalling the ex units in strict order of issue (via external counting table)
    //For now, no exceptions are implemented, so we don't stall anyone.  We also need this selective un-stall scheme to
    //deal with multi-cycle execution units, which was discovered to be unnecessary for the base instruction-set.
    assign alu1_stall = |state;
    assign alu2_stall = |state;
    assign advint_stall = |state;
    assign memunit_stall = |state;
    assign branch_stall = |state;

    always @(posedge clk or negedge rst_n)
    begin
        if(~rst_n) state <= STATE_NORMAL;
        else state <= next_state;
    end

    reg[63:0] deferred_result;
    reg[5:0] deferred_result_rn;
    always @(posedge clk or negedge rst_n)
    begin
        if(~rst_n) begin
            deferred_result <= 64'h0;
            deferred_result_rn <= 6'h0;
        end else if(advint_valid) begin
            deferred_result <= advint_result2;
            deferred_result_rn <= advint_rn2;
        end
    end

    always @(*)
    begin
        next_state = STATE_NORMAL;
        write_data = 64'h0;
        write_rn = 6'h0;

        case(state)
        STATE_NORMAL: begin
            if(branch_valid) begin
                write_data = branch_result;
                write_rn = 6'd63;
            end else if(alu1_valid) begin
                write_data = alu1_result;
                write_rn = alu1_rn;
            end else if(alu2_valid) begin
                write_data = alu2_result;
                write_rn = alu2_rn;
            end else if(advint_valid) begin
                next_state = STATE_DEFERRED_REGW;
                write_data = advint_result;
                write_rn = advint_rn;
            end else if(memunit_valid) begin
                write_data = memunit_result;
                write_rn = memunit_rn;
            end
        end

        STATE_DEFERRED_REGW: begin
            write_data = deferred_result;
            write_rn = deferred_result_rn;
        end

        endcase

    end

endmodule
