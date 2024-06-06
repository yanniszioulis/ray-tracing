/*
This module will take as input the direction vector of a ray and position of the camera (position vector), it will step the ray through octants until it is out of bounds, then it returns the background colour - 55, 55, 55

*/

module RayProcessor #(
    parameter COORD_BIT_LEN = 10
)(
    input logic                             clk, reset_n,
    input logic [31:0]                      ray_dir_x, ray_dir_y, ray_dir_z,
    input logic [COORD_BIT_LEN:0]           camera_pos_x, camera_pos_y, camera_pos_z,
    input logic [12:0]                      image_width, image_height,
    output logic [7:0]                      r, g, b,
    output logic                            ready_internal,                      // signal to go back to ray gen to tell it to generate new ray
    output logic                            valid_data_out,             // signal to next block/ buffer to read output from ray processor
    output logic                            last_x,
    output logic                            sof

);

    // Logic for state transitions:
    logic                       valid;                      // whether an input vector is a valid direction vector
    logic [1:0]                 received_material_id;       // check what material we have
    logic                       dir_big_enough;             // logic to check whether the direction vector is big enough for the current octant
    logic                       just_outside_AABB;          // logic to see whether we are just outside an AABB
    logic                       within_world;               // check if the ray is in the given envrionment
    
    logic [31:0]                loop_index;                 // keep track of loop count

    // World setup
    logic [COORD_BIT_LEN:0]     world_size;
    logic [COORD_BIT_LEN:0]     oct_size;
    logic [COORD_BIT_LEN-1:0]   world_max_x;
    logic [COORD_BIT_LEN-1:0]   world_max_y;
    logic [COORD_BIT_LEN-1:0]   world_max_z;
    logic [COORD_BIT_LEN-1:0]   aabb_min_x;
    logic [COORD_BIT_LEN-1:0]   aabb_min_y;
    logic [COORD_BIT_LEN-1:0]   aabb_min_z;
    logic [COORD_BIT_LEN-1:0]   aabb_max_x;
    logic [COORD_BIT_LEN-1:0]   aabb_max_y;
    logic [COORD_BIT_LEN-1:0]   aabb_max_z; 

    reg signed [31:0]           reg_ray_dir_x;
    reg signed [31:0]           reg_ray_dir_y;
    reg signed [31:0]           reg_ray_dir_z;

    reg                         underflow_x;
    reg                         underflow_y;
    reg                         underflow_z;

    reg signed [31:0]           curr_ray_dir_x;  
    reg signed [31:0]           curr_ray_dir_y;
    reg signed [31:0]           curr_ray_dir_z;      

    // Ray setup.
    logic [COORD_BIT_LEN-1:0]   ray_pos_x;
    logic [COORD_BIT_LEN-1:0]   ray_pos_y;
    logic [COORD_BIT_LEN-1:0]   ray_pos_z;

    // Octree setup
    logic [31:0]                node [0:7];

    // Traversal intermediate logic
    int                         depth;
    logic [2:0]                 octant_no; 

    // Ray stepping intermediate logic            
  
    logic                       just_outside_x;
    logic                       just_outside_y;
    logic                       just_outside_z;


    logic [COORD_BIT_LEN-1:0]   temp_ray_pos_x;
    logic [COORD_BIT_LEN-1:0]   temp_ray_pos_y;
    logic [COORD_BIT_LEN-1:0]   temp_ray_pos_z;

    logic                       within_x;
    logic                       within_y;
    logic                       within_z;
    logic                       within_world_x;
    logic                       within_world_y;
    logic                       within_world_z;

    logic [7:0]                 temp_r;
    logic [7:0]                 temp_g;
    logic [7:0]                 temp_b;
    
    int                         index;

    logic [31:0]                magnitude_squared;
    logic [31:0]                oct_size_squared;
    logic                       in_range;
    logic [31:0]                count;

    typedef enum logic [3:0] { 
        INITIALISE,                     // 0
        IDLE,                           // 1
        RAY_TRAVERSE_INITIALISE,        // 2
        RAY_TRAVERSE_OCTANT_NO,         // 3
        RAY_TRAVERSE_ADJUST,            // 4                           
        RAY_TRAVERSE_UPDATE,            // 5
        RAY_STEP_ADJUST_DIR_VEC,        // 6
        RAY_STEP_CHECK_PROXIMITY,       // 7
        RAY_STEP,                       // 8
        RAY_STEP_POSITION_CALC,         // 9
        STALL,                          // 9.5
        RAY_STEP_CHECK,                 // 10
        RAY_STEP_BRANCH,                // 11
        COLOUR_FORMAT,                  // 12
        RAY_OUT_OF_BOUND,               // 13
        OUTPUT_COLOUR                   // 14
     } state_t;

     state_t state, next_state;

    always_ff @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            state <= INITIALISE;
        end else begin
            state <= next_state;
        end
    end

    always_ff @(posedge clk) begin

        case (state)
            INITIALISE: begin // 0

                ready_internal <= 0;
                valid_data_out <= 0;
                world_size <= 2**COORD_BIT_LEN;
                oct_size <= 2**(COORD_BIT_LEN-1); // hard coded

                /* verilator lint_off WIDTH */
                world_max_x <= world_size - 1;
                world_max_y <= world_size - 1;
                world_max_z <= world_size - 1;
                /* verilator lint_on WIDTH */

                aabb_min_x <= 0;
                aabb_min_y <= 0;
                aabb_min_z <= 0;

                /* verilator lint_off WIDTH */
                aabb_max_x <= world_size - 1;
                aabb_max_y <= world_size - 1;
                aabb_max_z <= world_size - 1;

                ray_pos_x <= camera_pos_x;
                ray_pos_y <= camera_pos_y;
                ray_pos_z <= camera_pos_z;

                temp_ray_pos_x <= 0;
                temp_ray_pos_y <= 0;
                temp_ray_pos_z <= 0;

                just_outside_x <= 0;
                just_outside_y <= 0;
                just_outside_z <= 0;

               

                just_outside_AABB <= 0; 
                within_world <= 1;
                //octant_no <= 0;
                dir_big_enough <= 0;
                received_material_id <= 0;
                index <= 0;
                /* verilator lint_on WIDTH */

                node[0] <= 0;
                node[1] <= 0;
                node[2] <= 0;
                node[3] <= 0;
                node[4] <= 0;
                node[5] <= 2;
                node[6] <= 0;
                node[7] <= 1;


            end
            IDLE: begin // 1
                
                valid_data_out <= 0;

                if (ray_dir_z == 0) begin
                    valid <= 0;
                    ready_internal <= 1;
                end else if (loop_index == 0 && ((ray_dir_x == 0) || (ray_dir_y == 0))) begin 
                    valid <= 0;
                    ready_internal <= 0;
                end else begin 
                    valid <= 1;
                    ready_internal <= 0;
                end

                reg_ray_dir_x <= ray_dir_x;
                reg_ray_dir_y <= ray_dir_y;
                reg_ray_dir_z <= ray_dir_z;

                curr_ray_dir_x <= ray_dir_x;
                curr_ray_dir_y <= ray_dir_y;
                curr_ray_dir_z <= ray_dir_z;

            end
            RAY_TRAVERSE_INITIALISE: begin // 2
                
                reg_ray_dir_x <= curr_ray_dir_x;
                reg_ray_dir_y <= curr_ray_dir_y;
                reg_ray_dir_z <= curr_ray_dir_z;

                depth <= 0;
                index <= COORD_BIT_LEN-1-depth; // check for depth updates in seperate module

            end
            RAY_TRAVERSE_OCTANT_NO: begin // 3

                octant_no <= {ray_pos_z[index], ray_pos_y[index], ray_pos_x[index]};
                dir_big_enough <= 0;
                in_range <= 0;

            end
            RAY_TRAVERSE_ADJUST: begin // 4 - DETERMINING MIN AABB COORDINATES

                received_material_id <= node[octant_no]; // TODO (hard coded for now) this will change - will proably be the address of the first sub child + octant_no

                aabb_min_x <= octant_no[0] * oct_size;
                aabb_min_y <= octant_no[1] * oct_size;
                aabb_min_z <= octant_no[2] * oct_size;

            end
            RAY_TRAVERSE_UPDATE: begin // 5 DETERMINE MAX AABB COORDINATES

                /* verilator lint_off WIDTH */

                aabb_max_x <= aabb_min_x + oct_size - 1;
                aabb_max_y <= aabb_min_y + oct_size - 1;
                aabb_max_z <= aabb_min_z + oct_size - 1;

                /* verilator lint_on WIDTH */


                // calculate magnitude 

                magnitude_squared <= reg_ray_dir_x*reg_ray_dir_x + reg_ray_dir_y*reg_ray_dir_y + reg_ray_dir_z*reg_ray_dir_z;
                oct_size_squared <= oct_size * oct_size;
                
            end
            RAY_STEP_ADJUST_DIR_VEC: begin // 6

                if( magnitude_squared < oct_size_squared) begin
                    reg_ray_dir_x <= reg_ray_dir_x <<< 1;
                    reg_ray_dir_y <= reg_ray_dir_y <<< 1;
                    reg_ray_dir_z <= reg_ray_dir_z <<< 1;
                    dir_big_enough <= 0;
                end else begin
                    dir_big_enough <= 1;
                end

            end
            RAY_STEP_CHECK_PROXIMITY: begin // 7

                temp_ray_pos_x <= ray_pos_x + reg_ray_dir_x;
                temp_ray_pos_y <= ray_pos_y + reg_ray_dir_y;
                temp_ray_pos_z <= ray_pos_z + reg_ray_dir_z;

            end
            RAY_STEP: begin // 8

                within_x <= (temp_ray_pos_x >= aabb_min_x && temp_ray_pos_x <= aabb_max_x) ? 1 : 0;
                within_y <= (temp_ray_pos_y >= aabb_min_y && temp_ray_pos_y <= aabb_max_y) ? 1 : 0;
                within_z <= (temp_ray_pos_z >= aabb_min_z && temp_ray_pos_z <= aabb_max_z) ? 1 : 0;
                
                just_outside_x <= (temp_ray_pos_x == aabb_min_x - 1 || temp_ray_pos_x == aabb_max_x + 1) ? 1 : 0;
                just_outside_y <= (temp_ray_pos_y == aabb_min_y - 1 || temp_ray_pos_y == aabb_max_y + 1) ? 1 : 0;
                just_outside_z <= (temp_ray_pos_z == aabb_min_z - 1 || temp_ray_pos_z == aabb_max_z + 1) ? 1 : 0;

                within_world_x <= (temp_ray_pos_x + 1<= world_max_x) ? 1 : 0;
                within_world_y <= (temp_ray_pos_y + 1<= world_max_y) ? 1 : 0;
                within_world_z <= (temp_ray_pos_z + 1<= world_max_z) ? 1 : 0;

                in_range <= 0; 

            end
            RAY_STEP_POSITION_CALC: begin // 9
                within_world <= within_world_x && within_world_y && within_world_z;
                just_outside_AABB <= (just_outside_x&&just_outside_y&&just_outside_z)||(just_outside_x&&just_outside_y&&within_z)||(just_outside_x&&within_y&&just_outside_z)||(just_outside_x&&within_y&&within_z)||(within_x&&just_outside_y&&just_outside_z)||(within_x&&within_y&&just_outside_z)||(within_x&&just_outside_y&&within_z);
                in_range <= ((within_x && within_y && within_z) ||(just_outside_x&&just_outside_y&&just_outside_z)||(just_outside_x&&just_outside_y&&within_z)||(just_outside_x&&within_y&&just_outside_z)||(just_outside_x&&within_y&&within_z)||(within_x&&just_outside_y&&just_outside_z)||(within_x&&within_y&&just_outside_z)||(within_x&&just_outside_y&&within_z));
            
            end
            STALL: begin //10
            end
            RAY_STEP_CHECK: begin // 11


                if (in_range) begin
                    ray_pos_x <= temp_ray_pos_x;
                    ray_pos_y <= temp_ray_pos_y;
                    ray_pos_z <= temp_ray_pos_z;
                end


                // Block below: for more accurate direction vector.

                // if(reg_ray_dir_x == 1) begin
                //     underflow_x <= 1;
                //     if(underflow_x == 0 || (reg_ray_dir_y == 0 || reg_ray_dir_z == 0) || (underflow_x == 1 && underflow_y == 1 && underflow_z == 1) ) begin
                //         reg_ray_dir_x <= 1;
                //     end
                // end
                // else begin
                //     reg_ray_dir_x <= reg_ray_dir_x >>> 1;
                // end

                // if(reg_ray_dir_y == 1) begin
                //     underflow_y <= 1;
                //     if(underflow_y == 0 || (reg_ray_dir_x == 0 || reg_ray_dir_z == 0) || (underflow_x == 1 && underflow_y == 1 && underflow_z == 1)) begin
                //         reg_ray_dir_y <= 1;
                //     end
                // end
                // else begin
                //     reg_ray_dir_y <= reg_ray_dir_y >>> 1;
                // end

                // if(reg_ray_dir_z == 1) begin
                //     underflow_z <= 1;
                //     if(underflow_z == 0 || (reg_ray_dir_x == 0 || reg_ray_dir_y == 0) || (underflow_x == 1 && underflow_y == 1 && underflow_z == 1)) begin
                //         reg_ray_dir_z <= 1;
                //     end
                // end
                // else begin
                //     reg_ray_dir_z <= reg_ray_dir_z >>> 1;
                // end
                
                
                // Less accurate direction vector:

                reg_ray_dir_x <= (reg_ray_dir_x == 1) ? 1 : reg_ray_dir_x >>> 1;
                reg_ray_dir_y <= (reg_ray_dir_y == 1) ? 1 : reg_ray_dir_y >>> 1;
                reg_ray_dir_z <= (reg_ray_dir_z == 1) ? 1 : reg_ray_dir_z >>> 1;
                
            end
            RAY_STEP_BRANCH: begin // 12

                ray_pos_x <= temp_ray_pos_x;
                ray_pos_y <= temp_ray_pos_y;
                ray_pos_z <= temp_ray_pos_z;

                within_world_x <= (temp_ray_pos_x <= world_max_x) ? 1 : 0;
                within_world_y <= (temp_ray_pos_y <= world_max_y) ? 1 : 0;
                within_world_z <= (temp_ray_pos_z <= world_max_z) ? 1 : 0;

                within_world <= within_world_x && within_world_y && within_world_z;

            end
            COLOUR_FORMAT: begin // 13
                case(received_material_id) 
                    1: begin
                        temp_r <= 255; 
                        temp_g <= 255; 
                        temp_b <= 255;
                    end
                    2: begin
                        temp_r <= 0; 
                        temp_g <= 255; 
                        temp_b <= 0;
                    end
                    default: $stop;
                endcase

            end
            RAY_OUT_OF_BOUND: begin // 14
                
                // INFO: Change background colour here
                temp_r <= 0; 
                temp_g <= 0; 
                temp_b <= 0;

            end
            OUTPUT_COLOUR: begin // 15
                
                r <= temp_r;
                g <= temp_g;
                b <= temp_b;
                valid_data_out <= 1;
                ready_internal <= 1;
                loop_index <= loop_index + 1; 

                if (loop_index  % image_width == 0) begin
                    last_x <= 1;
                    count <= count + 1;
                end else begin
                    last_x <= 0;
                end

                if (loop_index == 0) begin
                    sof <= 1;
                end else begin
                    sof <= 0;
                end

            end
        default: $stop;
        endcase
        
    end

    always_comb begin
        next_state = state;
        case (state)
            INITIALISE: begin // 0
                next_state = IDLE;
            end
            IDLE: begin // 1
                next_state = valid ? RAY_TRAVERSE_INITIALISE : IDLE;
            end
            RAY_TRAVERSE_INITIALISE: begin // 2
                next_state = RAY_TRAVERSE_OCTANT_NO;
            end
            RAY_TRAVERSE_OCTANT_NO: begin // 3
                next_state = RAY_TRAVERSE_ADJUST;
            end
            RAY_TRAVERSE_ADJUST: begin // 4
                next_state = RAY_TRAVERSE_UPDATE;
            end
            RAY_TRAVERSE_UPDATE: begin // 5

                if (received_material_id != 0) begin
                    next_state = COLOUR_FORMAT;
                end else begin
                    next_state = RAY_STEP_ADJUST_DIR_VEC;
                end
                
            end
            RAY_STEP_ADJUST_DIR_VEC: begin // 6
                next_state = dir_big_enough ? RAY_STEP_CHECK_PROXIMITY : RAY_TRAVERSE_UPDATE;
            end
            RAY_STEP_CHECK_PROXIMITY: begin // 7
                next_state = RAY_STEP;
            end
            RAY_STEP: begin // 8
                next_state = RAY_STEP_POSITION_CALC;
            end
            RAY_STEP_POSITION_CALC: begin // 9
                next_state = STALL;
            end
            STALL: begin //10
                if (!within_world) begin
                    next_state = RAY_OUT_OF_BOUND;
                end else if (just_outside_AABB) begin
                    next_state = RAY_STEP_BRANCH;
                end else begin
                    next_state = RAY_STEP_CHECK;
                end
            end
            RAY_STEP_CHECK: begin // 11
                next_state = (in_range) ? RAY_STEP_CHECK_PROXIMITY : RAY_STEP_CHECK_PROXIMITY;
            end
            RAY_STEP_BRANCH: begin // 12
                next_state = within_world ? RAY_TRAVERSE_INITIALISE : RAY_OUT_OF_BOUND;
            end
            COLOUR_FORMAT: begin // 13
                next_state = OUTPUT_COLOUR;
            end
            RAY_OUT_OF_BOUND: begin // 14
                next_state = OUTPUT_COLOUR;
            end
            OUTPUT_COLOUR: begin // 15
                if (loop_index > image_height * image_width) begin
                    next_state = IDLE;
                end else begin
                    next_state = INITIALISE;
                end
            end
            default: $stop;
        endcase
     end

endmodule
