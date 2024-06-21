module PixelBuffer (
    input logic aclk,
    input logic aresetn,

    input logic [7:0] r1, g1, b1,
    input logic [7:0] r2, g2, b2,

    input logic       eol1, eol2,
    input logic       sof1, sof2,
    input logic [31:0] loop_index_1, loop_index_2,

    input logic [12:0] image_width, image_height,

    input logic valid1,
    input logic valid2,
    input logic [1:0] no_of_extra_cores,

    output logic compute_ready_1,
    output logic compute_ready_2,

    input logic in_stream_ready_buff,

    output logic [7:0] out_r,
    output logic [7:0] out_g,
    output logic [7:0] out_b,
    output logic out_valid,
    output logic EOL_out, SOF_out
);

    // State machine states
    typedef enum logic [2:0] {
        IDLE,
        WRITE_PIXEL
    } state_t;

    state_t state, next_state;

    // Buffer to store incoming pixels
    localparam MAX_CORES = 2;
    logic [7:0] pixel_buffer_r[MAX_CORES-1:0];
    logic [7:0] pixel_buffer_g[MAX_CORES-1:0];
    logic [7:0] pixel_buffer_b[MAX_CORES-1:0];
    logic EOL_buffer[MAX_CORES-1:0];
    logic SOF_buffer[MAX_CORES-1:0];
    logic [31:0] loop_index_buffer[MAX_CORES-1:0];
    logic [MAX_CORES-1:0] pixel_buffer_valid;


    // DEBUGGING
    logic [31:0] x_count, y_count;

    // Current pixel index to be written next
    logic [$clog2(MAX_CORES)-1:0] current_pixel;

    logic [31:0] pixel_count;

    logic pixel_count_reset;

    // Additional register to keep track of total pixels processed
    // Sequential logic to update state and buffer
    // Sequential logic to update state and buffer
    always @(posedge aclk) begin
        if (!aresetn) begin
            state <= IDLE;
            pixel_buffer_valid <= 'b0;
            current_pixel <= 'b0;
            pixel_count <= 0;
        end else begin
            state <= next_state;

            if(pixel_count_reset == 1) begin 
                pixel_count <= 0;
            end

            // Latching valid input pixels into buffer
            if (valid1 && (current_pixel == 0)) begin
                pixel_buffer_r[0] <= r1;
                pixel_buffer_g[0] <= g1;
                pixel_buffer_b[0] <= b1;
                EOL_buffer[0] <= eol1;
                SOF_buffer[0] <= sof1;
                loop_index_buffer[0] <= loop_index_1;
                pixel_buffer_valid[0] <= 1'b1;
                pixel_count <= pixel_count + 1;
            end
            if (valid2 && (current_pixel == 1)) begin
                pixel_buffer_r[1] <= r2;
                pixel_buffer_g[1] <= g2;
                pixel_buffer_b[1] <= b2;
                EOL_buffer[1] <= eol2;
                SOF_buffer[1] <= sof2;
                loop_index_buffer[1] <= loop_index_2;
                pixel_buffer_valid[1] <= 1'b1;
                pixel_count <= pixel_count + 1;
            end

            // Shifting buffer if pixel is written to packer
            if (state == WRITE_PIXEL && in_stream_ready_buff) begin
                pixel_buffer_valid[current_pixel] <= 1'b0;
                if (current_pixel == no_of_extra_cores) begin
                    current_pixel <= 'b0;
                end else begin
                    current_pixel <= current_pixel + 1;
                end
            end
        end
    end

    // Combinational logic for state transitions and output assignments
    always_comb begin
        next_state = state;
        compute_ready_1 = 1'b0;
        compute_ready_2 = 1'b0;
        out_valid = 1'b0;
        out_r = 8'h00;
        out_g = 8'h00;
        out_b = 8'h00;
        EOL_out = 1'b0;
        SOF_out = 1'b0;
        pixel_count_reset = 1'b0;

        case (state)
            IDLE: begin
                if (pixel_buffer_valid[current_pixel]) begin
                    next_state = WRITE_PIXEL;
                end else begin
                    case (current_pixel)
                        0: compute_ready_1 = 1'b1;
                        1: compute_ready_2 = 1'b1;
                    endcase
                end
            end

            WRITE_PIXEL: begin
                if (in_stream_ready_buff) begin
                    out_r = pixel_buffer_r[current_pixel];
                    out_g = pixel_buffer_g[current_pixel];
                    out_b = pixel_buffer_b[current_pixel];

                    out_valid = 1'b1;
                    if(loop_index_buffer[current_pixel] % image_width == 0) begin
                        EOL_out = 1;
                    end 

                    if((loop_index_buffer[current_pixel]) == 1) begin
                        SOF_out = 1;
                    end 
                    next_state = IDLE;

                end
            end

            default: begin
                next_state = IDLE;
            end
        endcase
    end

endmodule