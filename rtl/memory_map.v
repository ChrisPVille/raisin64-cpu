//Raisin64 - Memory Map
module memory_map(
    input[63:0] addr,
    output io,
    output led,
    output sw,
    output vga
    );

    //As physical addresses are sign-extended from the 47th bit,
    //only bits 46:14 really matter

    //Upper-half of the memory map is IO for now
    assign io = addr[46];

    assign led = (addr[46:14] == 33'h100000001);
    assign sw  = (addr[46:14] == 33'h100000002);
    assign vga = (addr[46:18] == 33'h10000001);

endmodule
