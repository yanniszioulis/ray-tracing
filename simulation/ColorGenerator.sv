module ColorGenerator(
    input [9:0] x, // Pixel X coordinate (0 to 1023)
    input [9:0] y, // Pixel Y coordinate (0 to 1023)
    output reg [7:0] r, // Red channel
    output reg [7:0] g, // Green channel
    output reg [7:0] b  // Blue channel
);

always @(*) begin
    // Example: gradient pattern
    r = x[7:0]; // Red based on X coordinate
    g = y[7:0]; // Green based on Y coordinate
    b = (x[7:0] ^ y[7:0]); // Blue as XOR of X and Y coordinates
end

endmodule
