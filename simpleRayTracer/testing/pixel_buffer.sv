module pixel_buffer(
    input aclk,
    input aresetn,

    input [7:0] r1, g1, b1,
    input [7:0] r2, g2, b2,
    input [7:0] r3, g3, b3,
    input [7:0] r4, g4, b4,

    input valid1,
    input valid2,
    input valid3,
    input valid4,
    input [2:0] no_of_extra_cores,

    output reg compute_ready_1,
    output reg compute_ready_2,
    output reg compute_ready_3,
    output reg compute_ready_4,

    input in_stream_ready,

    output reg [7:0] out_r,
    output reg [7:0] out_g,
    output reg [7:0] out_b,
    output reg out_valid
);

// State machine states
typedef enum logic [2:0] {
    IDLE,
    WAIT_FOR_1,
    WAIT_FOR_2,
    WAIT_FOR_3,
    WAIT_FOR_4,
    WRITE_PIXEL
} state_t;

state_t state, next_state;

// Buffer to store incoming pixels
reg [7:0] r_buf[3:0];
reg [7:0] g_buf[3:0];
reg [7:0] b_buf[3:0];
reg [3:0] valid_buf; // Keeps track of which slots in the buffer are valid
reg core_en1, core_en2, core_en3, core_en4;
// Current pixel sequence number to be written next
reg [1:0] current_pixel;
reg [2:0] core_num;

assign core_num = no_of_extra_cores + 3'b001;
// Sequential logic to update state and buffer
always @(posedge aclk or negedge aresetn) begin
    if (!aresetn) begin
        state <= IDLE;
        valid_buf <= 4'b0000;
        current_pixel <= 2'b00; // Start with the first pixel
    end else begin
        state <= next_state;

        // Latching valid input pixels into buffer
        if (valid1 && !valid_buf[0]) begin
            r_buf[0] <= r1;
            g_buf[0] <= g1;
            b_buf[0] <= b1;
            valid_buf[0] <= 1'b1;
        end
        if (valid2 && !valid_buf[1]) begin
            r_buf[1] <= r2;
            g_buf[1] <= g2;
            b_buf[1] <= b2;
            valid_buf[1] <= 1'b1;
        end
        if (valid3 && !valid_buf[2]) begin
            r_buf[2] <= r3;
            g_buf[2] <= g3;
            b_buf[2] <= b3;
            valid_buf[2] <= 1'b1;
        end
        if (valid4 && !valid_buf[3]) begin
            r_buf[3] <= r4;
            g_buf[3] <= g4;
            b_buf[3] <= b4;
            valid_buf[3] <= 1'b1;
        end

        // Shifting buffer if pixel is written to packer
        if (next_state == WRITE_PIXEL && in_stream_ready) begin
            valid_buf[current_pixel] <= 1'b0;
            current_pixel <= ((current_pixel + 1) % core_num);
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
    core_en1 = 1'b0;
    core_en2 = 1'b0;
    core_en3 = 1'b0;
    core_en4 = 1'b0;
    if (no_of_extra_cores == 3'b000) begin
        core_en1 = 1'b1;
    end
    else if (no_of_extra_cores == 3'b001) begin
        core_en1 = 1'b1;
        core_en2 = 1'b1;
    end
    else if (no_of_extra_cores == 3'b010) begin
        core_en1 = 1'b1;
        core_en2 = 1'b1;
        core_en3 = 1'b1;
    end
    else if (no_of_extra_cores == 3'b011) begin
        core_en1 = 1'b1;
        core_en2 = 1'b1;
        core_en3 = 1'b1;
        core_en4 = 1'b1;
    end
    case (state)
        IDLE: begin
            if (valid_buf[current_pixel]) begin
                next_state = WRITE_PIXEL;
            end else if (!valid_buf[0] && current_pixel == 2'b00 && core_en1 == 1'b1) begin
                next_state = WAIT_FOR_1;
            end else if (!valid_buf[1] && current_pixel == 2'b01 && core_en2 == 1'b1) begin
                next_state = WAIT_FOR_2;
            end else if (!valid_buf[2] && current_pixel == 2'b10 && core_en3 == 1'b1) begin
                next_state = WAIT_FOR_3;
            end else if (!valid_buf[3] && current_pixel == 2'b11 && core_en4 == 1'b1) begin
                next_state = WAIT_FOR_4;
            end
        end

        WAIT_FOR_1: begin
            if (valid_buf[0]) begin
                next_state = WRITE_PIXEL;
            end
            compute_ready_1 = 1'b1; // Signal ray tracing unit 1 to start computing next pixel
        end

        WAIT_FOR_2: begin
            if (valid_buf[1]) begin
                next_state = WRITE_PIXEL;
            end
            compute_ready_2 = 1'b1; // Signal ray tracing unit 2 to start computing next pixel
        end

        WAIT_FOR_3: begin
            if (valid_buf[2]) begin
                next_state = WRITE_PIXEL;
            end
            compute_ready_3 = 1'b1; // Signal ray tracing unit 3 to start computing next pixel
        end

        WAIT_FOR_4: begin
            if (valid_buf[3]) begin
                next_state = WRITE_PIXEL;
            end
            compute_ready_4 = 1'b1; // Signal ray tracing unit 4 to start computing next pixel
        end

        WRITE_PIXEL: begin
            if (in_stream_ready) begin
                out_r = r_buf[current_pixel];
                out_g = g_buf[current_pixel];
                out_b = b_buf[current_pixel];
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
