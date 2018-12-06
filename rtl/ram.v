//Test RAM
module ram(input clk,
            input we,
            input cs,
            input[63:0] addr,
            input[63:0] data_in,
            input[1:0] write_width, //0==64bit, 1==32bit, 2==16bit, 3==8bit
            output reg[63:0] data_out);

    parameter NUM_BYTES = 0;
    parameter INIT_FILE = "";

    reg[63:0] ram[0:(NUM_BYTES/8)-1]; //Nx64 RAM TODO Ceiling?

    reg[63:0] ramA_result, ramB_result;

    reg[7:0] weA_b; //Which byte lines are write-enabled
    reg[7:0] weB_b;

    always @(*) begin
        weA_b = 8'h00;
        weB_b = 8'h00;
        if(we) begin
            case(write_width)
            2'b00: {weA_b,weB_b} = 16'hFF00 >> addr[2:0];
            2'b01: {weA_b,weB_b} = 16'hF000 >> addr[2:0];
            2'b10: {weA_b,weB_b} = 16'hC000 >> addr[2:0];
            2'b11: {weA_b,weB_b} = 16'h8000 >> addr[2:0];
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

    reg[2:0] addr_lsb;
    always @(posedge clk) begin
        addr_lsb <= addr[2:0];
    end

    always @(*) begin
        data_out = ({ramA_result,ramB_result} >> ((8-addr_lsb)*8)) & 64'hFFFFFFFFFFFFFFFF;
    end

    //Populate our program memory with the user-provided hex file
    initial begin
        $readmemh(INIT_FILE, ram);
    end


endmodule
