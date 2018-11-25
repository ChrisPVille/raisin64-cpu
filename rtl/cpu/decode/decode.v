//Raisin64 Instruction Decode

module decode(
    //# {{clocks|Clocking}}
    input clk,
    input rst_n,

    //# {{data|Fetch Data}}
    input[63:0] instIn,

    //# {{data|Instruction Data Fields}}
    output reg type,
    output reg[2:0] unit,
    output reg[1:0] op,
    output reg[5:0] rs1_rn,
    output reg[5:0] rs2_rn,
    output reg[5:0] rd_rn,
    output reg[5:0] rd2_rn,
    output reg[63:0] imm_data,

    //Indicates which registers are loaded for this instruction
    output reg[5:0] r1_rn,
    output reg[5:0] r2_rn,

    //# {{control|Scheduler Feedback}}
    input stall

    );

    wire[63:0] canonInst;
    wire badOpcode;

    de_canonicalize de_canonicalize_1(
        .instIn(instIn), .instOut(canonInst)
        );

    de_badDetect de_badDetect_1(
        .instIn(instIn), .badOpcode(badOpcode)
        );

    reg load_rs1, load_rs1_rs2, load_rs1_rd;

    reg signedImm;

    always @(*) begin
        signedImm = 0;
        casex(canonInst[60:56])
        5'b000xx, //ADD, SUB
        5'b001x0, //SLTI, SGTI
        5'b10xxx, //LW, L32, L16, L8, LUI, L32S, L16S, L8S
        5'b110xx, //SW, S32, S16, S8
        5'b1110x: signedImm = 1; //BEQ, BEQAL
        endcase
    end

    wire ji_type;
    assign ji_type = &canonInst[61:57]; //Imm Type, Unit 7, JALI or JI

    always @(*) begin
        load_rs1 = 0;
        load_rs1_rs2 = 0;
        load_rs1_rd = 0;

        if(~canonInst[61]) begin //R-Type
            if(canonInst[60:58] < 3'h5 || //Units 0-4
              (&canonInst[60:58] && canonInst[57:56] == 2'h1)) begin //F* Inst
                load_rs1_rs2 = 1;
            end else if(&canonInst[60:58] & canonInst[57]) begin //JAL, J
                load_rs1 = 1;
            end
        end else begin //I-Type
            if(canonInst[60:58] < 3'h5 || //Units 0-4
              canonInst[60:58] == 3'h5 && |canonInst[57:56]) begin //Unit 5 except LUI
                load_rs1 = 1;
            end else if(canonInst[60:58] == 3'h6 | //Unit 6
              &canonInst[60:58] & ~canonInst[57]) begin //BEQ, BEQAL
                load_rs1_rd = 1;
            end
        end
    end

    always @(posedge clk or negedge rst_n)
    begin
        if(~rst_n) begin
            type <= 0;
            unit <= 0;
            op <= 0;
            rs1_rn <= 0;
            rs2_rn <= 0;
            rd_rn <= 0;
            rd2_rn <= 0;
            imm_data <= 0;
            r1_rn <= 0;
            r2_rn <= 0;
        end else begin
            if(~stall) begin
                type <= canonInst[61];
                unit <= canonInst[60:58];
                op <= canonInst[57:56];
                rs1_rn <= canonInst[43:38];
                rs2_rn <= canonInst[37:32];
                rd_rn <= canonInst[55:50];
                rd2_rn <= canonInst[49:44];
                imm_data <= ji_type ? {{8{1'b0}},canonInst[55:0]} : //TODO Need to decide how upper bits are handled
                            signedImm ? {{32{canonInst[31]}},canonInst[31:0]} :
                            {{32{1'b0}},canonInst[31:0]};

                r1_rn <= (load_rs1|load_rs1_rs2|load_rs1_rd) ? canonInst[43:38] : 6'h0;
                r2_rn <= load_rs1_rd ? canonInst[55:50] :
                                       load_rs1_rs2 ? canonInst[37:32] :
                                       6'h0;
            end
        end
    end

endmodule
