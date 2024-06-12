/*
This module generates rays from the camera, knowing the image pixel height and width
OVERVIEW:
- We have a camera at a point, pointing in a certain direction.
- So the "default ray" is given by r = cam_pos + mu * cam_dir
- We set this to point to the centre of the image, at a distance, d, away from the camera
- This distance is provided as an input
- We can then determine the centre of the generated image and where it is in out coordinate space by working out mu for the provided distance
- From the centre, we can work out the coordinates of every pixel, knowing the image size
- From this, we can work out the direction vector from the camera to the pixel.

SOME BUGS/ OTHER POINTS:
- First few clock cycles used to load values that can be reused so we get 0s in the output for the first few.
- Last direction vector is repeated
*/

module RayGenerator
(
    input logic             clk, reset_n, ready_internal, ready_external,
    input logic [10:0]      camera_pos_x, camera_pos_y, camera_pos_z,
    input logic [10:0]      camera_dir_x, camera_dir_y, camera_dir_z,
    input logic [10:0]      camera_right_x, camera_right_y, camera_right_z,
    input logic [10:0]      camera_up_x, camera_up_y, camera_up_z,
    input logic [12:0]      image_width, image_height,
    // input logic [31:0]      distance,
    output logic [31:0]     ray_dir_x, ray_dir_y, ray_dir_z,
    output logic [31:0]     loop_index

    // Debugging signals:
    // output logic [1:0]      curr_state,
    // output logic [31:0]     pixel_x, pixel_y, 
    // output logic [31:0]     image_center_x, image_center_y,
    // output logic [31:0]     mu
    // output logic [31:0]     loop_index

);

    logic [31:0]            image_center_x, image_center_y;
    logic [31:0]            mu;
    // logic [31:0]            loop_index;
    // logic [31:0]            pixel_x, pixel_y;
    // logic [31:0]            column_number, row_number,

    typedef enum logic [2:0] { IDLE, CALCULATE_MU, CALCULATE_IMAGE, STALL, GENERATE_RAYS, UPDATE_LOOP } state_t;

    state_t state, next_state;

    always_ff @(posedge clk) begin
        if (reset_n) begin
            state <= STALL;
        end else begin
            state <= next_state;
        end
        
    end

    always_ff @(posedge clk) begin
        if (reset_n) begin
            mu <= 0;
            image_center_x <= 0;
            image_center_y <= 0;
            loop_index <= 0;
            // pixel_x <= 0;
            // pixel_y <= 0;
        end else begin
            case (state)
                IDLE: begin
                    // For debugging visualisation
                    ray_dir_x <= 0;
                    ray_dir_y <= 0;
                    ray_dir_z <= 0;
                    // OLD:
                    // loop_index <= 1;
                    loop_index <= 1;
                end 
                CALCULATE_MU: begin
                    /* verilator lint_off WIDTH */
                    // OLD:
                    // mu <= distance - camera_pos_z;




                    // row_number <= loop_index / image_width;
                    // column_number <= loop_index % image_width;




                    /* verilator lint_on WIDTH */
                end
                CALCULATE_IMAGE: begin
                    /* verilator lint_off WIDTH */

                    // OLD:
                    // image_center_x <= camera_pos_x + mu * camera_dir_x;
                    // image_center_y <= camera_pos_y + mu * camera_dir_y;
                    /* verilator lint_on WIDTH */
                end
                STALL: begin
                end
                GENERATE_RAYS: begin
                        if (loop_index < image_height * image_width) begin
                            //* verilator lint_off WIDTH */
                            // pixel_x <= image_center_x + (loop_index % image_width) - (image_width / 2);
                            // pixel_y <= image_center_y - (loop_index / image_width) + (image_height / 2) - 1;
                            
                            // OLD:
                            // ray_dir_x <= (image_center_x + (loop_index % image_width) - (image_width / 2)) - camera_pos_x;
                            // ray_dir_y <= (image_center_y - (loop_index / image_width) + (image_height / 2)-1)- camera_pos_y;
                            // ray_dir_z <= distance;

                            //loop_index <= loop_index + 1;
                            // ray_dir_x <= pixel_x - camera_pos_x;
                            // ray_dir_y <= pixel_y - camera_pos_y;
                            // ray_dir_z <= distance;
                            /* verilator lint_on WIDTH */

                            ray_dir_x <= (camera_right_x * ((loop_index % image_width)-image_width/2)) + (camera_up_x * (image_height/2 - (loop_index / image_width))) + camera_dir_x;
                            ray_dir_y <= (camera_right_y * ((loop_index % image_width)-image_width/2)) + (camera_up_y * (image_height/2 - (loop_index / image_width))) + camera_dir_y;
                            ray_dir_z <= (camera_right_z * ((loop_index % image_width)-image_width/2)) + (camera_up_z * (image_height/2 - (loop_index / image_width))) + camera_dir_z;
                        end
                end
                UPDATE_LOOP: begin
                    loop_index <= loop_index + 1;
                end
            endcase
        end
    end

    always_comb begin
        // curr_state = state; <- debugging
        next_state = state;
        case (state)
            IDLE: begin // 0
                next_state = CALCULATE_MU;
                // loop_index = 0;
            end
            CALCULATE_MU: begin // 1
                next_state = CALCULATE_IMAGE;
            end
            CALCULATE_IMAGE: begin // 2
                next_state = STALL;
            end
            STALL: begin // 3
                if (ready_internal) begin
                    next_state = GENERATE_RAYS;
                end else begin
                    next_state = STALL;
                end
            end
            GENERATE_RAYS: begin // 4
                next_state = UPDATE_LOOP;
            end
            UPDATE_LOOP: begin // 5
                if (loop_index > image_height * image_width) begin
                    // loop_index = 0;
                    next_state = IDLE;
                end else begin
                    // loop_index = loop_index + 1;
                    next_state = STALL;
                end
            end
        endcase
    end

endmodule
