//Raisin64 Execute Unit - Branch and Jump Unit

module ex_branch(
    //# {{clocks|Clocking}}
    input clk,
    input rst_n,

    //# {{data|Branch Data}}
    input[63:0] in1,
    input[63:0] in2,
    input[63:0] imm,
    input[63:0] next_pc,
    output reg[63:0] jump_pc,
    output reg do_jump,

    output reg[63:0] r63,
    output reg r63_update,

    //# {{control|Dispatch Control Signals}}
    input ex_enable,
    output ex_busy,
    input[2:0] unit,
    input[1:0] op,

    //# {{control|Commit Control Signals}}
    input stall
    );

    wire op_eq;
    assign op_eq = (in1 == in2);

    always @(posedge clk or negedge rst_n)
    begin
        if(~rst_n) begin
            jump_pc <= 64'h0;
            do_jump <= 0;
            r63 <= 64'h0;
            r63_update <= 0;
        end else begin
            jump_pc <= 64'h0;
            do_jump <= 0;
            r63 <= 64'h0;
            r63_update <= 0;

            if(ex_enable) begin
                if(op[1]) begin //Jump
                    //Input is already properly shifted by the time it gets here
                    jump_pc <= in1;
                    do_jump <= 1;
                    if(op[0]) begin //And Link
                        r63_update <= 1;
                        r63 <= next_pc;
                    end
                end else if (~op[1] & op_eq) begin //Branch
                    jump_pc <= next_pc + (imm<<1);
                    do_jump <= 1;
                    if(op[0]) begin //And Link
                        r63_update <= 1;
                        r63 <= next_pc;
                    end
                end
            end
        end
    end

    assign ex_busy = ex_enable;

endmodule
