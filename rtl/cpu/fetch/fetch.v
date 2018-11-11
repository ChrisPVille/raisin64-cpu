//Raisin64 - Fetch Module
module fetch(
    //# {{clocks|Clocking}}
    input clk,
    input rst_n,

    //# {{data|Memory Bus}}
    input[63:0] imem_addr,
    input[63:0] imem_data,

    //# {{control|Memory Bus Control}}
    input imem_data_valid,
    output imem_addr_valid,

    //# {{data|Instruction Word}}
    output reg[63:0] instData,

    //# {{control|Decoder Status}}
    input advance16,
    input advance32,
    input advance64
    );

    reg[63:0] seq_pc;

    always @(posedge clk or negedge rst_n)
    begin
        if(~rst_n) seq_pc = 64'h0;
        else if(imem_data_valid) begin
            if(advance16) seq_pc <= seq_pc + 2;
            else if(advance32) seq_pc <= seq_pc + 4;
            else if(advance64) seq_pc <= seq_pc + 8;
        end
    end

    assign imem_addr = seq_pc;
    assign imem_addr_valid = 1;

    always @(posedge clk or negedge rst_n)
    begin
        if(~rst_n) instData <= 64'h0;
        else if(imem_data_valid) begin
            instData <= imem_data;
        end else begin
            instData <= 64'h0;
        end
    end

endmodule
