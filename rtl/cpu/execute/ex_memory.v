//Raisin64 Execute Unit - Memory Unit

module ex_memory(
    input clk,
    input rst_n,

    //# {{data|Memory Data}}
    input[63:0] dmem_din,
    output reg[63:0] dmem_dout,
    output reg[63:0] dmem_addr,

    //# {{control|Memory Control Signals}}
    input dmem_cycle_complete,
    output dmem_width,
    output reg dmem_rstrobe,
    output reg dmem_wstrobe,

    //# {{data|Register Data}}
    input[63:0] base, //R1
    input[63:0] data, //R2
    input[31:0] offset,
    output reg[63:0] out,

    //# {{control|Dispatch Control Signals}}
    input ex_enable,
    output ex_busy,
    input[5:0] rd_in_rn,
    input[2:0] unit,
    input[1:0] op,

    //# {{control|Commit Control Signals}}
    output reg[5:0] rd_out_rn,
    output reg valid,
    input stall
    );

    localparam START = 3'h0;
    localparam READ_STROBE = 3'h1;
    localparam READ_WAIT = 3'h3;
    localparam FINISH = 3'h2;
    localparam WRITE_STROBE = 3'h4;
    localparam WRITE_WAIT = 3'h6;

    ////////////////////////////////////////
    //// Registering of control signals ////
    ////////////////////////////////////////

    reg[63:0] data_reg;
    reg[5:0] rd_in_rn_reg;
    reg[2:0] unit_reg;
    reg[1:0] op_reg;

    always @(posedge clk or negedge rst_n)
    begin
        if(~rst_n) begin
            data_reg <= 64'h0;
            rd_in_rn_reg <= 6'h0;
            unit_reg <= 3'h0;
            op_reg <= 2'h0;
        end else if(ex_enable) begin
            data_reg <= data;
            rd_in_rn_reg <= rd_in_rn;
            unit_reg <= unit;
            op_reg <= op;
        end
    end

    //Signals associated with the incoming instruction (and only valid at ex_enable)
    wire load, store, lui;
    assign load = (unit == 3'h4 || //Regular load
                  (unit == 3'h5 && op != 2'h0)); //Sign-Extend load except LUI

    assign store = (unit == 3'h6); //Store
    assign lui = (unit == 3'h5 && op == 2'h0); //LUI

    //Signals using the registered control signals
    wire sign_extend_reg;
    assign sign_extend_reg = (unit_reg == 3'h5 && op_reg != 2'h0); //Sign-Extend load except LUI

    assign dmem_width = op_reg;

    ///////////////////////////////
    //// State machine control ////
    ///////////////////////////////

    reg[2:0] state;
    reg[63:0] effective_addr;

    assign ex_busy = stall || (state != START);

    always @(posedge clk or negedge rst_n)
    begin
        if(~rst_n) begin
            state <= START;
            effective_addr <= 64'h0;
            out <= 64'h0;
            valid <= 1'b0;
            rd_out_rn <= 6'h0;
            dmem_dout <= 64'h0;
            dmem_addr <= 64'h0;
            dmem_rstrobe <= 1'b0;
            dmem_wstrobe <= 1'b0;
        end else begin

            case(state)
            START: begin
                valid <= 0;
                rd_out_rn <= 6'h0;
                dmem_rstrobe <= 0;
                dmem_wstrobe <= 0;

                if(ex_enable) begin
                    effective_addr <= base + offset;
                    if(load) state <= READ_STROBE; // Loads/Reads
                    else if(store) state <= WRITE_STROBE; // Stores/Writes
                    else if(lui) begin
                        out <= {offset,{32{1'b0}}};
                        valid <= 1;
                        rd_out_rn <= rd_in_rn;
                    end
                end
            end

            READ_STROBE: begin
                dmem_addr <= effective_addr;
                dmem_rstrobe <= 1;
                state <= READ_WAIT;
            end

            WRITE_STROBE: begin
                dmem_addr <= effective_addr;
                dmem_dout <= data_reg;
                dmem_wstrobe <= 1;
                state <= WRITE_WAIT;
            end

            READ_WAIT: begin
                dmem_rstrobe <= 0;
                if(dmem_cycle_complete) begin
                    valid <= 1;
                    rd_out_rn <= rd_in_rn_reg;
                    case(op_reg)
                    //64-Bit load
                    0: out <= dmem_din;

                    //32-Bit load
                    1: out <= sign_extend_reg ? {{32{dmem_din[31]}},dmem_din[31:0]} :
                                                {{32{1'b0}},dmem_din[31:0]};

                    //16-Bit load
                    2: out <= sign_extend_reg ? {{48{dmem_din[15]}},dmem_din[15:0]} :
                                                {{48{1'b0}},dmem_din[15:0]};

                    //8-Bit load
                    3: out <= sign_extend_reg ? {{56{dmem_din[7]}},dmem_din[7:0]} :
                                                {{56{1'b0}},dmem_din[7:0]};
                    endcase
                    state <= START;
                end
            end

            WRITE_WAIT: begin
                dmem_wstrobe <= 0;
                if(dmem_cycle_complete) begin
                    valid <= 1;
                    state <= START;
                end
            end

            default: begin
                $error("Reached unreachable case in memory state machine");
                state <= START; //TODO Throw exception
            end
            endcase
        end
    end
endmodule
