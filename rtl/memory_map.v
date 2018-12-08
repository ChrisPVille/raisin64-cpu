//Raisin64 - Memory Map
module memory_map(
    input[63:0] addr,
    output io,
    output led,
    output sw,
    output vga
    );

    //As physical addresses are sign-extended from the 47th bit,
    //only bits 47:14 really matter

    //Upper-half of the memory map is IO for now
    assign io = addr[47];

    assign led = (addr[47:14] == 80000001);
    assign sw = (addr[47:14] == 80000002);
    assign vga = (addr[47:14] == 80000003);

endmodule
