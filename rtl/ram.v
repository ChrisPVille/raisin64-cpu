//Test RAM
module ram(input clk,
            input we,
            input cs,
            input[63:0] addr,
            input[63:0] data_in,
            output reg[63:0] data_out);

parameter NUM_BYTES = 0;
parameter INIT_FILE = "";

reg[7:0] ram[0:NUM_BYTES-1]; //Nx8 RAM
always @(posedge clk) begin
    if(we & cs) begin
        //Ram accesses in this system are byte-oriented
        ram[addr] <= data_in[63:56];
        ram[addr+1] <= data_in[55:48];
        ram[addr+2] <= data_in[47:40];
        ram[addr+3] <= data_in[39:32];
        ram[addr+4] <= data_in[31:24];
        ram[addr+5] <= data_in[23:16];
        ram[addr+6] <= data_in[15:8];
        ram[addr+7] <= data_in[7:0];
    end
end

//Registered read (ready by next clock cycle)
always @(posedge clk) begin
    if(cs) begin
        data_out[63:56] <= ram[addr];
        data_out[55:48: <= ram[addr+1];
        data_out[47:40] <= ram[addr+2];
        data_out[39:32] <= ram[addr+3];
        data_out[31:24] <= ram[addr+4];
        data_out[23:16] <= ram[addr+5];
        data_out[15:8] <= ram[addr+6];
        data_out[7:0] <= ram[addr+7];
    else data_out <= 64'h0;
end

//Populate our program memory with the user-provided hex file
initial begin
    $readmemh(INIT_FILE, ram);
end

endmodule
