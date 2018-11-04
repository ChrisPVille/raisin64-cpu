//Raisin64 Decode Unit - Opcode Canonicalization
//Converts compact instructions into their true 64-bit native format

module de_canonicalize(
    //# {{data|Instruction Data}}
    input[63:0] opcodeIn,
    output[63:0] opcodeOut
    );

    `include "de_isa_def.vh"

    reg[63:0] opcodeOut_pre;
    assign opcodeOut = opcodeOut_pre;

    //Expands input instruction into full 64-bit format
    always @(*)
    begin
        opcodeOut_pre = 64'h0;

        //Set the output size field appropriately
        opcodeOut_pre[63:62] = 2'h3;

        //16-Bit input instructions
        if(~opcodeIn[63])
        begin
            //Switch on Opcode field
            case(opcodeIn[62:60])
                `OP16_ADD:     opcodeOut_pre[61:56] = `OP_ADD; //ADD Rd = Rd + Rs
                `OP16_SUB:     opcodeOut_pre[61:56] = `OP_SUB; //SUB Rd = Rd - Rs
                `OP16_ADDI:    opcodeOut_pre[61:56] = `OP_ADDI; //ADDI Rd = Rd + sign_extend(imm)
                `OP16_SUBI:    opcodeOut_pre[61:56] = `OP_SUBI; //SUBI Rd = Rd - imm
                `OP16_SYSCALL: opcodeOut_pre[61:56] = `OP_SYSCALL; //SYSCALL
                `OP16_J:       opcodeOut_pre[61:56] = `OP_J; //J Rs
                `OP16_JAL:     opcodeOut_pre[61:56] = `OP_JAL; //JAL Rs
            endcase

            opcodeOut_pre[55:50] = opcodeIn[59:54]; //Put the Rd/Rs1 into Rd
            opcodeOut_pre[49:44] = 6'h0; //Rd2 is not used in this format
            opcodeOut_pre[43:38] = opcodeIn[59:54]; //Put the Rd/Rs1 into Rs1
            opcodeOut_pre[37:32] = opcodeIn[53:48]; //Populate Rs2 (imm type instructions ignore this)

            //Sign extended immediate field and populate
            opcodeOut_pre[31:0]  = {{26{opcodeIn[53]}},opcodeIn[53:48]}; //reg type instructions ignore this
        end

        //32-bit instructions
        else if(~opcodeIn[62])
        begin
            opcodeOut_pre[61:56] = opcodeIn[61:56]; //Set Type/Unit/Op fields
            opcodeOut_pre[55:50] = opcodeIn[55:50]; //Set Rd

            //32I-Type instruction
            if(opcodeIn[61]) begin
                opcodeOut_pre[43:38] = opcodeIn[49:44]; //Set Rs1

                //Sign-Extended type
                if(opcodeIn[60] || //Most sign-extended Ops
                   opcodeIn[60:58]==3'h0 || //ADDI/SUBI
                   opcodeIn[61:56]==`OP_SLTI ||
                   opcodeIn[61:56]==`OP_SGTI)
                      opcodeOut_pre[31:0] = {{20{opcodeIn[43]}},opcodeIn[43:32]}; 
                //Non Sign-extended type
                else opcodeOut_pre[11:0] = opcodeIn[43:32];

            //32R-Type instructions
            end else begin
                //Set the other operands
                opcodeOut_pre[49:32] = opcodeIn[49:32];

                //No immediate
            end
        end
        //64-bit instructions
        else opcodeOut_pre = opcodeIn;
    end
endmodule
