module camera_controller (
    input logic clk,
    input logic reset,
    input logic rx,
    output logic [31:0] camera_pos_x,
    output logic [31:0] camera_pos_y,
    output logic [31:0] camera_pos_z,
    output logic [31:0] camera_dir_x,
    output logic [31:0] camera_dir_y,
    output logic [31:0] camera_dir_z
);
    logic [7:0] uart_data;
    logic uart_data_valid;

    // Instantiate UART receiver
    uart_rx uart_rx_inst (
        .clk(clk),
        .reset(reset),
        .rx(rx),
        .data(uart_data),
        .data_valid(uart_data_valid)
    );

    // State machine to parse incoming data
    typedef enum logic [2:0] {
        WAITING,
        POS_X,
        POS_Y,
        POS_Z,
        DIR_X,
        DIR_Y,
        DIR_Z
    } parse_state_t;

    parse_state_t parse_state;
    logic [31:0] temp_data;
    logic [2:0] byte_count;

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            parse_state <= WAITING;
            byte_count <= 0;
            temp_data <= 0;
            camera_pos_x <= 0;
            camera_pos_y <= 0;
            camera_pos_z <= 0;
            camera_dir_x <= 0;
            camera_dir_y <= 0;
            camera_dir_z <= 0;
        end else begin
            if (uart_data_valid) begin
                case (parse_state)
                    WAITING: begin
                        if (uart_data == ",") begin
                            parse_state <= POS_X;
                            byte_count <= 0;
                            temp_data <= 0;
                        end
                    end
                    POS_X, POS_Y, POS_Z, DIR_X, DIR_Y, DIR_Z: begin
                        if (uart_data == ",") begin
                            case (parse_state)
                                POS_X: begin
                                    camera_pos_x <= temp_data;
                                    parse_state <= POS_Y;
                                end
                                POS_Y: begin
                                    camera_pos_y <= temp_data;
                                    parse_state <= POS_Z;
                                end
                                POS_Z: begin
                                    camera_pos_z <= temp_data;
                                    parse_state <= DIR_X;
                                end
                                DIR_X: begin
                                    camera_dir_x <= temp_data;
                                    parse_state <= DIR_Y;
                                end
                                DIR_Y: begin
                                    camera_dir_y <= temp_data;
                                    parse_state <= DIR_Z;
                                end
                                DIR_Z: begin
                                    camera_dir_z <= temp_data;
                                    parse_state <= WAITING;
                                end
                            endcase
                            byte_count <= 0;
                            temp_data <= 0;
                        end else begin
                            temp_data <= (temp_data * 10) + (uart_data - "0");
                            byte_count <= byte_count + 1;
                        end
                    end
                endcase
            end
        end
    end
endmodule
