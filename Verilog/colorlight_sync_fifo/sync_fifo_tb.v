module sync_fifo_tb #(parameter DATA_BITS=8)(
    input clk_in, n_rst, fifo_empty_in, fifo_full_in, uart_rx_valid_in, uart_tx_ready_in,
    input [DATA_BITS-1:0] uart_rx_data_in, fifo_rd_data_in,    
    output fifo_wr_en, fifo_rd_en, uart_tx_en,
    output [DATA_BITS-1:0] fifo_wr_data_out, uart_tx_data_out
);

    localparam reg [1:0]
    wr_idle = 2'b00,
    write = 2'b01,
    full = 2'b10;
    localparam reg [1:0]
    rd_idle = 2'b00,
    read = 2'b01,
    empty = 2'b10;

    // Declaração dos sinais
    reg [DATA_BITS-1:0] fifo_wr_data_reg;
    reg [DATA_BITS-1:0] uart_tx_data_reg;
    reg fifo_wr_en_reg, fifo_rd_en_reg, uart_tx_en_reg;

    // Máquina de estados de escrita no buffer
    always @(posedge clk_in, negedge n_rst) begin: fifo_write
        reg [1:0] state;
        if(~n_rst) begin
            state <= wr_idle;
            fifo_wr_data_reg <= 0;
            fifo_wr_en_reg <= 1'b0;
        end
        else begin
            case(state)
                wr_idle: begin
                    fifo_wr_data_reg <= 0;
                    if(~fifo_full_in && uart_rx_valid_in && uart_rx_data_in == "w") begin
                        state <= write;
                    end
                end
                write: begin
                    fifo_wr_en_reg <= 1'b1;
                    state <= full;
                end
                full: begin
                    fifo_wr_en_reg <= 1'b0;
                    if(fifo_full_in) begin
                        state <= wr_idle;
                    end
                    else begin
                        fifo_wr_data_reg <= fifo_wr_data_reg + 1;
                        state <= write;
                    end
                end
            endcase
        end
    end

    // Máquina de estados de leitura no buffer
    always @(posedge clk_in, negedge n_rst) begin: fifo_read
        reg [1:0] state;
        if(~n_rst) begin
            state <= rd_idle;
            uart_tx_data_reg <= 0;
            fifo_rd_en_reg <= 1'b0;
            uart_tx_en_reg <= 1'b0;
        end
        else begin
            case(state)
                rd_idle: begin
                    uart_tx_en_reg <= 1'b0;
                    if(~fifo_empty_in && uart_rx_valid_in && uart_rx_data_in == "r") begin
                        state <= read;
                    end
                end

                read: begin
                    uart_tx_en_reg <= 1'b0;
                    if(uart_tx_ready_in) begin
                        fifo_rd_en_reg <= 1'b1;
                        uart_tx_data_reg <= fifo_rd_data_in;
                        state <= empty;
                    end
                end

                empty: begin
                    fifo_rd_en_reg <= 1'b0;
                    uart_tx_en_reg <= 1'b1;
                    if(~uart_tx_ready_in) begin
                        if(fifo_empty_in)
                            state <= rd_idle;
                        else
                            state <= read;
                    end
                end
            endcase
        end
    end

    // Direcionamento dos registradores para as saídas
    assign fifo_wr_data_out = fifo_wr_data_reg;
    assign uart_tx_data_out = uart_tx_data_reg;
    assign fifo_wr_en = fifo_wr_en_reg;
    assign fifo_rd_en = fifo_rd_en_reg;
    assign uart_tx_en = uart_tx_en_reg;

endmodule