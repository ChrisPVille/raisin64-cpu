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

    reg[63:0] pc, next_pc, prev_pc;

    always @(posedge clk or negedge rst_n)
    begin
        if(~rst_n) begin
            //pc <= 64'h0;
            prev_pc <= 64'h0;
        end else begin
            //pc <= next_pc;
            prev_pc <= pc;
        end
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
        if(do_jump) pc = jump_pc;
        else if(stall) pc = prev_pc;
        else if(imem_data_valid) begin
            pc = next_seq_pc;
        end
    end

    reg[63:0] next_data;
    always @(*) begin
        next_data = inst_data;
        if(imem_data_valid) next_data = imem_data;
    end

    reg[63:0] prev_data;
    reg just_stalled;
    always @(posedge clk or negedge rst_n)
    begin
        if(~rst_n) begin
            just_stalled <= 0;
            inst_data <= 64'h0;
        end else begin
            just_stalled <= stall;
            if(~imem_data_valid | do_jump) inst_data <= 64'h0;
            else if(~stall) inst_data <= imem_data;
        end
    end

    //assign inst_data = ~imem_data_valid ? 64'h0 :  stall|just_stalled ? prev_data : imem_data;
    assign imem_addr_valid = 1;

endmodule
