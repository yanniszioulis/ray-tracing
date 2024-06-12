module uart_rx (
    input logic clk,
    input logic reset,
    input logic rx,
    output logic [7:0] data,
    output logic data_valid
);
    // UART parameters
    parameter CLK_FREQ = 50000000; // 50 MHz clock
    parameter BAUD_RATE = 115200;

    // Calculate number of clock cycles per baud
    localparam integer CYCLES_PER_BIT = CLK_FREQ / BAUD_RATE;

    // UART receiver state machine
    typedef enum logic [2:0] {
        IDLE,
        START_BIT,
        DATA_BITS,
        STOP_BIT
    } uart_rx_state_t;

    uart_rx_state_t state;
    logic [3:0] bit_index;
    logic [15:0] cycle_count;

    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= IDLE;
            bit_index <= 0;
            cycle_count <= 0;
            data_valid <= 0;
        end else begin
            case (state)
                IDLE: begin
                    data_valid <= 0;
                    if (!rx) begin
                        state <= START_BIT;
                        cycle_count <= CYCLES_PER_BIT / 2;
                    end
                end
                START_BIT: begin
                    if (cycle_count == CYCLES_PER_BIT) begin
                        state <= DATA_BITS;
                        bit_index <= 0;
                        cycle_count <= 0;
                    end else begin
                        cycle_count <= cycle_count + 1;
                    end
                end
                DATA_BITS: begin
                    if (cycle_count == CYCLES_PER_BIT) begin
                        data[bit_index] <= rx;
                        bit_index <= bit_index + 1;
                        cycle_count <= 0;
                        if (bit_index == 7) begin
                            state <= STOP_BIT;
                        end
                    end else begin
                        cycle_count <= cycle_count + 1;
                    end
                end
                STOP_BIT: begin
                    if (cycle_count == CYCLES_PER_BIT) begin
                        data_valid <= 1;
                        state <= IDLE;
                    end else begin
                        cycle_count <= cycle_count + 1;
                    end
                end
            endcase
        end
    end
endmodule
