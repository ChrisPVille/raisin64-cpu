//Raisin64 - Fetch Module
module fetch(
    //# {{clocks|Clocking}}
    input clk,
    input rst_n,

    //# {{data|Memory Bus}}
    output[63:0] imem_addr,
    input[63:0] imem_data,

    //# {{control|Memory Bus Control}}
    input imem_data_valid,
    output imem_addr_valid,

    //# {{data|Pipeline Data}}
    output reg[63:0] inst_data,
    output[63:0] next_jump_pc,
    input[63:0] jump_pc,

    //# {{control|Pipeline Status}}
    input do_jump,
    input stall
    );

    //TODO Register type jumps can still get us off 16-bit boundries. Probably should just ignore the bottom bit

    reg[63:0] pc, next_pc, prev_pc;

    always @(posedge clk or negedge rst_n)
    begin
        if(~rst_n) prev_pc <= 64'h0;
        else prev_pc <= pc;
    end

    assign imem_addr = pc;

    //Becuase the PC is "ahead" by a cycle and the data leaving the fetch
    //module is "behind", our prev_pc will actually point at the next PC
    //for any associated jumps.
    assign next_jump_pc = prev_pc;

    reg[63:0] next_seq_pc;
    always @(*) begin
        casex(imem_data[63:62])
        2'b0x: next_seq_pc = prev_pc + 2;
        2'b10: next_seq_pc = prev_pc + 4;
        2'b11: next_seq_pc = prev_pc + 8;
        endcase
    end

    always @(*) begin
        pc = prev_pc;
        if(~rst_n); //Do nothing
        else if(do_jump) pc = jump_pc;
        else if(stall) pc = prev_pc;
        else if(imem_data_valid) pc = next_seq_pc;
    end

    reg[63:0] next_data;
    always @(*) begin
        next_data = inst_data;
        if(imem_data_valid) next_data = imem_data;
    end

    reg[63:0] prev_data;
    always @(posedge clk or negedge rst_n)
    begin
        if(~rst_n) begin
            inst_data <= 64'h0;
        end else begin
            if(~imem_data_valid | do_jump) inst_data <= 64'h0;
            else if(~stall) inst_data <= imem_data;
        end
    end

    assign imem_addr_valid = 1;

endmodule
