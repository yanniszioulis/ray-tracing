module RayTracingUnit
(
    input logic                 clk, reset,
    input logic [10:0]          cameraDirX, cameraDirY, cameraDirZ, cameraPosX, cameraPosY, cameraPosZ,
    input logic [12:0]          imageWidth, imageHeight,
    input logic                 ReadyExternal,
    input logic [31:0]          cameraDistance,
    output logic                validRead, lastX, Sof,
    output logic [7:0]          red, green, blue


);

    logic                       ReadyInternal;
    logic [31:0]                dirX; 
    logic [31:0]                dirY; 
    logic [31:0]                dirZ;
    logic [31:0]                 addr1;
    logic [31:0]                dout1;
    logic                       ren;
    logic [31:0]                loopIndex;

    RayGenerator ray_generator 
    (
        .clk(clk),
        .reset_n(reset),
        .ready_internal(ReadyInternal),
        .ready_external(ReadyExternal),
        .camera_pos_x(cameraPosX),
        .camera_pos_y(cameraPosY),
        .camera_pos_z(cameraPosZ),
        .camera_dir_x(cameraDirX),
        .camera_dir_y(cameraDirY),
        .camera_dir_z(cameraDirZ),
        .image_width(imageWidth),
        .image_height(imageHeight),
        .distance(cameraDistance),
        .ray_dir_x(dirX),
        .ray_dir_y(dirY),
        .ray_dir_z(dirZ),
        .loop_index(loopIndex)
    );


    RayProcessor ray_processor
    (
        .clk(clk),
        .reset_n(reset),
        .ray_dir_x(dirX),
        .ray_dir_y(dirY),
        .ray_dir_z(dirZ),
        .camera_pos_x(cameraPosX),
        .camera_pos_y(cameraPosY),
        .camera_pos_z(cameraPosZ),
        .image_width(imageWidth),
        .image_height(imageHeight),
        .ready_external(ReadyExternal),
        .r(red),
        .g(green),
        .b(blue),
        .ready_internal(ReadyInternal),
        .valid_data_out(validRead),
        .last_x(lastX),
        .sof(Sof),
        .address(addr1),
        .node(dout1),
        .ren(ren),
        .loop_index(loopIndex)
    );

    octant_rom OctantRom
    (
        .clk(clk),
        .addr1(addr1),
        .dout1(dout1),
        .ren(ren)
    );

endmodule
