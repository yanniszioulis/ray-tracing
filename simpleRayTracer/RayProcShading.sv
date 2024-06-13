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
    input logic                             ready_external,
    output logic [7:0]                      r, g, b,
    output logic                            ready_internal,                      // signal to go back to ray gen to tell it to generate new ray
    output logic                            valid_data_out,             // signal to next block/ buffer to read output from ray processor
    output logic                            last_x,
    output logic                            sof,
    input logic [31:0]                      node,
    output logic [31:0]                     address,
    output logic                            ren

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
    //logic [31:0]                node [0:7];
    // logic [31:0]                  node;
    // logic [15:0]                  address;

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

    reg signed [1:0]            normal_vec_x;
    reg signed [1:0]                 normal_vec_y;
    reg signed [1:0]                 normal_vec_z;

    logic signed [31:0]                        magnitude_shading;

    reg signed [31:0]   light_dir_x;
    reg signed [31:0]   light_dir_y;
    reg signed [31:0]   light_dir_z;
    logic signed [31:0]  light_dir_x_real, light_dir_y_real, light_dir_z_real;


    logic signed [31:0]                         normalized_light_dir_x;
    logic signed [31:0]                        normalized_light_dir_y;
    logic signed [31:0]                         normalized_light_dir_z;

    logic signed [31:0]                         brightness_factor;
    logic signed [31:0]                         sqrt_res, sqrt_bit, sqrt_temp, sqrt_input;

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

    logic                       intermediate_ready;

    typedef enum logic [4:0] { 
        NEW_FRAME,                      // 0
        INITIALISE,                     // 1
        IDLE,                           // 2
        RAY_TRAVERSE_INITIALISE,        // 3
        RAY_TRAVERSE_OCTANT_NO,         // 4
        CHECK_STATE,                    // 5
        FIND_OCTANT,                    // 6
        UPDATE_MIN,                     // 7                           
        UPDATE_MAX,                     // 8
        RAY_PREP_STEP,                  // 9
        RAY_STEP_ADJUST_DIR_VEC,        // 10
        RAY_STEP_TEMP,                  // 11
        RAY_STEP_CHECK_POSITION,        // 12
        RAY_STEP_CHECK_AABB,            // 13
        STALL,                          // 14
        RAY_STEP_INSIDE,                // 15
        RAY_STEP_OUTSIDE,               // 16
        COLOUR_FORMAT,                  // 17
        SHADING_1,                      // 18
        SHADING_2,
        SQRT_INIT,
        SQRT_INIT_BUFFER,
        SQRT_ITER,
        SQRT_ITER_BUFFER,                      // 19
        SHADING_3,                      // 20
        SHADING_4,                      // 21
        RAY_OUT_OF_BOUND,               // 22
        OUTPUT_COLOUR                   // 23
     } state_t;

     state_t state, next_state;

    always_ff @(posedge clk) begin
        if (!reset_n) begin
            state <= NEW_FRAME;
        end else begin
            state <= next_state;
        end
    end

    always_ff @(posedge clk) begin

        case (state)
            NEW_FRAME: begin // 0
                loop_index <= 0;
                // valid_data_out <= 0;
                //ready_internal <= 1;
                // last_x <= 0;
                world_size <= 2**COORD_BIT_LEN;
            end
            INITIALISE: begin // 1

                //ready_internal <= 0;
                // valid_data_out <= 0;
                // world_size <= 2**COORD_BIT_LEN;
                oct_size <= world_size; 

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

                normal_vec_x <= 1;
                normal_vec_y <= 1;
                normal_vec_z <= 1;

                brightness_factor <= 1;
                magnitude_shading <= 1;

                just_outside_AABB <= 0; 

                within_world_x <= 1;
                within_world_y <= 1;
                within_world_z <= 1;
                within_world <= 1;
                //octant_no <= 0;
                dir_big_enough <= 0;
                received_material_id <= 0;
                index <= COORD_BIT_LEN-1;
                depth <= 0;
                /* verilator lint_on WIDTH */

                // root address <= address in ROM of root 
                address <= 0;
                ren <= 1;
                // node <= 0;


                // node[0] <= 0;
                // node[1] <= 0;
                // node[2] <= 0;
                // node[3] <= 0;
                // node[4] <= 0;
                // node[5] <= 2;
                // node[6] <= 3;
                // node[7] <= 1;


            end
            IDLE: begin // 2
                
                // valid_data_out <= 0;

                if (ray_dir_z == 0) begin
                    valid <= 0;
                    intermediate_ready <= 1;
                end else if (loop_index == 0 && ((ray_dir_x == 0) || (ray_dir_y == 0))) begin 
                    valid <= 0;
                    intermediate_ready <= 0;
                end else begin 
                    valid <= 1;
                    intermediate_ready <= 0;
                end

                reg_ray_dir_x <= ray_dir_x;
                reg_ray_dir_y <= ray_dir_y;
                reg_ray_dir_z <= ray_dir_z;

                curr_ray_dir_x <= ray_dir_x;
                curr_ray_dir_y <= ray_dir_y;
                curr_ray_dir_z <= ray_dir_z;

            end
            RAY_TRAVERSE_INITIALISE: begin // 3
                
                reg_ray_dir_x <= curr_ray_dir_x;
                reg_ray_dir_y <= curr_ray_dir_y;
                reg_ray_dir_z <= curr_ray_dir_z;


            end
            RAY_TRAVERSE_OCTANT_NO: begin // 4
                dir_big_enough <= 0;
                in_range <= 0;
                index <= COORD_BIT_LEN-1-depth; // check for depth updates in seperate module
                // state to check rom
                // node <= ROM[address];x
                
                // GO TO CHECK STATE

            end
            CHECK_STATE: begin // 5
                // IF NODE IS FFFF go to state RETURN MATERIAL
                // IF NODE IS NOT go to POINTER_HANDLING
            end
            FIND_OCTANT: begin // 6
                // IF NODE IS POINTER 
                octant_no <= {ray_pos_z[index], ray_pos_y[index], ray_pos_x[index]};
                depth <= depth+1;
                oct_size <= oct_size/2;

                // GO TO UPDATE MIN

            end
            UPDATE_MIN: begin // 7
                aabb_min_x <= aabb_min_x + octant_no[0] * oct_size;
                aabb_min_y <= aabb_min_y + octant_no[1] * oct_size;
                aabb_min_z <= aabb_min_z + octant_no[2] * oct_size;
                address <= node + octant_no;
                // GO TO UPDATE MAX

            end 
            UPDATE_MAX: begin // 8
                aabb_max_x <= aabb_min_x + oct_size - 1;
                aabb_max_y <= aabb_min_y + oct_size - 1;
                aabb_max_z <= aabb_min_z + oct_size - 1;

                // GO TO RAY_TRAVERSE_OCTANT_NO
            end

            RAY_PREP_STEP: begin // 9 RETURN MATERIAL

                /* verilator lint_off WIDTH */

                received_material_id <= node[1:0];

                // calculate magnitude 

                magnitude_squared <= reg_ray_dir_x*reg_ray_dir_x + reg_ray_dir_y*reg_ray_dir_y + reg_ray_dir_z*reg_ray_dir_z;
                oct_size_squared <= oct_size * oct_size;
                
            end
            RAY_STEP_ADJUST_DIR_VEC: begin // 10

                if( magnitude_squared < oct_size_squared) begin
                    reg_ray_dir_x <= reg_ray_dir_x <<< 1;
                    reg_ray_dir_y <= reg_ray_dir_y <<< 1;
                    reg_ray_dir_z <= reg_ray_dir_z <<< 1;
                    dir_big_enough <= 0;
                end else begin
                    dir_big_enough <= 1;
                end

            end
            RAY_STEP_TEMP: begin // 11

                temp_ray_pos_x <= ray_pos_x + reg_ray_dir_x;
                temp_ray_pos_y <= ray_pos_y + reg_ray_dir_y;
                temp_ray_pos_z <= ray_pos_z + reg_ray_dir_z;

            end
            RAY_STEP_CHECK_POSITION: begin // 12

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
            RAY_STEP_CHECK_AABB: begin // 13
                within_world <= within_world_x && within_world_y && within_world_z;
                just_outside_AABB <= (just_outside_x&&just_outside_y&&just_outside_z)||(just_outside_x&&just_outside_y&&within_z)||(just_outside_x&&within_y&&just_outside_z)||(just_outside_x&&within_y&&within_z)||(within_x&&just_outside_y&&just_outside_z)||(within_x&&within_y&&just_outside_z)||(within_x&&just_outside_y&&within_z);
                in_range <= ((within_x && within_y && within_z) ||(just_outside_x&&just_outside_y&&just_outside_z)||(just_outside_x&&just_outside_y&&within_z)||(just_outside_x&&within_y&&just_outside_z)||(just_outside_x&&within_y&&within_z)||(within_x&&just_outside_y&&just_outside_z)||(within_x&&within_y&&just_outside_z)||(within_x&&just_outside_y&&within_z));
            
            end
            STALL: begin //14
            end
            RAY_STEP_INSIDE: begin // 15


                if (in_range) begin
                    ray_pos_x <= temp_ray_pos_x;
                    ray_pos_y <= temp_ray_pos_y;
                    ray_pos_z <= temp_ray_pos_z;
                end


                // Block below: for more accurate direction vector.

                if(reg_ray_dir_x == 1) begin
                    underflow_x <= 1;
                    if(underflow_x == 0 || (reg_ray_dir_y == 0 || reg_ray_dir_z == 0) || (underflow_x == 1 && underflow_y == 1 && underflow_z == 1) ) begin
                        reg_ray_dir_x <= 1;
                    end
                end
                else begin
                    reg_ray_dir_x <= reg_ray_dir_x >>> 1;
                end

                if(reg_ray_dir_y == 1) begin
                    underflow_y <= 1;
                    if(underflow_y == 0 || (reg_ray_dir_x == 0 || reg_ray_dir_z == 0) || (underflow_x == 1 && underflow_y == 1 && underflow_z == 1)) begin
                        reg_ray_dir_y <= 1;
                    end
                end
                else begin
                    reg_ray_dir_y <= reg_ray_dir_y >>> 1;
                end

                if(reg_ray_dir_z == 1) begin
                    underflow_z <= 1;
                    if(underflow_z == 0 || (reg_ray_dir_x == 0 || reg_ray_dir_y == 0) || (underflow_x == 1 && underflow_y == 1 && underflow_z == 1)) begin
                        reg_ray_dir_z <= 1;
                    end
                end
                else begin
                    reg_ray_dir_z <= reg_ray_dir_z >>> 1;
                end
                
                
                // Less accurate direction vector:

                // reg_ray_dir_x <= (reg_ray_dir_x == 1) ? 1 : reg_ray_dir_x >>> 1;
                // reg_ray_dir_y <= (reg_ray_dir_y == 1) ? 1 : reg_ray_dir_y >>> 1;
                // reg_ray_dir_z <= (reg_ray_dir_z == 1) ? 1 : reg_ray_dir_z >>> 1;
                
            end
            RAY_STEP_OUTSIDE: begin // 16


                // probably recalculate AABBs here or something

                ray_pos_x <= temp_ray_pos_x;
                ray_pos_y <= temp_ray_pos_y;
                ray_pos_z <= temp_ray_pos_z;

                within_world_x <= (temp_ray_pos_x <= world_max_x) ? 1 : 0;
                within_world_y <= (temp_ray_pos_y <= world_max_y) ? 1 : 0;
                within_world_z <= (temp_ray_pos_z <= world_max_z) ? 1 : 0;

                within_world <= (temp_ray_pos_x <= world_max_x) && (temp_ray_pos_y <= world_max_y) && (temp_ray_pos_z <= world_max_z);

                depth <= 0;
                address <= 0;
                oct_size <= world_size;
                aabb_min_x <= 0;
                aabb_min_y <= 0;
                aabb_min_z <= 0;
                aabb_max_x <= world_max_x;
                aabb_max_y <= world_max_y;
                aabb_max_z <= world_max_z;

                just_outside_x <= 0;
                just_outside_y <= 0;
                just_outside_z <= 0;
                
                just_outside_AABB <= 0; 
                //octant_no <= 0;
                dir_big_enough <= 0;
                received_material_id <= 0;
                

            end
            COLOUR_FORMAT: begin // 17
                case(received_material_id) 
                    2'b01: begin
                        temp_r <= 255; 
                        temp_g <= 255; 
                        temp_b <= 255;
                    end
                    2'b10: begin
                        temp_r <= 255; 
                        temp_g <= 0; 
                        temp_b <= 0;
                    end
                    2'b11 : begin
                        temp_r <= 0; 
                        temp_g <= 0; 
                        temp_b <= 255;
                    end
                    default: $stop;
                endcase
                
                loop_index <= loop_index + 1; 

            end
            SHADING_1: begin
                if (ray_pos_x == aabb_min_x) begin
                    normal_vec_x <= -1;
                    normal_vec_y <= 0;
                    normal_vec_z <= 0;
                end else if (ray_pos_x == aabb_max_x) begin
                    normal_vec_x <= 1;
                    normal_vec_y <= 0;
                    normal_vec_z <= 0;
                end else if (ray_pos_y == aabb_min_y) begin
                    normal_vec_x <= 0;
                    normal_vec_y <= -1;
                    normal_vec_z <= 0;
                end else if (ray_pos_y == aabb_max_y) begin
                    normal_vec_x <= 0;
                    normal_vec_y <= 1;
                    normal_vec_z <= 0;
                end else if (ray_pos_z == aabb_min_z) begin
                    normal_vec_x <= 0;
                    normal_vec_y <= 0;
                    normal_vec_z <= -1;
                end else if (ray_pos_y == aabb_max_z) begin
                    normal_vec_x <= 0;
                    normal_vec_y <= 0;
                    normal_vec_z <= 1;
                end else begin
                    normal_vec_x <= 1;
                    normal_vec_y <= 1;
                    normal_vec_z <= 1;
                end

            light_dir_x <= camera_pos_x - ray_pos_x;
            light_dir_y <= camera_pos_y - ray_pos_y;
            light_dir_z <= camera_pos_z - ray_pos_z;

            end
            SHADING_2: begin
                magnitude_shading <= (light_dir_x**2 + light_dir_y**2 + light_dir_z**2);
                sqrt_input <= (light_dir_x**2 + light_dir_y**2 + light_dir_z**2);
            end
            SQRT_INIT: begin
                sqrt_res <= 0;
                sqrt_bit <= 1 << 30;
            end
            SQRT_INIT_BUFFER: begin
            end
            SQRT_ITER: begin
                    if (sqrt_bit != 0) begin
                        sqrt_temp = sqrt_res + sqrt_bit;
                        if (sqrt_input >= sqrt_temp) begin
                            sqrt_input <= sqrt_input - sqrt_temp;
                            sqrt_res <= (sqrt_res >> 1) + sqrt_bit;
                        end else begin
                            sqrt_res <= sqrt_res >> 1;
                        end
                        sqrt_bit <= sqrt_bit >> 2;
                    end
                end
            SQRT_ITER_BUFFER: begin
            end
            SHADING_3: begin
                if (magnitude_shading != 0) begin
                    normalized_light_dir_x <= (light_dir_x * 10000) / sqrt_res;
                    normalized_light_dir_y <= (light_dir_y * 10000) / sqrt_res;
                    normalized_light_dir_z <= (light_dir_z * 10000) / sqrt_res;
                end else begin
                    normalized_light_dir_x <= 0;
                    normalized_light_dir_y <= 0;
                    normalized_light_dir_z <= 0;
                end
            end

            SHADING_4: begin
                brightness_factor <= (normalized_light_dir_x * normal_vec_x) + (normalized_light_dir_y * normal_vec_y) + (normalized_light_dir_z * normal_vec_z);
                // brightness_factor <= $itor(normal_vec_x);
            end
            RAY_OUT_OF_BOUND: begin // 18
                
                // INFO: Change background colour here
                temp_r <= 255; 
                temp_g <= 255; 
                temp_b <= 255;
                loop_index <= loop_index + 1; 

            end
            OUTPUT_COLOUR: begin // 19
                
                if (brightness_factor != 10000) begin
                    r <= (temp_r * brightness_factor) / 10000;
                    g <= (temp_g * brightness_factor) / 10000;
                    b <= (temp_b * brightness_factor) / 10000;
                end else begin
                    r <= temp_r;
                    g <= temp_g;
                    b <= temp_b;
                end
                // valid_data_out <= 1;
                //ready_internal <= 1;
            end
        default: $stop;
        endcase
        
    end

    always_comb begin
        next_state = state;
        valid_data_out = (state == OUTPUT_COLOUR);
        ready_internal = 0;
        last_x = 0;
        sof = 0;
        case (state) 
            NEW_FRAME: begin // 0
                next_state = INITIALISE;
                valid_data_out = 0;
                last_x = 0;
                ready_internal = 1;
            end
            INITIALISE: begin // 1
                next_state = IDLE;
                valid_data_out = 0;
                ready_internal = 0;
            end
            IDLE: begin // 2
                if (valid) begin
                    next_state = RAY_TRAVERSE_INITIALISE;
                end else begin
                    next_state = IDLE;
                end
                valid_data_out = 0;

                // if (loop_index == 0) begin
                //     sof = 1;
                // end else begin
                //     sof = 0;
                // end

                if (intermediate_ready) begin 
                    ready_internal = 1;
                end else begin
                    ready_internal = 0;
                end
            end
            RAY_TRAVERSE_INITIALISE: begin // 3
                next_state = RAY_TRAVERSE_OCTANT_NO;
            end
            RAY_TRAVERSE_OCTANT_NO: begin // 4
                next_state = CHECK_STATE;
            end
            CHECK_STATE: begin // 5
                // IF NODE HAS FFFF go to state RETURN MATERIAL
                // IF NODE IS NOT go to POINTER_HANDLING
                if(node[31]) begin
                    next_state = RAY_PREP_STEP;
                end else begin
                    next_state = FIND_OCTANT;
                end

            end
            FIND_OCTANT: begin // 6
                next_state = UPDATE_MIN;
            end
            UPDATE_MIN: begin // 7
                next_state = UPDATE_MAX;
            end
            UPDATE_MAX: begin // 8
                next_state = RAY_TRAVERSE_OCTANT_NO;
            end
            RAY_PREP_STEP: begin // 9

                if (received_material_id != 2'b00) begin
                    next_state = COLOUR_FORMAT;
                end else begin
                    next_state = RAY_STEP_ADJUST_DIR_VEC;
                end
                
            end
            RAY_STEP_ADJUST_DIR_VEC: begin // 10
                if (dir_big_enough) begin
                    next_state = RAY_STEP_TEMP;
                end else begin
                    next_state = RAY_PREP_STEP; //SOMEWHERE ELSE
                end            end
            RAY_STEP_TEMP: begin // 11
                next_state = RAY_STEP_CHECK_POSITION;
            end
            RAY_STEP_CHECK_POSITION: begin // 12
                next_state = RAY_STEP_CHECK_AABB;
            end
            RAY_STEP_CHECK_AABB: begin // 13
                next_state = STALL;
            end
            STALL: begin //14
                if (!within_world) begin
                    next_state = RAY_OUT_OF_BOUND;
                end else if (just_outside_AABB) begin
                    next_state = RAY_STEP_OUTSIDE;
                end else begin
                    next_state = RAY_STEP_INSIDE;
                end
            end
            RAY_STEP_INSIDE: begin // 15
                // next_state = (in_range) ? RAY_STEP_TEMP : RAY_STEP_TEMP;
                if (in_range) begin
                    next_state = RAY_STEP_TEMP;
                end else begin
                    next_state = RAY_STEP_TEMP;
                end
            end
            RAY_STEP_OUTSIDE: begin // 16
                // next_state = within_world ? RAY_TRAVERSE_INITIALISE : RAY_OUT_OF_BOUND;
                if (within_world) begin
                    next_state = RAY_TRAVERSE_INITIALISE;
                end else begin
                    next_state = RAY_OUT_OF_BOUND;
                end
            end
            COLOUR_FORMAT: begin // 17
                next_state = SHADING_1;
            end
            SHADING_1: begin // 18
                next_state = SHADING_2;
            end
            SHADING_2: begin // 19
                next_state = SQRT_INIT;
            end
            SQRT_INIT: begin // 20
                next_state = SQRT_ITER;
            end
            SQRT_INIT_BUFFER: begin // 21
                if (sqrt_bit > sqrt_input) begin
                    next_state = SQRT_ITER;
                end else begin
                    next_state = SHADING_3;
                end
            end
            SQRT_ITER: begin
                next_state = SQRT_ITER_BUFFER;
            end
            SQRT_ITER_BUFFER: begin
                if(sqrt_bit != 0) begin
                    next_state = SQRT_ITER;
                end else begin
                    next_state = SHADING_3;
                end
            end
            SHADING_3: begin
                next_state = SHADING_4;
            end
            SHADING_4: begin
                next_state = OUTPUT_COLOUR;
            end
            RAY_OUT_OF_BOUND: begin // 22
                next_state = OUTPUT_COLOUR;
            end
            OUTPUT_COLOUR: begin // 23
                valid_data_out = 1;
                if (ready_external) begin
                    if (loop_index >= image_height * image_width) begin
                        next_state = NEW_FRAME;
                    end else begin
                        next_state = INITIALISE;
                        ready_internal = 1;
                    end
                end else begin
                    next_state = OUTPUT_COLOUR;
                end

                if ((loop_index ) % image_width == 0) begin
                    last_x = 1;
                end else begin
                    last_x = 0;
                end

                if (loop_index == 1) begin
                    sof = 1;
                end else begin
                    sof = 0;
                end

            end
        default: $stop;
        endcase
     end

endmodule