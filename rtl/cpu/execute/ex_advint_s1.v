//Raisin64 Execute Unit - Advanced Integer Unit - Stage 1

//For now, we just use the intrinsic * and / operations.  These do have the
//advantage of mapping to DSP hard-blocks on our example SoC design.

module ex_advint_s1(
    //# {{data|ALU Data}}
    input[63:0] in1,
    input[63:0] in2,
    output[63:0] out,
    output[63:0] out2,

    //# {{control|Control Signals}}
    input enable,
    input[2:0] unit,
    input[1:0] op
    );

    reg[127:0] out_pre;
    assign out = out_pre[63:0];
    assign out2 = out_pre[127:64];

    always @(*)
    begin
        out_pre = 128'h0;

        if(enable & unit==3'h4) begin
            case(op)
                0: out_pre = $signed(in1) * $signed(in2); //MUL
                1: out_pre = in1 * in2; //MULU
                2: begin //DIV
                    out_pre[63:0] = $signed(in1) / $signed(in2);
                    out_pre[127:64] = $signed(in1) % $signed(in2);
                   end
                3: begin //DIVU
                    out_pre[63:0] = in1 / in2;
                    out_pre[127:64] = in1 % in2;
                   end
            endcase
        end
    end
endmodule
