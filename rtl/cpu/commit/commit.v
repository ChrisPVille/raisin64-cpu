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

    output alu1_stall,
    output alu2_stall,
    output advint_stall,
    output memunit_stall,
    output branch_stall,

    //# {{data|Register File Data}}
    output reg[63:0] write_data,
    output reg[5:0] write_rn
    );

    //TODO Finish exception handling by un-stalling the ex units in strict order of issue (via external counting table)
    //For now, no exceptions are implemented, so we don't stall anyone.
    assign alu1_stall = 0;
    assign alu2_stall = 0;
    assign advint_stall = 0;
    assign memunit_stall = 0;
    assign branch_stall = 0;

    always @(*)
    begin
        write_data = 64'h0;
        write_rn = 6'h0;
        if(alu1_valid) begin
            write_data = alu1_result;
            write_rn = alu1_rn;
        end else if(alu2_valid) begin
            write_data = alu2_result;
            write_rn = alu2_rn;
        end else if(memunit_valid) begin
            write_data = memunit_result;
            write_rn = memunit_rn;
        end
    end

endmodule
