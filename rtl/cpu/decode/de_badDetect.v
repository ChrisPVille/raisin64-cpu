//Raisin64 Decode Unit - Bad Opcode Detector

module de_badDetect(
    //# {{data|Instruction Data}}
    input[63:0] instIn,

    //# {{control|Control Signals}}
    output badOpcode
    );

    `include "de_isa_def.vh"

    reg badOpcode_pre;
    wire is16, is32, is64;

    assign badOpcode = badOpcode_pre;

    assign is16 = ~instIn[63];
    assign is32 = instIn[63:62] == 2'h2;
    assign is64 = instIn[63:62] == 2'h3;

    //Detects and flags invalid opcodes
    always @(*)
    begin
        badOpcode_pre = 0;

        if(is16 && instIn[62:60] == 3'h7) badOpcode_pre = 1;
        else if(is32 | is64)
        begin
            case(instIn[61:56])
                `OP_BAD_02, `OP_BAD_03, `OP_BAD_0B, `OP_BAD_14, `OP_BAD_15,
                `OP_BAD_16, `OP_BAD_17, `OP_BAD_18, `OP_BAD_19, `OP_BAD_1A,
                `OP_BAD_1B, `OP_BAD_22, `OP_BAD_23, `OP_BAD_2B: badOpcode_pre = 1;
                `OP_FSTAR, `OP_LUI, `OP_JALI, `OP_JI: if(is32) badOpcode_pre = 1;
            endcase
        end
    end
endmodule
