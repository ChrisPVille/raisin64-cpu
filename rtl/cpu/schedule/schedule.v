//Raisin64 Instruction Scheduler
//Schedules a ready instruction to a free execution unit capiable of servicing it

module schedule(
    //# {{clocks|Clocking}}
    input clk,
    input rst_n,

    //# {{data|Decoded Instruction Data}}
    input type,
    input[2:0] unit,
    input[6:0] rd_in_rn,
    input[6:0] rd2_in_rn,

    //# {{control|Decoded Instruction Control}}
    output instIssued,

    //# {{control|Register Control}}
    input[63:0] reg_busy,

    //# {{data|Execution Units Register Data}}
    output reg[6:0] rd_out_rn,
    output reg rd_out_rn_en,
    output reg[6:0] rd2_out_rn,
    output reg rd2_out_rn_en,

    //# {{control|Execution Units Control Signals}}
    output reg alu1_en,
    output reg alu2_en,
    output reg advint_en,
    output reg memunit_en,
    output reg branch_en,

    input alu1_busy,
    input alu2_busy,
    input advint_busy,
    input memunit_busy,
    input branch_busy

    );

    assign instIssued = alu1_en | alu2_en | advint_en | memunit_en | branch_en;

    wire alu_type, advint_type, memunit_type, branch_type;
    assign alu_type = ~unit[2];
    assign advint_type = ~type && unit==3'h4;
    assign memunit_type = type && (unit==3'h4 | unit==3'h5 | unit==3'h6);
    assign branch_type = unit==3'h7;

    always @(posedge clk or negedge rst_n)
    begin
        if(~rst_n) begin
            alu1_en <= 0;
            alu2_en <= 0;
            advint_en <= 0;
            memunit_en <= 0;
            branch_en <= 0;
            rd_out_rn <= 6'h0;
            rd2_out_rn <= 6'h0;
            rd_out_rn_en <= 0;
            rd2_out_rn_en <= 0;

        end else begin
            rd_out_rn_en <= 0;
            rd2_out_rn_en <= 0;

            if(alu_type & ~alu1_busy) begin
                alu1_en <= 1;
                rd_out_rn <= Rd_rn;
                rd_out_rn_en <= 1;

            end else if(alu_type & ~alu2_busy) begin
                alu2_en <= 1;
                rd_out_rn <= Rd_rn;
                rd_out_rn_en <= 1;

            end else if(advint_type & ~advint_busy) begin
                advint_en <= 1;
                rd_out_rn <= Rd_rn;
                rd2_out_rn <= Rd2_rn;
                rd_out_rn_en <= 1;
                rd2_out_rn_en <= 1;

            end else if(memunit_type & ~memunit_busy) begin
                memunit_en <= 1;
                rd_out_rn <= Rd_rn;
                rd_out_rn_en <= 1;

            end else if(branch_type & ~branch_busy) begin
                branch_en <= 1;
                rd_out_rn <= Rd_rn;
                rd_out_rn_en <= 1;
            end
        end
    end

endmodule
