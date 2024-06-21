module OctantRom #(
    parameter   ADDRESS_WIDTH = 32,
                DATA_WIDTH = 32
)(
    input   logic                       clk,
    input   logic   [ADDRESS_WIDTH-1:0] addr1, addr2,
    output  logic   [DATA_WIDTH-1:0]    dout1, dout2,
    input   logic                       ren1, ren2
);

logic   [DATA_WIDTH-1:0] rom_array [4305:0];

initial begin
    $display("loading mem...");
    $readmemh("house.mem", rom_array);
    $display("loaded");
end

always_ff @(posedge clk) begin
    if(ren1 || ren2) begin
        dout1 <= rom_array[addr1];
        dout2 <= rom_array[addr2];
    end
end

endmodule