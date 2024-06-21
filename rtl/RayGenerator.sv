module RayGenerator
(
    input logic             clk, reset_n, ready_internal, ready_external, en,
    input logic signed [11:0]      camera_pos_x, camera_pos_y, camera_pos_z,
    input logic signed [11:0]      camera_dir_x, camera_dir_y, camera_dir_z,
    input logic signed [11:0]      camera_right_x, camera_right_y, camera_right_z,
    input logic signed [11:0]      camera_up_x, camera_up_y, camera_up_z,
    // input logic signed [10:0]      camera_pos_x, camera_pos_y, camera_pos_z,
    // input logic signed [10:0]      camera_dir_x, camera_dir_y, camera_dir_z,
    // input logic signed [10:0]      camera_right_x, camera_right_y, camera_right_z,
    // input logic signed [10:0]      camera_up_x, camera_up_y, camera_up_z,
    input logic [12:0]      image_width, image_height,

    input logic [2:0]       core_number, 
    input logic [1:0]       op_code,

    input logic             val_dir,

    output logic signed [11:0]     ray_dir_x, ray_dir_y, ray_dir_z,
    output logic signed [31:0]     loop_index
    
);

    logic [2:0]             number_of_cores;
    logic                   valid_temp;

    logic [31:0]            line_count;
    logic signed [11:0]     temp1, temp2;

    typedef enum logic [3:0] { IDLE, CALCULATE_MU, CALCULATE_IMAGE, STALL, GENERATE_RAYS, GENERATE_RAYS2, CHECK_VALID, UPDATE_LOOP } state_t;

    state_t state, next_state;

    always_ff @(posedge clk) begin
        if (!reset_n) begin
            state <= IDLE;
        end else begin
            state <= next_state;
        end
        
    end

    always_ff @(posedge clk) begin
        if (!reset_n) begin
            loop_index <= 0;

        end else begin
            case (state)
                IDLE: begin
                    ray_dir_x <= 0;
                    ray_dir_y <= 0;
                    ray_dir_z <= 0;
                    loop_index <= core_number;
                    number_of_cores <= op_code + 1;
                    line_count <= 0;
                end 
                CALCULATE_MU: begin
                    // OLD
                end
                CALCULATE_IMAGE: begin
                    // OLD
                end
                STALL: begin

                end

                GENERATE_RAYS: begin
                    temp1 <= ((loop_index % image_width)-image_width/2);
                    temp2 <= (image_height/2 - (loop_index>>>8)); // presuming image width is 256 (2^8)
                end
                GENERATE_RAYS2: begin
                    if (loop_index < image_height * image_width + number_of_cores) begin

                        ray_dir_x <= (camera_right_x * temp1) + (camera_up_x * temp2) + camera_dir_x;
                        ray_dir_y <= (camera_right_y * temp1) + (camera_up_y * temp2) + camera_dir_y;
                        ray_dir_z <= (camera_right_z * temp1) + (camera_up_z * temp2) + camera_dir_z;
                    end
                end
                CHECK_VALID: begin
                    valid_temp <= ((ray_dir_x == 0) && (ray_dir_y == 0) && (ray_dir_z == 0));
                end
                UPDATE_LOOP: begin
                    loop_index <= loop_index + number_of_cores;
                end
            endcase
        end
    end

    always_comb begin
        next_state = state;
        case (state)
            IDLE: begin // 0
                if (en) begin
                    next_state = STALL;
                end else begin
                    next_state = IDLE;
                end
            end
            CALCULATE_MU: begin // 1
                next_state = CALCULATE_IMAGE;
            end
            CALCULATE_IMAGE: begin // 2
                next_state = STALL;
            end
            STALL: begin // 3
                if (loop_index >= image_height * image_width + 1 ) begin
                    next_state = IDLE; 
                end 
                
                else begin 
                    if (ready_internal) begin // maybe need a check to see if the loop index is currently like massive, so it can exit without waiting for ready 
                        next_state = GENERATE_RAYS;
                    end else begin
                        next_state = STALL;
                    end
                end
                

            end
            GENERATE_RAYS: begin // 4
                next_state = GENERATE_RAYS2;
            end
            GENERATE_RAYS2: begin
                next_state = CHECK_VALID;
            end
            CHECK_VALID: begin
                if (!valid_temp) begin
                    next_state = UPDATE_LOOP;
                end else begin
                    next_state = STALL;
                end
            end
            UPDATE_LOOP: begin // 5
                if (loop_index >= image_height * image_width + 1) begin
                    next_state = IDLE;
                end else begin
                    next_state = STALL;
                end
            end
        endcase
    end

endmodule
