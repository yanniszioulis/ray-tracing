module octant_rom #(
    parameter   ADDRESS_WIDTH = 32,
                DATA_WIDTH = 32
)(
    input   logic                       clk,
    input   logic   [ADDRESS_WIDTH-1:0] addr1, addr2, addr3, addr4,
    output  logic   [DATA_WIDTH-1:0]    dout1, dout2, dout3, dout4,
    input   logic                       ren1, ren2, ren3, ren4
);

logic   [DATA_WIDTH-1:0] rom_array [37:0];

initial begin
    $display("loading rom.");
    $readmemh("octree.mem", rom_array);
    $display("loaded rom.");
end

always_ff @(posedge clk) begin
    if(ren1 || ren2 || ren3 || ren4 ) begin
        dout1 <= rom_array[addr1];
        dout2 <= rom_array[addr2];
        dout3 <= rom_array[addr3];
        dout4 <= rom_array[addr4];
    end
end

endmodule