module spi_master_ctrl #(parameter DATA_BITS=8) (
    input clk_in, n_rst, spi_ready_in, spi_valid_in, enable,
    input [DATA_BITS-1:0] spi_data_r,
    output tied_SS_out, spi_enable_out, ready_out, valid_out,
    output [DATA_BITS-1:0] spi_data_t,
    output [5:0] spi_data_words,
    output [DATA_BITS-1:0] reg_1_out, reg_2_out, reg_3_out, reg_4_out
);

    // Palavras a serem transmitidas
    reg [DATA_BITS-1:0] word_1 = 8'hFA;
    reg [DATA_BITS-1:0] word_2 = 8'hFB;
    reg [DATA_BITS-1:0] word_3 = 8'hFC;
    reg [DATA_BITS-1:0] word_4 = 8'hFD;

    // Registradores das palavras a serem recebidas
    reg [DATA_BITS-1:0] reg_1, next_reg_1;
    reg [DATA_BITS-1:0] reg_2, next_reg_2;
    reg [DATA_BITS-1:0] reg_3, next_reg_3;
    reg [DATA_BITS-1:0] reg_4, next_reg_4;

    // Declaração dos sinais
    reg [3:0] state, next_state;
    reg ready_reg, next_ready;
    reg [5:0] spi_data_words_reg, next_spi_data_words;
    reg tied_SS_reg, next_spi_en;
    reg [DATA_BITS-1:0] spi_data_t_reg, next_spi_data_t;

    // Declaração dos estados simbólicos
    localparam reg [3:0]
    idle = 0,
    t1 = 1,
    r1 = 2,
    t2 = 3,
    r2 = 4,
    t3 = 5,
    r3 = 6,
    t4 = 7,
    r4 = 8;

    // Registradores da máquina de estados para o controlador do módulo SPI master
    always_ff @(posedge clk_in, negedge n_rst) begin
        if(~n_rst) begin
            reg_1 <= 0;
            reg_2 <= 0;
            reg_3 <= 0;
            reg_4 <= 0;
            state <= idle;
            ready_reg <= 1'b0;
            spi_data_words_reg <= 0;
            tied_SS_reg <= 1'b0;
            spi_en_reg <= 1'b0;
            spi_data_t_reg <= 0;
        end
        else begin
            reg_1 <= next_reg_1;
            reg_2 <= next_reg_2;
            reg_3 <= next_reg_3;
            reg_4 <= next_reg_4;
            ready_reg <= next_ready;
            spi_data_words_reg <= next_spi_data_words;
            tied_SS_reg <= next_tied_SS;
            spi_en_reg <= next_spi_en;
            spi_data_t_reg <= next_spi_data_t;
        end
    end

    // Lógica combinacional para o controlador do módulo SPI master
    always_comb begin
        next_state = state;
        next_ready = ready_reg;
        next_spi_data_words = spi_data_words_reg;
        next_tied_SS = tied_SS_reg;
        next_spi_en = spi_en_reg;
        next_spi_data_t = spi_data_t_reg;

        case(state)
            idle: begin
                if(spi_ready_in && enable) begin
                    next_ready = 1'b0;
                    next_spi_data_words = 4;
                    next_tied_SS = 1'b1;
                    next_state = t1;
                end
                else begin
                    next_ready = 1'b1;
                    next_spi_data_words = 0;
                    next_tied_SS = 1'b0;
                end
            end
            t1: begin
                next_spi_data_t = word_1;
                next_spi_en = 1'b1;
                next_state = r1;
            end
            r1: begin
                next_spi_en = 1'b0;
                if(spi_valid_in) begin
                    next_reg_1 = spi_data_r;
                    next_state = t2;
                end
            end
            t2: begin
                next_spi_data_t = word_2;
                next_state = r2;
            end
            r2: begin
                if(spi_valid_in) begin
                    next_reg_2 = spi_data_r;
                    next_state = t3;
                end
            end
            t3: begin
                next_spi_data_t = word_3;
                next_state = r3;
            end
            r3: begin
                if(spi_valid_in) begin
                    next_reg_3 = spi_data_r;
                    next_state = t4;
                end
            end
            t4: begin
                next_spi_data_t = word_4;
                next_state = r4;
            end
            r4: begin
                if(spi_valid_in) begin
                    next_reg_4 = spi_data_r;
                    next_state = idle;
                end
            end
        endcase
    end

    // Direcionamento das saídas
    assign ready_out = ready_reg;
    assign spi_data_words = spi_data_words_reg;
    assign tied_SS_out = tied_SS_reg;
    assign spi_en_out = spi_en_reg;
    assign spi_data_t = spi_data_t_reg;

    assign reg_1_out = reg_1;
    assign reg_2_out = reg_2;
    assign reg_3_out = reg_3;
    assign reg_4_out = reg_4;

    assign valid_out = spi_valid_in;

endmodule