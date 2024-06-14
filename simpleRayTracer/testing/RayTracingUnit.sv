module RayTracingUnit
(
    input logic                 clk, reset,
    input logic [10:0]          cameraDirX, cameraDirY, cameraDirZ, cameraPosX, cameraPosY, cameraPosZ, cameraRightX, cameraRightY, cameraRightZ, cameraUpX, cameraUpY, cameraUpZ,
    input logic [12:0]          imageWidth, imageHeight,
    input logic                 ReadyExternal,
    output logic                validRead, SOF_out, EOL_out,
    output logic [7:0]          out_red, out_green, out_blue


);

    logic                       ReadyInternal1, ReadyInternal2, ReadyInternal3, ReadyInternal4;
    logic                       valid1, valid2, valid3, valid4;
    logic [31:0]                dirX1, dirX2, dirX3, dirX4; 
    logic [31:0]                dirY1, dirY2, dirY3, dirY4; 
    logic [31:0]                dirZ1, dirZ2, dirZ3, dirZ4;
    logic [31:0]                addr1;
    logic [31:0]                dout1;
    logic [31:0]                addr2;
    logic [31:0]                dout2;
    logic [31:0]                addr3;
    logic [31:0]                dout3;
    logic [31:0]                addr4;
    logic [31:0]                dout4;
    logic                       ren1, ren2, ren3, ren4;
    logic [7:0]                 red1, green1, blue1;
    logic [7:0]                 red2, green2, blue2;
    logic [7:0]                 red3, green3, blue3;
    logic [7:0]                 red4, green4, blue4;
    logic [31:0]                loopIndex1, loopIndex2, loopIndex3, loopIndex4;
    logic                       ready1, ready2, ready3, ready4;
    logic                       lastX1, lastX2, lastX3, lastX4;
    logic                       sof1, sof2, sof3, sof4;

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
        .op_code(2'b11),
        .core_number(3'b001),
        .en(1'b1)
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
        .core_number(3'b001)
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
        .op_code(2'b11),
        .core_number(3'b010),
        .en(1'b1)
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
        .core_number(3'b010)
    );


    
    RayGenerator ray_generator3 
    (
        .clk(clk),
        .reset_n(reset),
        .ready_internal(ReadyInternal3),
        .ready_external(ready3),
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
        .ray_dir_x(dirX3),
        .ray_dir_y(dirY3),
        .ray_dir_z(dirZ3),
        .loop_index(loopIndex3),
        .op_code(2'b11),
        .core_number(3'b011),
        .en(1'b1)
    );


    RayProcessor ray_processor3
    (
        .clk(clk),
        .reset_n(reset),
        .ray_dir_x(dirX3),
        .ray_dir_y(dirY3),
        .ray_dir_z(dirZ3),
        .camera_pos_x(cameraPosX),
        .camera_pos_y(cameraPosY),
        .camera_pos_z(cameraPosZ),
        .image_width(imageWidth),
        .image_height(imageHeight),
        .ready_external(ready3),
        .r(red3),
        .g(green3),
        .b(blue3),
        .ready_internal(ReadyInternal3),
        .valid_data_out(valid3),
        .last_x(lastX3),
        .sof(sof3),
        .address(addr3),
        .node(dout3),
        .ren(ren3),
        .loop_index(loopIndex3),
        .core_number(3'b011)
    );


        RayGenerator ray_generator4 
    (
        .clk(clk),
        .reset_n(reset),
        .ready_internal(ReadyInternal4),
        .ready_external(ready4),
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
        .ray_dir_x(dirX4),
        .ray_dir_y(dirY4),
        .ray_dir_z(dirZ4),
        .loop_index(loopIndex4),
        .op_code(2'b11),
        .core_number(3'b100),
        .en(1'b1)
    );


    RayProcessor ray_processor4
    (
        .clk(clk),
        .reset_n(reset),
        .ray_dir_x(dirX4),
        .ray_dir_y(dirY4),
        .ray_dir_z(dirZ4),
        .camera_pos_x(cameraPosX),
        .camera_pos_y(cameraPosY),
        .camera_pos_z(cameraPosZ),
        .image_width(imageWidth),
        .image_height(imageHeight),
        .ready_external(ready4),
        .r(red4),
        .g(green4),
        .b(blue4),
        .ready_internal(ReadyInternal4),
        .valid_data_out(valid4),
        .last_x(lastX4),
        .sof(sof4),
        .address(addr4),
        .node(dout4),
        .ren(ren4),
        .loop_index(loopIndex4),
        .core_number(3'b100)
    );




    octant_rom OctantRom
    (
        .clk(clk),
        .addr1(addr1),
        .dout1(dout1),
        .addr2(addr2),
        .dout2(dout2),
        .addr3(addr3),
        .dout3(dout3),
        .addr4(addr4),
        .dout4(dout4),
        .ren1(ren1),
        .ren2(ren2),
        .ren3(ren3),
        .ren4(ren4)
    );

    pixel_buffer pixel_buffer
    (
        .aclk(clk),
        .aresetn(reset),
        .r1(red1),
        .r2(red2),
        .r3(red3),
        .r4(red4),
        .g1(green1),
        .g2(green2),
        .g3(green3),
        .g4(green4),
        .b1(blue1),
        .b2(blue2),
        .b3(blue3),
        .b4(blue4),
        .valid1(valid1),
        .valid2(valid2),
        .valid3(valid3),
        .valid4(valid4),
        .no_of_extra_cores(3'b011),
        .compute_ready_1(ready1),
        .compute_ready_2(ready2),
        .compute_ready_3(ready3),
        .compute_ready_4(ready4),
        .in_stream_ready(ReadyExternal),
        .out_r(out_red),
        .out_g(out_green),
        .out_b(out_blue),
        .out_valid(validRead),
        .eol1(lastX1),
        .eol2(lastX2),
        .eol3(lastX3),
        .eol4(lastX4),
        .sof1(sof1),
        .sof2(sof2),
        .sof3(sof3),
        .sof4(sof4),
        .SOF_out(SOF_out),
        .EOL_out(EOL_out),
        .image_height(imageHeight),
        .image_width(imageWidth)
    );

endmodule
