//Raisin64 Instruction Decode

module decode(
    //# {{clocks|Clocking}}
    input clk,
    input rst_n,

    //# {{data|Fetch Data}}
    input[63:0] instIn,

    //# {{control|Fetch Control}}
    output advance16,
    output advance32,
    output advance64,

    //# {{data|Instruction Data Fields}}
    output reg type,
    output reg[2:0] unit,
    output reg[1:0] op,
    output reg[6:0] rs1_rn,
    output reg[6:0] rs2_rn,
    output reg[6:0] rd_rn,
    output reg[6:0] rd2_rn,
    output reg[56:0] imm_data
    );

    wire[63:0] canonInst;
    wire badOpcode;

    de_canonicalize de_canonicalize_1(
        .instIn(instIn), .instOut(canonInst)
        );

    de_badDetect de_badDetect_1(
        .instIn(instIn), .badOpcode(badOpcode)
        );

    assign advance16 = ~instIn[63];
    assign advance32 = (instIn[63:62] == 2'b10);
    assign advance64 = (instIn[63:62] == 2'b11);

    always @(posedge clk or negedge rst_n)
    begin
        if(~rst_n) begin
            type <= 0;
            unit <= 0;
            op <= 0;
            Rs1_rn <= 0;
            Rs2_rn <= 0;
            Rd_rn <= 0;
            Rd2_rn <= 0;
            imm_data <= 0;
        end else begin
            type <= canonInst[61];
            unit <= canonInst[60:58];
            op <= canonInst[57:56];
            Rs1_rn <= canonInst[43:38];
            Rs2_rn <= canonInst[37:32];
            Rd_rn <= canonInst[55:50];
            Rd2_rn <= canonInst[49:44];
            imm_data <= canonInst[55:0];
        end
    end

endmodule
