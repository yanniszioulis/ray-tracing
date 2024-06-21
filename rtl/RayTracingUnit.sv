module RayTracingUnit
(
    input logic                 clk, reset,
    input logic [11:0]          cameraDirX, cameraDirY, cameraDirZ, cameraPosX, cameraPosY, cameraPosZ, cameraRightX, cameraRightY, cameraRightZ, cameraUpX, cameraUpY, cameraUpZ,
    input logic [12:0]          imageWidth, imageHeight,
    input logic                 ReadyExternal,
    output logic                validRead, SOF_out, EOL_out,
    output logic [7:0]          out_red, out_green, out_blue


);

    logic                       ReadyInternal1, ReadyInternal2;
    logic                       valid1, valid2;
    logic [11:0]                dirX1, dirX2; 
    logic [11:0]                dirY1, dirY2; 
    logic [11:0]                dirZ1, dirZ2;
    logic [31:0]                addr1;
    logic [31:0]                dout1;
    logic [31:0]                addr2;
    logic [31:0]                dout2;
    logic                       ren1, ren2;
    logic [7:0]                 red1, green1, blue1;
    logic [7:0]                 red2, green2, blue2;
    logic [31:0]                loopIndex1, loopIndex2;
    logic                       ready1, ready2;
    logic                       lastX1, lastX2;
    logic                       sof1, sof2;
    logic                       validDir1, validDir2;

    RayGenerator ray_generator1 
    (
        .clk(clk),
        .reset_n(reset),
        .ready_internal(ReadyInternal1),
        .ready_external(ready1),
        .camera_pos_x(cameraPosX),
        .camera_pos_y(cameraPosY),
        .camera_pos_z(cameraPosZ),
        .camera_dir_x(cameraDirX),
        .camera_dir_y(cameraDirY),
        .camera_dir_z(cameraDirZ),
        .camera_right_x(cameraRightX),
        .camera_right_y(cameraRightY),
        .camera_right_z(cameraRightZ),
        .camera_up_x(cameraUpX),
        .camera_up_y(cameraUpY),
        .camera_up_z(cameraUpZ),
        .image_width(imageWidth),
        .image_height(imageHeight),
        .ray_dir_x(dirX1),
        .ray_dir_y(dirY1),
        .ray_dir_z(dirZ1),
        .loop_index(loopIndex1),
        .op_code(2'b01),
        .core_number(3'b001),
        .en(1'b1),
        .val_dir(validDir1)
    );


    RayProcessor ray_processor1
    (
        .clk(clk),
        .reset_n(reset),
        .ray_dir_x(dirX1),
        .ray_dir_y(dirY1),
        .ray_dir_z(dirZ1),
        .camera_pos_x(cameraPosX),
        .camera_pos_y(cameraPosY),
        .camera_pos_z(cameraPosZ),
        .image_width(imageWidth),
        .image_height(imageHeight),
        .ready_external(ready1),
        .r(red1),
        .g(green1),
        .b(blue1),
        .ready_internal(ReadyInternal1),
        .valid_data_out(valid1),
        .last_x(lastX1),
        .sof(sof1),
        .address(addr1),
        .node(dout1),
        .ren(ren1),
        .loop_index(loopIndex1),
        .valid_dir(validDir1)
    );


    RayGenerator ray_generator2 
    (
        .clk(clk),
        .reset_n(reset),
        .ready_internal(ReadyInternal2),
        .ready_external(ready2),
        .camera_pos_x(cameraPosX),
        .camera_pos_y(cameraPosY),
        .camera_pos_z(cameraPosZ),
        .camera_dir_x(cameraDirX),
        .camera_dir_y(cameraDirY),
        .camera_dir_z(cameraDirZ),
        .camera_right_x(cameraRightX),
        .camera_right_y(cameraRightY),
        .camera_right_z(cameraRightZ),
        .camera_up_x(cameraUpX),
        .camera_up_y(cameraUpY),
        .camera_up_z(cameraUpZ),
        .image_width(imageWidth),
        .image_height(imageHeight),
        .ray_dir_x(dirX2),
        .ray_dir_y(dirY2),
        .ray_dir_z(dirZ2),
        .loop_index(loopIndex2),
        .op_code(2'b01),
        .core_number(3'b010),
        .en(1'b1),
        .val_dir(validDir2)
    );


    RayProcessor ray_processor2
    (
        .clk(clk),
        .reset_n(reset),
        .ray_dir_x(dirX2),
        .ray_dir_y(dirY2),
        .ray_dir_z(dirZ2),
        .camera_pos_x(cameraPosX),
        .camera_pos_y(cameraPosY),
        .camera_pos_z(cameraPosZ),
        .image_width(imageWidth),
        .image_height(imageHeight),
        .ready_external(ready2),
        .r(red2),
        .g(green2),
        .b(blue2),
        .ready_internal(ReadyInternal2),
        .valid_data_out(valid2),
        .last_x(lastX2),
        .sof(sof2),
        .address(addr2),
        .node(dout2),
        .ren(ren2),
        .loop_index(loopIndex2),
        .valid_dir(validDir2)
    );


    OctantRom OctantRom
    (
        .clk(clk),
        .addr1(addr1),
        .dout1(dout1),
        .addr2(addr2),
        .dout2(dout2),
        .ren1(ren1),
        .ren2(ren2)
    );

    PixelBuffer pixel_buffer
    (
        .aclk(clk),
        .aresetn(reset),
        .r1(red1),
        .r2(red2),
        .g1(green1),
        .g2(green2),
        .b1(blue1),
        .b2(blue2),
        .valid1(valid1),
        .valid2(valid2),
        .no_of_extra_cores(2'b01),
        .compute_ready_1(ready1),
        .compute_ready_2(ready2),
        .in_stream_ready_buff(ReadyExternal),
        .out_r(out_red),
        .out_g(out_green),
        .out_b(out_blue),
        .out_valid(validRead),
        .eol1(lastX1),
        .eol2(lastX2),
        .sof1(sof1),
        .sof2(sof2),
        .SOF_out(SOF_out),
        .EOL_out(EOL_out),
        .loop_index_1(loopIndex1),
        .loop_index_2(loopIndex2),
        .image_height(imageHeight),
        .image_width(imageWidth)
    );

endmodule