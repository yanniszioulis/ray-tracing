module octant_rom #(
    parameter   ADDRESS_WIDTH = 32,
                DATA_WIDTH = 32
)(
    input   logic                       clk,
    input   logic   [ADDRESS_WIDTH-1:0] addr1,
    output  logic   [DATA_WIDTH-1:0]    dout1,
    input   logic                       ren
);

logic   [DATA_WIDTH-1:0] rom_array [37:0];

initial begin
    $display("loading rom.");
    $readmemh("octree.mem", rom_array);
    $display("loaded rom.");
end

always_ff @(posedge clk) begin
    if(ren) begin
        dout1 <= rom_array[addr1];
    end
end

endmodule
