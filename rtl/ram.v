//Test RAM
module ram(input clk,
            input we,
            input cs,
            input[63:0] addr,
            input[63:0] data_in,
            output reg[63:0] data_out);

    parameter NUM_BYTES = 0;
    parameter INIT_FILE = "";

    reg[63:0] ram[0:(NUM_BYTES/8)-1]; //Nx64 RAM

    reg[63:0] ramA_result, ramB_result;

    reg[7:0] weA_b; //Which byte lines are write-enabled
    reg[7:0] weB_b;

    always @(*) begin
        weA_b = 8'h00;
        weB_b = 8'h00;
        if(we) begin
            case(addr[2:0])
            3'h0: begin
                weA_b = 8'hFF;
                weB_b = 8'h00;
                end

            3'h1: begin
                weA_b = 8'h7F;
                weB_b = 8'h01;
                end

            3'h2: begin
                weA_b = 8'h3F;
                weB_b = 8'h03;
                end

            3'h3: begin
                weA_b = 8'h1F;
                weB_b = 8'h07;
                end

            3'h4: begin
                weA_b = 8'h0F;
                weB_b = 8'h0F;
                end

            3'h5: begin
                weA_b = 8'h07;
                weB_b = 8'h1F;
                end

            3'h6: begin
                weA_b = 8'h03;
                weB_b = 8'h3F;
                end

            3'h7: begin
                weA_b = 8'h01;
                weB_b = 8'h7F;
                end
            endcase
        end
    end

    generate
    genvar i;
    for(i = 0; i < 8; i = i+1) begin
        always @(posedge clk)
            if(cs)
                if(weA_b[i]) begin
                    ram[addr[63:3]][(i+1)*8-1:i*8] <= data_in[(i+1)*8-1:i*8];
                end
        end

    for(i = 0; i < 8; i = i+1) begin
        always @(posedge clk)
            if(cs)
                if(weB_b[i]) begin
                    ram[addr[63:3]+1][(i+1)*8-1:i*8] <= data_in[(i+1)*8-1:i*8];
                end
        end
    endgenerate

    //Registered read (ready by next clock cycle)
    always @(posedge clk) begin
        if(cs) begin
            ramA_result <= ram[addr[63:3]];
            ramB_result <= ram[addr[63:3]+1];
        end
    end

    always @(*) begin
        case(addr[2:0])
        3'h0: data_out = ramA_result;
        3'h1: data_out = {ramA_result[63:8],ramB_result[63:56]};
        3'h2: data_out = {ramA_result[63:16],ramB_result[63:48]};
        3'h3: data_out = {ramA_result[63:24],ramB_result[63:40]};
        3'h4: data_out = {ramA_result[63:32],ramB_result[63:32]};
        3'h5: data_out = {ramA_result[63:40],ramB_result[63:24]};
        3'h6: data_out = {ramA_result[63:48],ramB_result[63:16]};
        3'h7: data_out = {ramA_result[63:56],ramB_result[63:8]};
        endcase
    end

    //Populate our program memory with the user-provided hex file
    initial begin
        $readmemh(INIT_FILE, ram);
    end


endmodule
