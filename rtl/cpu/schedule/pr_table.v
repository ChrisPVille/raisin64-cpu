//Raisin64 Instruction Scheduler - Pending Register Table
//Keeps track of which registers are currently issued for writing
//to the various execution units

module pr_table #(
    parameter NUM_READ_PORTS = 3,
    ) (
    //# {{clocks|Clocking}}
    input clk,
    input rst_n,

    //# {{data|Register Status}}
    output reg[63:0] reg_busy,

    //# {{control|Control Signals}}
    input[6:0] busy_rn,
    input busy_en,

    input[6:0] free_rn[0:NUM_READ_PORTS-1],
    input free_en[0:NUM_READ_PORTS-1]
    );

    integer i;

    always @(posedge clk or negedge rst_n)
    begin
        if(~rst_n) reg_busy <= 64'h0;
        else for(i = 0; i < NUM_READ_PORTS; i=i+1)
        begin
            if(busy_en) reg_busy[busy_rn] <= 1;
            else if(free_en[i]) reg_busy[free_rn[i]] <= 0;

            if(busy_en & free_en[i]) $warning("Register in commit table freed and taken simultaneously");
        end
    end

endmodule
