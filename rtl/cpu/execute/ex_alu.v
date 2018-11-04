//Raisin64 Execute Unit - Integer ALU

module ex_alu(
    //# {{data|ALU Data}}
    input[63:0] in1,
    input[63:0] in2,
    output[63:0] out,

    //# {{control|Control Signals}}
    input[2:0] unit,
    input[1:0] op
    );

    reg[63:0] out_pre;
    assign out = out_pre;

    always @(*)
    begin
        out_pre = 64'h0;
        case(unit)
            3'h0: //Basic integer math
                case(op[0])
                    0,2: out_pre = in1 + in2; //ADD
                    1,3: out_pre = in1 - in2; //SUB
                endcase
            3'h1: //Compare/Set
                case(op)
                    0: out_pre = $signed(in1) < $signed(in2) ? 64'h1 : 64'h0; //SLT
                    1: out_pre = in1 < in2 ? 64'h1 : 64'h0; //SLTU
                    2: out_pre = $signed(in1) > $signed(in2) ? 64'h1 : 64'h0; //SGT
                    3: out_pre = in1 > in2 ? 64'h1 : 64'h0; //SGTU
                endcase
            3'h2: //Shift
                case(op)
                    0: out_pre = in1 << {|in2[63:6], in2[5:0]}; //SLL
                    1: out_pre = in1 >>> {|in2[63:6], in2[5:0]}; //SRA
                    2,3: out_pre = in1 >> {|in2[63:6], in2[5:0]}; //SRL
                endcase
            3'h3: //Bitwise Operations
                case(op)
                    0: out_pre = in1 & in2; //AND
                    1: out_pre = in1 ~| in2; //NOR
                    2: out_pre = in1 | in2; //OR
                    3: out_pre = in1 ^ in2; //XOR
                endcase
        endcase
    end
endmodule
