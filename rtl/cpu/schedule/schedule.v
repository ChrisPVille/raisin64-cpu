//Raisin64 Instruction Scheduler
//Schedules a ready instruction to a free execution unit capiable of servicing it

module schedule(
    //# {{clocks|Clocking}}
    input clk,
    input rst_n,

    //# {{data|Decoded Instruction Data}}
    input type,
    input[2:0] unit,
    input[5:0] r1_in_rn,
    input[5:0] r2_in_rn,
    input[5:0] rd_in_rn,
    input[5:0] rd2_in_rn,

    //# {{control|Decoded Instruction Control}}
    output reg will_issue,

    //# {{control|Register Control}}
    input[5:0] reg1_finished,
    input[5:0] reg2_finished,

    //# {{data|Execution Units Register Data}}
    output reg[5:0] rd_out_rn,
    output reg[5:0] rd2_out_rn,

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

    reg[63:0] reg_busy;

    wire alu_type, advint_type, memunit_type, branch_type;
    assign alu_type = ~unit[2];
    assign advint_type = ~type && unit==3'h4;
    assign memunit_type = type && (unit==3'h4 | unit==3'h5 | unit==3'h6);
    assign branch_type = unit==3'h7;

    reg start_stall;
    always @(posedge clk or negedge rst_n)
    begin
        if(~rst_n) start_stall <= 0;
        else start_stall <= 1;
    end

    wire instIssued;
    assign instIssued = alu1_en | alu2_en | advint_en | memunit_en | branch_en;

    reg operand_unavailable;

    always @(*)
    begin
        operand_unavailable = 0;
        //We are starting up and wish to stall while the decode pipeline fills
        if(~start_stall) operand_unavailable = 1;

        //The register was previously busy
        else if(reg_busy[r1_in_rn] && r1_in_rn!=reg1_finished && r1_in_rn!=reg2_finished) operand_unavailable = 1;
        else if(reg_busy[r2_in_rn] && r2_in_rn!=reg2_finished && r2_in_rn!=reg1_finished) operand_unavailable = 1;

        //We just issued something to an execution unit
        else if(instIssued) begin
            //The incoming source register is non-zero
            if(|r1_in_rn) begin
                //And it matches the previous destination register number.  We
                //will stall here until it is picked up by reg_busy next cycle
                if(rd_out_rn==r1_in_rn) operand_unavailable = 1;
                else if(rd_out_rn==r2_in_rn) operand_unavailable = 1;
            end
            if(|r2_in_rn) begin
                if(rd2_out_rn==r1_in_rn) operand_unavailable = 1;
                else if(rd2_out_rn==r2_in_rn) operand_unavailable = 1;
            end
        end
    end

    always @(*)
    begin
        will_issue = 0;
        if(~operand_unavailable) begin
            if(alu_type & (~alu1_busy | ~alu2_busy)) will_issue = 1;
            else if(advint_type & ~advint_busy) will_issue = 1;
            else if(memunit_type & ~memunit_busy) will_issue = 1;
            else if(branch_type & ~branch_busy) will_issue = 1;
        end
    end

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
            reg_busy <= 64'h0;

        end else begin
            //Only allow the scheduling of instructions if the source registers
            //aren't the destination of in-progress instructions.
            alu1_en <= 0;
            alu2_en <= 0;
            advint_en <= 0;
            memunit_en <= 0;
            branch_en <= 0;

            reg_busy[reg1_finished] <= 0;
            reg_busy[reg2_finished] <= 0;

            if(~operand_unavailable) begin
                if(alu_type & ~alu1_busy) begin
                    alu1_en <= 1;
                    rd_out_rn <= rd_in_rn;
                    if(|rd_in_rn) reg_busy[rd_in_rn] <= 1;

                end else if(alu_type & ~alu2_busy) begin
                    alu2_en <= 1;
                    rd_out_rn <= rd_in_rn;
                    if(|rd_in_rn) reg_busy[rd_in_rn] <= 1;

                end else if(advint_type & ~advint_busy) begin
                    advint_en <= 1;
                    rd_out_rn <= rd_in_rn;
                    rd2_out_rn <= rd2_in_rn;
                    if(|rd_in_rn) reg_busy[rd_in_rn] <= 1;
                    if(|rd2_in_rn) reg_busy[rd2_in_rn] <= 1;

                end else if(memunit_type & ~memunit_busy) begin
                    memunit_en <= 1;
                    rd_out_rn <= rd_in_rn;
                    if(|rd_in_rn && unit!=3'h6) reg_busy[rd_in_rn] <= 1;

                end else if(branch_type & ~branch_busy) begin
                    branch_en <= 1;
                    rd_out_rn <= rd_in_rn;
                    if(|rd_in_rn) reg_busy[rd_in_rn] <= 1; //TODO Only BAL and then only 63
                end
            end
        end
    end

endmodule
