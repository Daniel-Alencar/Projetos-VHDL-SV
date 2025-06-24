module uart_rx (
    input wire clk,
    input wire n_rst,
    input wire rx,
    output wire ready_out,
    output wire valid_out,
    output wire [7:0] data_out
);

    // Estados
    parameter idle  = 2'b00;
    parameter start = 2'b01;
    parameter data  = 2'b10;
    parameter stop  = 2'b11;

    // Registradores internos
    reg [7:0] data_reg;
    reg ready_reg, valid_reg;
    reg [1:0] state;
    reg [3:0] clk_cnt;
    reg [2:0] data_cnt;

    // Máquina de estados
    always @(posedge clk or negedge n_rst) begin
        if (!n_rst) begin
            state     <= idle;
            valid_reg <= 1'b0;
            ready_reg <= 1'b0;
            data_reg  <= 8'b0;
            clk_cnt   <= 4'd0;
            data_cnt  <= 3'd0;
        end else begin
            case (state)
                idle: begin
                    ready_reg <= 1'b1;
                    if (~rx) begin
                        state <= start;
                        clk_cnt <= 4'd0;
                        ready_reg <= 1'b0;
                    end
                end

                start: begin
                    if (clk_cnt == 4'd7) begin
                        clk_cnt <= 4'd0;
                        if (~rx)
                            state <= data;
                        else
                            state <= idle;
                    end else begin
                        clk_cnt <= clk_cnt + 1;
                    end
                end

                data: begin
                    if (clk_cnt == 4'd15) begin
                        clk_cnt <= 4'd0;
                        data_reg <= {rx, data_reg[7:1]};
                        if (data_cnt == 3'd7) begin
                            data_cnt <= 3'd0;
                            valid_reg <= 1'b1;
                            state <= stop;
                        end else begin
                            data_cnt <= data_cnt + 1;
                        end
                    end else begin
                        clk_cnt <= clk_cnt + 1;
                    end
                end

                stop: begin
                    if (clk_cnt == 4'd15) begin
                        clk_cnt <= 4'd0;
                        if (rx) begin
                            valid_reg <= 1'b0;
                            state <= idle;
                        end
                    end else begin
                        clk_cnt <= clk_cnt + 1;
                    end
                end
            endcase
        end
    end

    assign data_out  = data_reg;
    assign valid_out = valid_reg;
    assign ready_out = ready_reg;

endmodule
