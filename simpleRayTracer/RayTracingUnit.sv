module RayTracingUnit
(
    input logic                 clk, reset,
    input logic [7:0]           cameraDirX, cameraDirY, cameraDirZ, cameraPosX, cameraPosY, cameraPosZ,
    input logic [12:0]          imageWidth, imageHeight,
    input logic [31:0]          cameraDistance,
    output logic                validRead,
    output logic [7:0]          red, green, blue,

    output logic [3:0]          curr_state
);

    logic                       Ready;
    logic [31:0]                dirX; 
    logic [31:0]                dirY; 
    logic [31:0]                dirZ;

    RayGenerator ray_generator 
    (
        .clk(clk),
        .reset_n(reset),
        .ready(Ready),
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
        .ray_dir_z(dirZ)
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
        .r(red),
        .g(green),
        .b(blue),
        .ready(Ready),
        .valid_data_out(validRead),
        .curr_state(curr_state)
    );

endmodule
