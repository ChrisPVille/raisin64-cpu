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
    input[6:0] busy_rn[0:1],
    input busy_en[0:1],

    input[6:0] free_rn[0:1],
    input free_en[0:1]
    );

    integer i;

    always @(posedge clk or negedge rst_n)
    begin
        if(~rst_n) reg_busy <= 64'h0;
        else begin
            if(busy_en[0] & |busy_rn[0]) begin
                reg_busy[busy_rn[0]] <= 1;
            end

            if(busy_en[1] & |busy_rn[1]) begin
                reg_busy[busy_rn[1]] <= 1;
            end

            if(free_en[0]) begin
                reg_busy[free_rn[0]] <= 0;
            end

            if(free_en[1]) begin
                reg_busy[free_rn[1]] <= 0;
            end
        end
    end

endmodule
