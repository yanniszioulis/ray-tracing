module SerialReceiver (
    input wire clk,
    input wire reset,
    input wire rx,  // Serial receive line
    output reg [31:0] camera_pos,  // Packed positions (x, y, z)
    output reg [31:0] camera_dir   // Packed directions (x, y, z)
);

    reg [7:0] rx_data;
    reg [3:0] bit_count;
    reg [5:0] state;  // Increased state bits to handle more states
    reg [9:0] temp_pos_x, temp_pos_y, temp_pos_z, temp_dir_x, temp_dir_y, temp_dir_z;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= 0;
            bit_count <= 0;
            rx_data <= 0;
            camera_pos <= 0;
            camera_dir <= 0;
            temp_pos_x <= 0;
            temp_pos_y <= 0;
            temp_pos_z <= 0;
            temp_dir_x <= 0;
            temp_dir_y <= 0;
            temp_dir_z <= 0;
        end else begin
            case (state)
                0: if (rx) state <= 1;  // Start bit detection
                1: begin
                    rx_data[bit_count] <= rx;  // Collect bits
                    bit_count <= bit_count + 1;
                    if (bit_count == 7) begin
                        bit_count <= 0;
                        state <= state + 1;  // Move to the next state after 8 bits
                    end
                   end
                2: begin
                    temp_pos_x <= {temp_pos_x[8:0], rx};  // Shift in bits for pos_x
                    bit_count <= bit_count + 1;
                    if (bit_count == 9) begin
                        bit_count <= 0;
                        state <= state + 1;
                    end
                   end
                3: begin
                    temp_pos_y <= {temp_pos_y[8:0], rx};  // Shift in bits for pos_y
                    bit_count <= bit_count + 1;
                    if (bit_count == 9) begin
                        bit_count <= 0;
                        state <= state + 1;
                    end
                   end
                4: begin
                    temp_pos_z <= {temp_pos_z[8:0], rx};  // Shift in bits for pos_z
                    bit_count <= bit_count + 1;
                    if (bit_count == 9) begin
                        bit_count <= 0;
                        state <= state + 1;
                    end
                   end
                5: begin
                    temp_dir_x <= {temp_dir_x[8:0], rx};  // Shift in bits for dir_x
                    bit_count <= bit_count + 1;
                    if (bit_count == 9) begin
                        bit_count <= 0;
                        state <= state + 1;
                    end
                   end
                6: begin
                    temp_dir_y <= {temp_dir_y[8:0], rx};  // Shift in bits for dir_y
                    bit_count <= bit_count + 1;
                    if (bit_count == 9) begin
                        bit_count <= 0;
                        state <= state + 1;
                    end
                   end
                7: begin
                    temp_dir_z <= {temp_dir_z[8:0], rx};  // Shift in bits for dir_z
                    bit_count <= bit_count + 1;
                    if (bit_count == 9) begin
                        bit_count <= 0;
                        state <= 8;
                    end
                   end
                8: begin
                    camera_pos <= {temp_pos_x, temp_pos_y, temp_pos_z[1:0]};  // Pack pos_x, pos_y, and top 2 bits of pos_z
                    camera_dir <= {temp_dir_x, temp_dir_y, temp_dir_z[1:0]};  // Pack dir_x, dir_y, and top 2 bits of dir_z
                    state <= 0;  // Reset state to start over
                   end
                default: state <= 0;
            endcase
        end
    end

endmodule
