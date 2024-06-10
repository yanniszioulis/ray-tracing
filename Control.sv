module control(
    input logic clk,                    // Clock input
    input logic reset,                  // Reset input
    input logic [7:0] image_height,     // Image height input
    input logic [7:0] image_width,      // Image width input
    input logic [7:0] camera_pos_x,     // Camera position x input
    input logic [7:0] camera_pos_y,     // Camera position y input
    input logic [7:0] camera_pos_z,     // Camera position z input
    input logic [7:0] camera_dir_x,     // Camera direction x input
    input logic [7:0] camera_dir_y,     // Camera direction y input
    input logic [7:0] camera_dir_z,     // Camera direction z input
    input logic [7:0] camera_distance,  // Camera distance input
    output logic error                  // Error output
);
    // Internal signals
    logic valid_input;

    // Simple validation checks
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            valid_input <= 0;
            error <= 0;
        end else begin
            // Check for validity (example: non-zero values)
            if (image_height == 0 || image_width == 0 || camera_distance == 0) begin
                valid_input <= 0;
                error <= 1; // Set error if inputs are invalid
            end else begin
                valid_input <= 1;
                error <= 0; // Clear error if inputs are valid
            end
        end
    end
  
   RTU rtu_inst (
        .clk(clk),
        .reset(reset),
        .cameraDirX(cameraDirX),
        .cameraDirY(cameraDirY),
        .cameraDirZ(cameraDirZ),
        .cameraPosX(cameraPosX),
        .cameraPosY(cameraPosY),
        .cameraPosZ(cameraPosZ),
        .imageWidth(imageWidth),
        .imageHeight(imageHeight),
        .cameraDistance(cameraDistance),
        .ReadyExternal(ReadyExternal),
        .validRead(validRead),
        .lastX(lastX),
        .Sof(Sof),
        .red(red),
        .green(green),
        .blue(blue)
    );  
    
endmodule
