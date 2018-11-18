//Raisin64 Pending Register Table
//Keeps track of which registers are currently issued for writing
//to the various execution units

module pr_table(
    //# {{clocks|Clocking}}
    input clk,
    input rst_n,

    //# {{data|Register Status}}
    output reg[63:0] reg_busy,

    //# {{control|Control Signals}}
    input[5:0] busy0_rn,
    input[5:0] busy1_rn,
    input busy0_en,
    input busy1_en,

    input[5:0] free0_rn, //TODO Two free ports aren't necessary if we only have one register file write port
    input[5:0] free1_rn
    );

    reg[63:0] reg_busy_pre;

    integer i;

    always @(*)
    begin
        reg_busy[0] = 0;
        for(i = 1; i < 64; i = i+1)
        begin
            reg_busy[i] = (busy0_rn==i && busy0_en) ? 1 :
                           (busy1_rn==i && busy1_en) ? 1 :
                           (free0_rn==i) ? 0 :
                           (free1_rn==i) ? 0 :
                           reg_busy_pre[i];
        end
    end

    always @(posedge clk or negedge rst_n)
    begin
        if(~rst_n) reg_busy_pre <= 64'h0;
        else begin
            if(busy0_en & |busy0_rn) begin
                reg_busy_pre[busy0_rn] <= 1;
            end

            if(busy1_en & |busy1_rn) begin
                reg_busy_pre[busy1_rn] <= 1;
            end

            reg_busy_pre[free0_rn] <= 0;
            reg_busy_pre[free1_rn] <= 0;
        end
    end

endmodule
