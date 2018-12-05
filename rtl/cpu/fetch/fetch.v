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
    output[63:0] inst_data,
    output reg[63:0] next_seq_pc,
    input[63:0] jump_pc,

    //# {{control|Pipeline Status}}
    input do_jump,
    input stall
    );

    reg[63:0] prev_pc;

    wire advance, advance16, advance32, advance64;
    assign advance = advance16 | advance32 | advance64;

    assign advance16 = ~stall && ~imem_data[63];
    assign advance32 = ~stall && (imem_data[63:62] == 2'b10);
    assign advance64 = ~stall && (imem_data[63:62] == 2'b11);

    always @(posedge clk or negedge rst_n)
    begin
        if(~rst_n) begin
            next_seq_pc <= 64'h0;
            prev_pc <= 64'h0;
        end else begin
            if(do_jump) next_seq_pc <= jump_pc;
            else if(imem_data_valid) begin
                if(advance) prev_pc <= next_seq_pc;
                if(advance16) next_seq_pc <= next_seq_pc + 2;
                else if(advance32) next_seq_pc <= next_seq_pc + 4;
                else if(advance64) next_seq_pc <= next_seq_pc + 8;
            end
        end
    end

    assign imem_addr_valid = 1;

    reg[63:0] inst_data_pre;

    always @(posedge clk or negedge rst_n)
    begin
        if(~rst_n) inst_data_pre <= 64'h0;
        else begin
            if(imem_data_valid)
                inst_data_pre <= imem_data;
            else
                inst_data_pre <= 64'h0;
        end
    end

    assign imem_addr = do_jump ? jump_pc :
                       advance ? next_seq_pc :
                       prev_pc;

    assign inst_data = advance ? imem_data : inst_data_pre;

endmodule
