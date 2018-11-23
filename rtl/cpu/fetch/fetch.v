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

    //# {{data|Instruction Word}}
    output[63:0] instData,

    //# {{control|Pipeline Status}}
    input stall
    );

    reg[63:0] seq_pc;
    reg[63:0] prev_pc;

    wire advance, advance16, advance32, advance64;
    assign advance = advance16 | advance32 | advance64;

    assign advance16 = ~stall && ~imem_data[63];
    assign advance32 = ~stall && (imem_data[63:62] == 2'b10);
    assign advance64 = ~stall && (imem_data[63:62] == 2'b11);

    always @(posedge clk or negedge rst_n)
    begin
        if(~rst_n) begin
            seq_pc <= 64'h0;
            prev_pc <= 64'h0;
        end else if(imem_data_valid) begin
            prev_pc <= seq_pc;
            if(advance16) seq_pc <= seq_pc + 2;
            else if(advance32) seq_pc <= seq_pc + 4;
            else if(advance64) seq_pc <= seq_pc + 8;
        end
    end

    assign imem_addr_valid = 1;

    reg[64:0] instData_pre;

    always @(posedge clk or negedge rst_n)
    begin
        if(~rst_n) instData_pre <= 64'h0;
        else begin
            if(imem_data_valid)
                instData_pre <= imem_data;
            else
                instData_pre <= 64'h0;
        end
    end

    assign imem_addr = advance ? seq_pc : prev_pc;
    assign instData = advance ? imem_data : instData_pre;

endmodule
