module RayGenerator
(
    input logic             clk, reset_n, ready_internal, ready_external, en,
    input logic [10:0]      camera_pos_x, camera_pos_y, camera_pos_z,
    input logic [10:0]      camera_dir_x, camera_dir_y, camera_dir_z,
    input logic [10:0]      camera_right_x, camera_right_y, camera_right_z,
    input logic [10:0]      camera_up_x, camera_up_y, camera_up_z,
    input logic [12:0]      image_width, image_height,

    input logic [2:0]       core_number, 
    input logic [1:0]       op_code,

    output logic [31:0]     ray_dir_x, ray_dir_y, ray_dir_z,
    output logic [31:0]     loop_index
);

    logic [2:0]             number_of_cores;

    typedef enum logic [2:0] { IDLE, CALCULATE_MU, CALCULATE_IMAGE, STALL, GENERATE_RAYS, UPDATE_LOOP } state_t;

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
                    loop_index <= core_number + 3;
                    number_of_cores <= op_code + 1;
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
                        if (loop_index < image_height * image_width) begin

                            ray_dir_x <= (camera_right_x * ((loop_index % image_width)-image_width/2)) + (camera_up_x * (image_height/2 - (loop_index / image_width))) + camera_dir_x;
                            ray_dir_y <= (camera_right_y * ((loop_index % image_width)-image_width/2)) + (camera_up_y * (image_height/2 - (loop_index / image_width))) + camera_dir_y;
                            ray_dir_z <= (camera_right_z * ((loop_index % image_width)-image_width/2)) + (camera_up_z * (image_height/2 - (loop_index / image_width))) + camera_dir_z;
                        end
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
                    next_state = CALCULATE_MU;
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
                    next_state = IDLE;
                end else begin
                    next_state = STALL;
                end
            end
        endcase
    end

endmodule
