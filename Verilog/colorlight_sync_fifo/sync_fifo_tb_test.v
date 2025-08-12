module sync_fifo_tb #(parameter DATA_BITS=8)(
    input clk_in, n_rst, fifo_empty_in, fifo_full_in, uart_rx_valid_in, uart_tx_ready_in,
    input [DATA_BITS-1:0] uart_rx_data_in, fifo_rd_data_in,    
    output reg fifo_wr_en, fifo_rd_en, uart_tx_en,
    output reg [DATA_BITS-1:0] fifo_wr_data_out, uart_tx_data_out
);

    // Estados
    localparam reg [1:0]
    IDLE = 2'b00,
    WRITE_RUN = 2'b01,
    READ_RUN = 2'b10;

    reg [1:0] state, next_state;
    // contar de 0 até 1023
    reg [9:0] count, next_count;

    // Registradores de saída
    reg [DATA_BITS-1:0] next_fifo_wr_data_out;
    reg next_fifo_wr_en, next_fifo_rd_en, next_uart_tx_en;
    reg [DATA_BITS-1:0] next_uart_tx_data_out;

    // Máquina de estados sequencial
    always @(posedge clk_in, negedge n_rst) begin
        if(~n_rst) begin
            state <= IDLE;
            count <= 0;

            fifo_wr_data_out <= 0;
            uart_tx_data_out <= 0;
            fifo_wr_en <= 0;
            fifo_rd_en <= 0;
            uart_tx_en <= 0;
        end
        else begin
            state <= next_state;
            count <= next_count;

            fifo_wr_data_out <= next_fifo_wr_data_out;
            uart_tx_data_out <= next_uart_tx_data_out;
            fifo_wr_en <= next_fifo_wr_en;
            fifo_rd_en <= next_fifo_rd_en;
            uart_tx_en <= next_uart_tx_en;
        end
    end

    always @(*)
    begin
        // Valores padrão para todos os registradores
        next_state = state;
        next_count = count;

        next_fifo_wr_en = 0;
        next_fifo_rd_en = 0;
        next_uart_tx_en = 0;
        next_fifo_wr_data_out = fifo_wr_data_out;
        next_uart_tx_data_out = uart_tx_data_out;

        case(state)
            IDLE: begin
                if(uart_rx_valid_in) begin
                    if(uart_rx_data_in == "w") begin
                        next_state = WRITE_RUN;
                        next_count = 0;
                    end
                    else if(uart_rx_data_in == "r") begin
                        next_state = READ_RUN;
                        next_count = 0;
                    end
                end
            end
            WRITE_RUN: begin
                next_fifo_wr_en = 1;
                next_fifo_wr_data_out = count;

                if (fifo_full_in || count == 255) begin
                    next_state = IDLE;
                    next_fifo_wr_en = 0;
                end
                else begin
                    next_count = count + 1;
                end
            end
            READ_RUN: begin
                if (~fifo_empty_in && uart_tx_ready_in) begin
                    next_fifo_rd_en = 1;
                    next_uart_tx_en = 1;
                    next_uart_tx_data_out = fifo_rd_data_in;
                end
                else begin
                    next_fifo_rd_en = 0;
                    next_uart_tx_en = 0;
                end

                if (fifo_empty_in) begin
                    next_state = IDLE;
                end
            end

        endcase
    end

endmodule