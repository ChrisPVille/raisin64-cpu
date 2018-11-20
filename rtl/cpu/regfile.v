//Raisin64 Register File
//Registered dual-ported register file two read, one write port

module regfile(
    //# {{clocks|Clocking}}
    input clk,
    input rst_n,

    //# {{data|Register Interface}}
    input[63:0] w_data,
    output reg[63:0] r1_data,
    output reg[63:0] r2_data,

    //# {{control|Register Control}}
    input[5:0] r1_rn,
    input[5:0] r2_rn,
    input[5:0] w_rn,
    input w_en

    //# {{debug|Debug Signals}}
    );

    reg[63:0] file[1:63];
    reg[63:0] r1_data_pre, r2_data_pre;
    integer i;

    //TODO if place-route isn't smart enough to figure it out and use block ram, have two register files with write ports cross connected so we get "two" read ports on a clock cycle using multiple simple dual-port rams.
    always @(posedge clk or negedge rst_n)
    begin
        if(~rst_n) begin
            for(i = 1; i<64; i = i+1) file[i] <= 64'h0;
        end else begin
            if(w_en && w_rn!=6'h0) file[w_rn] <= w_data;
        end
    end

    always @(posedge clk or negedge rst_n)
    begin
        if(~rst_n) r1_data <= 64'h0;
        else if(r1_rn==6'h0) r1_data <= 64'h0;
        else r1_data <= (w_rn==r1_rn && w_en) ? w_data : file[r1_rn];
    end

    always @(posedge clk or negedge rst_n)
    begin
        if(~rst_n) r2_data <= 64'h0;
        else if(r2_rn==6'h0) r2_data <= 64'h0;
        else r2_data <= (w_rn==r2_rn && w_en) ? w_data : file[r2_rn];
    end
endmodule
