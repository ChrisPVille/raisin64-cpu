//Raisin64 Decode Unit - Opcode Canonicalization
//Converts compact instructions into their true 64-bit native format

module de_canonicalize(
    //# {{data|Instruction Data}}
    input[63:0] instIn,
    output[63:0] instOut
    );

    `include "de_isa_def.vh"

    reg[63:0] instOut_pre;
    assign instOut = instOut_pre;

    //Expands input instruction into full 64-bit format
    always @(*)
    begin
        instOut_pre = 64'h0;

        //Set the output size field appropriately
        instOut_pre[63:62] = 2'h3;

        //16-Bit input instructions
        if(~instIn[63])
        begin
            //Switch on Opcode field
            case(instIn[62:60])
                `OP16_ADD:     instOut_pre[61:56] = `OP_ADD; //ADD Rd = Rd + Rs
                `OP16_SUB:     instOut_pre[61:56] = `OP_SUB; //SUB Rd = Rd - Rs
                `OP16_ADDI:    instOut_pre[61:56] = `OP_ADDI; //ADDI Rd = Rd + sign_extend(imm)
                `OP16_SUBI:    instOut_pre[61:56] = `OP_SUBI; //SUBI Rd = Rd - imm
                `OP16_SYSCALL: instOut_pre[61:56] = `OP_SYSCALL; //SYSCALL
                `OP16_J:       instOut_pre[61:56] = `OP_J; //J Rs
                `OP16_JAL:     instOut_pre[61:56] = `OP_JAL; //JAL Rs
            endcase

            instOut_pre[55:50] = instIn[59:54]; //Put the Rd/Rs1 into Rd
            instOut_pre[49:44] = 6'h0; //Rd2 is not used in this format
            instOut_pre[43:38] = instIn[59:54]; //Put the Rd/Rs1 into Rs1
            instOut_pre[37:32] = instIn[53:48]; //Populate Rs2 (imm type instructions ignore this)

            //Sign extended immediate field and populate
            instOut_pre[31:0]  = {{26{instIn[53]}},instIn[53:48]}; //reg type instructions ignore this
        end

        //32-bit instructions
        else if(~instIn[62])
        begin
            instOut_pre[61:56] = instIn[61:56]; //Set Type/Unit/Op fields
            instOut_pre[55:50] = instIn[55:50]; //Set Rd

            //32I-Type instruction
            if(instIn[61]) begin
                instOut_pre[43:38] = instIn[49:44]; //Set Rs1

                //Sign-Extended type
                if(instIn[60] || //Most sign-extended Ops (remember, JALI and JI are invalid for 32I)
                   instIn[60:58]==3'h0 || //ADDI/SUBI signed versions sign extend
                   instIn[61:56]==`OP_SLTI || //SLTI and SGTI are signed and sign extend
                   instIn[61:56]==`OP_SGTI)
                      instOut_pre[31:0] = {{20{instIn[43]}},instIn[43:32]}; 
                //Non Sign-extended type
                else instOut_pre[11:0] = instIn[43:32];

            //32R-Type instructions
            end else begin
                //Set the other operands
                instOut_pre[49:32] = instIn[49:32];

                //No immediate
            end
        end
        //64-bit instructions
        else instOut_pre = instIn;
    end
endmodule
