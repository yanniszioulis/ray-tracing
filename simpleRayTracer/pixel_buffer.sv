module pixel_buffer (
    input logic aclk,
    input logic aresetn,

    input logic [7:0] r1, g1, b1,
    input logic [7:0] r2, g2, b2,
    input logic [7:0] r3, g3, b3,
    input logic [7:0] r4, g4, b4,

    input logic valid1,
    input logic valid2,
    input logic valid3,
    input logic valid4,
    input logic [2:0] no_of_extra_cores,

    output logic compute_ready_1,
    output logic compute_ready_2,
    output logic compute_ready_3,
    output logic compute_ready_4,

    input logic in_stream_ready,

    output logic [7:0] out_r,
    output logic [7:0] out_g,
    output logic [7:0] out_b,
    output logic out_valid
);

    // State machine states
    typedef enum logic [2:0] {
        IDLE,
        WRITE_PIXEL
    } state_t;

    state_t state, next_state;

    // Buffer to store incoming pixels
    localparam MAX_CORES = 4;
    localparam MAX_PIXELS = 1024;
    logic [7:0] pixel_buffer_r[MAX_CORES-1:0];
    logic [7:0] pixel_buffer_g[MAX_CORES-1:0];
    logic [7:0] pixel_buffer_b[MAX_CORES-1:0];
    logic [MAX_CORES-1:0] pixel_buffer_valid;

    // Current pixel index to be written next
    logic [$clog2(MAX_CORES)-1:0] current_pixel;

    // Additional register to keep track of total pixels processed
    logic [$clog2(MAX_CORES*MAX_PIXELS)-1:0] total_pixels_processed;

    always @(posedge aclk or negedge aresetn) begin
    if (!aresetn) begin
        state <= IDLE;
        pixel_buffer_valid <= 'b0;
        current_pixel <= 'b0;
        total_pixels_processed <= 'b0;
    end else begin
        state <= next_state;

        // Latching valid input pixels into buffer
        if (valid1) begin
            pixel_buffer_r[0] <= r1;
            pixel_buffer_g[0] <= g1;
            pixel_buffer_b[0] <= b1;
            pixel_buffer_valid[0] <= 1'b1;
        end
        if (valid2) begin
            pixel_buffer_r[1] <= r2;
            pixel_buffer_g[1] <= g2;
            pixel_buffer_b[1] <= b2;
            pixel_buffer_valid[1] <= 1'b1;
        end
        if (valid3) begin
            pixel_buffer_r[2] <= r3;
            pixel_buffer_g[2] <= g3;
            pixel_buffer_b[2] <= b3;
            pixel_buffer_valid[2] <= 1'b1;
        end
        if (valid4) begin
            pixel_buffer_r[3] <= r4;
            pixel_buffer_g[3] <= g4;
            pixel_buffer_b[3] <= b4;
            pixel_buffer_valid[3] <= 1'b1;
        end

        // Shifting buffer if pixel is written to packer
        if (state == WRITE_PIXEL && in_stream_ready) begin
            pixel_buffer_valid[current_pixel] <= 1'b0;
            total_pixels_processed <= total_pixels_processed + 1;
            current_pixel <= (current_pixel + 1) % (no_of_extra_cores + 1);
        end
    end
end

// Combinational logic for state transitions and output assignments
always_comb begin
    next_state = state;
    compute_ready_1 = 1'b0;
    compute_ready_2 = 1'b0;
    compute_ready_3 = 1'b0;
    compute_ready_4 = 1'b0;
    out_valid = 1'b0;
    out_r = 8'h00;
    out_g = 8'h00;
    out_b = 8'h00;

    case (state)
        IDLE: begin
            if (pixel_buffer_valid[current_pixel]) begin
                next_state = WRITE_PIXEL;
            end else begin
                case (current_pixel)
                    0: compute_ready_1 = ~pixel_buffer_valid[0];
                    1: compute_ready_2 = ~pixel_buffer_valid[1];
                    2: compute_ready_3 = ~pixel_buffer_valid[2];
                    3: compute_ready_4 = ~pixel_buffer_valid[3];
                endcase
            end
        end

        WRITE_PIXEL: begin
            if (in_stream_ready) begin
                out_r = pixel_buffer_r[current_pixel];
                out_g = pixel_buffer_g[current_pixel];
                out_b = pixel_buffer_b[current_pixel];
                out_valid = 1'b1;
                next_state = IDLE;
            end
        end

        default: begin
            next_state = IDLE;
        end
    endcase
end


endmodule
