/*
This module will take as input the direction vector of a ray and position of the camera (position vector), it will step the ray through octants until it is out of bounds, then it returns the background colour - 55, 55, 55

*/

module RayProcessor #(
    parameter COORD_BIT_LEN = 10
)(
    input logic                 clk, reset_n,
    input logic [31:0]          ray_dir_x, ray_dir_y, ray_dir_z,
    input logic [7:0]           camera_pos_x, camera_pos_y, camera_pos_z,
    input logic [12:0]          image_width, image_height,
    output logic [7:0]          r, g, b,
    output logic                ready,                      // signal to go back to ray gen to tell it to generate new ray
    output logic                valid_data_out,              // signal to next block/ buffer to read output from ray processor

    output logic [3:0]          curr_state
);

    // Logic for state transitions:
    logic                       valid;                      // whether an input vector is a valid direction vector
    logic                       valid_depth;                // condition for octree traversal - when to break out of loop
    logic [1:0]                 received_material_id;       // check what material we have
    logic                       dir_big_enough;             // logic to check whether the direction vector is big enough for the current octant
    logic                       just_outside_AABB;          // logic to see whether we are just outside an AABB
    logic                       temp_just_outside_AABB;
    logic                       within_world;               // check if the ray is in the given envrionment
    
    logic [31:0]                loop_index;                 // keep track of loop count

    // World setup
    logic [COORD_BIT_LEN:0]     world_size;
    logic [COORD_BIT_LEN:0]     oct_size;
    // logic [COORD_BIT_LEN-1:0]   world_min_x;
    // logic [COORD_BIT_LEN-1:0]   world_min_y;
    // logic [COORD_BIT_LEN-1:0]   world_min_z;
    logic [COORD_BIT_LEN-1:0]   world_max_x;
    logic [COORD_BIT_LEN-1:0]   world_max_y;
    logic [COORD_BIT_LEN-1:0]   world_max_z;
    logic [COORD_BIT_LEN-1:0]   aabb_min_x;
    logic [COORD_BIT_LEN-1:0]   aabb_min_y;
    logic [COORD_BIT_LEN-1:0]   aabb_min_z;
    logic [COORD_BIT_LEN-1:0]   aabb_max_x;
    logic [COORD_BIT_LEN-1:0]   aabb_max_y;
    logic [COORD_BIT_LEN-1:0]   aabb_max_z; 

    logic [31:0]                reg_ray_dir_x;
    logic [31:0]                reg_ray_dir_y;
    logic [31:0]                reg_ray_dir_z;

    // Ray setup.
    logic [COORD_BIT_LEN-1:0]   ray_pos_x;
    logic [COORD_BIT_LEN-1:0]   ray_pos_y;
    logic [COORD_BIT_LEN-1:0]   ray_pos_z;

    // Octree setup
    // logic [31:0]                root;
    logic [31:0]                node [0:7];
    // logic [31:0]                octree [0:7];

    // Traversal intermediate logic
    logic [31:0]                depth;
    logic [2:0]                 octant_no; 

    // Ray stepping intermediate logic            
    logic                       just_outside_x;
    logic                       just_outside_y;
    logic                       just_outside_z;
    logic                       temp_just_outside_x;
    logic                       temp_just_outside_y;
    logic                       temp_just_outside_z;
    
    logic [COORD_BIT_LEN-1:0]   temp_ray_pos_x;
    logic [COORD_BIT_LEN-1:0]   temp_ray_pos_y;
    logic [COORD_BIT_LEN-1:0]   temp_ray_pos_z;
    logic                       within_x;
    logic                       within_y;
    logic                       within_z;
    logic                       within_AABB;
    logic                       within_world_x;
    logic                       within_world_y;
    logic                       within_world_z;

    logic [7:0]                 temp_r;
    logic [7:0]                 temp_g;
    logic [7:0]                 temp_b;

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
        RAY_STEP_POSITION_CALC,
        RAY_STEP_CHECK,                 // 9
        RAY_STEP_BRANCH,                // 10
        COLOUR_FORMAT,                  // 11
        RAY_OUT_OF_BOUND,               // 12
        OUTPUT_COLOUR                   // 13
     } state_t;

     state_t state, next_state;

    always_ff @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            state <= INITIALISE;
        end else begin
            state <= next_state;
        end
    end

    always_ff @(posedge clk or negedge reset_n) begin
        curr_state <= state;
        if (!reset_n) begin
            
        end else begin
            case (state)
                INITIALISE: begin // 0

                    ready <= 0;
                    valid_data_out <= 0;

                    world_size <= 2**COORD_BIT_LEN;
                    oct_size <= 2**COORD_BIT_LEN;

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
                    /* verilator lint_on WIDTH */

                    // TODO: this array initialisation needs to move - shouldn't be repeated for each ray.
                    // octree[0] <= 0;
                    // octree[1] <= 0;
                    // octree[2] <= 0;
                    // octree[3] <= 0;
                    // octree[4] <= 2;
                    // octree[5] <= 0;
                    // octree[6] <= 0;
                    // octree[7] <= 1;

                    node[0] <= 0;
                    node[1] <= 0;
                    node[2] <= 0;
                    node[3] <= 0;
                    node[4] <= 2;
                    node[5] <= 0;
                    node[6] <= 0;
                    node[7] <= 1;


                end
                IDLE: begin // 1
                    
                    valid_data_out <= 0;

                    if (ray_dir_z == 0) begin
                        valid <= 0;
                        ready <= 1;
                    end else if (loop_index == 0 && ((ray_dir_x == 0) || (ray_dir_y == 0))) begin
                        valid <= 0;
                        ready <= 0;
                    end else begin 
                        valid <= 1;
                        ready <= 0;
                    end

                    reg_ray_dir_x <= ray_dir_x;
                    reg_ray_dir_y <= ray_dir_y;
                    reg_ray_dir_z <= ray_dir_z;

                end
                RAY_TRAVERSE_INITIALISE: begin // 2
                    
                    depth <= 0;

                end
                RAY_TRAVERSE_OCTANT_NO: begin // 3

                    octant_no <= 4 * ray_pos_z[depth] + 2 * ray_pos_y[depth] + 1 * ray_pos_x[depth];

                end
                RAY_TRAVERSE_ADJUST: begin // 4

                    depth <= depth + 1;
                    oct_size <= oct_size >> 1; 

                end
                RAY_TRAVERSE_UPDATE: begin // 5

                    /* verilator lint_off WIDTH */
                    aabb_min_x <= aabb_min_x + oct_size * ray_pos_x[depth-1];
                    aabb_min_y <= aabb_min_y + oct_size * ray_pos_y[depth-1];
                    aabb_min_z <= aabb_min_z + oct_size * ray_pos_z[depth-1];

                    aabb_max_x <= aabb_min_x + oct_size - 1;
                    aabb_max_y <= aabb_min_y + oct_size - 1;
                    aabb_max_z <= aabb_min_z + oct_size - 1;

                    received_material_id <= node[octant_no]; // TODO (hard coded for now) this will change - will proably be the address of the first sub child + octant_no
                    /* verilator lint_on WIDTH */

                    valid_depth <= (depth < COORD_BIT_LEN) ? 1 : 0;
                end
                RAY_STEP_ADJUST_DIR_VEC: begin // 6

                    if(reg_ray_dir_x*reg_ray_dir_x + reg_ray_dir_y*reg_ray_dir_y + reg_ray_dir_z*reg_ray_dir_z < oct_size*oct_size) begin
                        reg_ray_dir_x <= reg_ray_dir_x << 1;
                        reg_ray_dir_y <= reg_ray_dir_y << 1;
                        reg_ray_dir_z <= reg_ray_dir_z << 1;
                        dir_big_enough <= 0;
                    end else begin
                        dir_big_enough <= 1;
                    end

                end
                RAY_STEP_CHECK_PROXIMITY: begin // 7
                    
                    if (ray_pos_x == aabb_min_x - 1 || ray_pos_x == aabb_max_x + 1) begin
                        just_outside_x <= 1;
                    end else begin
                        just_outside_x <= 0;
                    end

                    if (ray_pos_y == aabb_min_y - 1 || ray_pos_y == aabb_max_y + 1) begin
                        just_outside_y <= 1;
                    end else begin
                        just_outside_y <= 0;
                    end

                    if (ray_pos_z == aabb_min_z - 1 || ray_pos_z == aabb_max_z + 1) begin
                        just_outside_z <= 1;
                    end else begin
                        just_outside_z <= 0;
                    end

                    just_outside_AABB <= just_outside_x && just_outside_y && just_outside_z;

                end
                RAY_STEP: begin // 8

                    /* verilator lint_off WIDTH */
                    temp_ray_pos_x <= ray_pos_x + reg_ray_dir_x;
                    temp_ray_pos_y <= ray_pos_y + reg_ray_dir_y;
                    temp_ray_pos_z <= ray_pos_z + reg_ray_dir_z;
                    /* verilator lint_on WIDTH */
                    


                end
                RAY_STEP_POSITION_CALC: begin

                    within_x <= (temp_ray_pos_x >= aabb_min_x && temp_ray_pos_x <= aabb_max_x) ? 1 : 0;
                    within_y <= (temp_ray_pos_y >= aabb_min_y && temp_ray_pos_y <= aabb_max_y) ? 1 : 0;
                    within_z <= (temp_ray_pos_z >= aabb_min_z && temp_ray_pos_z <= aabb_max_z) ? 1 : 0;

                    //within_AABB <= within_x && within_y && within_z;


                    if (temp_ray_pos_x == aabb_min_x - 1 || temp_ray_pos_x == aabb_max_x + 1) begin
                        temp_just_outside_x <= 1;
                    end else begin
                        temp_just_outside_x <= 0;
                    end

                    if (temp_ray_pos_y == aabb_min_y - 1 || temp_ray_pos_y == aabb_max_y + 1) begin
                        temp_just_outside_y <= 1;
                    end else begin
                        temp_just_outside_y <= 0;
                    end

                    if (temp_ray_pos_z == aabb_min_z - 1 || temp_ray_pos_z == aabb_max_z + 1) begin
                        temp_just_outside_z <= 1;
                    end else begin
                        temp_just_outside_z <= 0;
                    end

                    //temp_just_outside_AABB <= temp_just_outside_x && temp_just_outside_y && temp_just_outside_z;
                
                end
                RAY_STEP_CHECK: begin // 9


                    if ((within_x && within_y && within_z) || (within_x && temp_just_outside_y && within_z) || (within_x && within_y && temp_just_outside_z) || (within_x && temp_just_outside_y && temp_just_outside_z) || (temp_just_outside_x && temp_just_outside_y && temp_ray_pos_z) || (temp_just_outside_x && within_y && temp_ray_pos_z) || (temp_just_outside_x && temp_just_outside_y && within_z) || (temp_just_outside_x && within_y && within_z)) begin
                        ray_pos_x <= (temp_ray_pos_x >= aabb_max_x) ? aabb_max_x : temp_ray_pos_x;
                        ray_pos_y <= (temp_ray_pos_y >= aabb_max_y) ? aabb_max_y : temp_ray_pos_y;
                        ray_pos_z <= (temp_ray_pos_z >= aabb_max_z) ? aabb_max_z : temp_ray_pos_z;
                    end


                    reg_ray_dir_x <= (reg_ray_dir_x == 1) ? 1 : reg_ray_dir_x >> 1;
                    reg_ray_dir_y <= (reg_ray_dir_y == 1) ? 1 : reg_ray_dir_y >> 1;
                    reg_ray_dir_z <= (reg_ray_dir_z == 1) ? 1 : reg_ray_dir_z >> 1;
                    
                end
                RAY_STEP_BRANCH: begin // 10

                    within_world_x <= (ray_pos_x <= world_max_x) ? 1 : 0;
                    within_world_y <= (ray_pos_y <= world_max_y) ? 1 : 0;
                    within_world_z <= (ray_pos_z <= world_max_z) ? 1 : 0;

                    within_world <= within_world_x && within_world_y && within_world_z;

                end
                COLOUR_FORMAT: begin // 11

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
                        0: begin
                            temp_r <= 55; 
                            temp_g <= 55; 
                            temp_b <= 55;
                        end
                    endcase

                end
                RAY_OUT_OF_BOUND: begin // 12
                    
                    // INFO: Change background colour here
                    temp_r <= 55; 
                    temp_g <= 55; 
                    temp_b <= 55;

                end
                OUTPUT_COLOUR: begin // 13
                    
                    r <= temp_r;
                    g <= temp_g;
                    b <= temp_b;
                    valid_data_out <= 1;
                    ready <= 1;
                    loop_index <= loop_index + 1; 

                end
            default: $stop;
            endcase
        end
    end

    always_comb begin
        next_state = state;
        case (state)
            INITIALISE: begin
                next_state = IDLE;
            end
            IDLE: begin
                next_state = valid ? RAY_TRAVERSE_INITIALISE : IDLE;
            end
            RAY_TRAVERSE_INITIALISE: begin
                next_state = RAY_TRAVERSE_OCTANT_NO;
            end
            RAY_TRAVERSE_OCTANT_NO: begin
                next_state = RAY_TRAVERSE_ADJUST;
            end
            RAY_TRAVERSE_ADJUST: begin
                next_state = RAY_TRAVERSE_UPDATE;
            end
            RAY_TRAVERSE_UPDATE: begin
                if (valid_depth) begin
                    next_state = RAY_TRAVERSE_OCTANT_NO;
                end else begin
                    next_state = (received_material_id > 0) ? COLOUR_FORMAT : RAY_STEP_ADJUST_DIR_VEC;
                end
            end
            RAY_STEP_ADJUST_DIR_VEC: begin
                next_state = dir_big_enough ? RAY_STEP_CHECK_PROXIMITY : RAY_STEP_ADJUST_DIR_VEC;
            end
            RAY_STEP_CHECK_PROXIMITY: begin
                next_state = (!just_outside_AABB) ? RAY_STEP : RAY_STEP_BRANCH;
            end
            RAY_STEP: begin
                next_state = RAY_STEP_POSITION_CALC;
            end
            RAY_STEP_POSITION_CALC: begin
                next_state = RAY_STEP_CHECK;
            end
            RAY_STEP_CHECK: begin
                next_state = RAY_STEP_CHECK_PROXIMITY;
            end
            RAY_STEP_BRANCH: begin
                next_state = within_world ? RAY_TRAVERSE_INITIALISE : RAY_OUT_OF_BOUND;
            end
            COLOUR_FORMAT: begin
                next_state = OUTPUT_COLOUR;
            end
            RAY_OUT_OF_BOUND: begin
                next_state = OUTPUT_COLOUR;
            end
            OUTPUT_COLOUR: begin
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
