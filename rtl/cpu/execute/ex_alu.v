//Raisin64 Execute Unit - Integer ALU

module ex_alu(
    //# {{clocks|Clocking}}
    input clk,
    input rst_n,

    //# {{data|ALU Data}}
    input[63:0] in1,
    input[63:0] in2,
    output reg[63:0] out,

    //# {{control|Dispatch Control Signals}}
    input ex_enable,
    output ex_busy,
    input[5:0] rd_in_rn,
    input[2:0] unit,
    input[1:0] op,

    //# {{control|Commit Control Signals}}
    output reg[5:0] rd_out_rn,
    output reg valid,
    input stall
    );

    wire[63:0] out_pre;

    //We allow the next result to register when we aren't explicitly beign
    //stalled by the next stage (i.e. our result has somewhere to go).
    always @(posedge clk or negedge rst_n)
    begin
        if(~rst_n) begin
            valid <= 0;
            out <= 64'h0;
            rd_out_rn <= 6'h0;
        end else begin
            valid <= ex_enable;
            out <= out_pre;
            rd_out_rn <= rd_in_rn;
        end
    end

    initial begin
        if(stall&ex_enable) $error("Told to execute ALU when commit was stalled");
    end

    //As this is a one-cycle stage, busy is simple
    assign ex_busy = stall;

    ex_alu_s1 ex_alu_s1_1(
        .in1(in1), .in2(in2), .out(out_pre), .enable(ex_enable),
        .unit(unit), .op(op)
        );

endmodule
