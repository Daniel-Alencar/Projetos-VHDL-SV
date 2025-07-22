module bmp280_ctrl (
    input clk, n_rst, uart_ready_in, uart_valid_in, spi_ready_in, spi_valid_in,
    input [7:0] uart_data_in, spi_data_in,
    output uart_en, tied_SS, spi_en,
    output [7:0] uart_data_out, spi_data_out,
    output [5:0] spi_data_words
);

// Declaração dos estados simbólicos
localparam reg [4:0]
idle = 0,
add_id = 1,
rd_id = 2,
add_status = 3,
rd_status = 4,
add_ctrl_meas = 5,
wr_ctrl_meas = 6,
add_config = 7,
wr_config = 8,
add_press_msb = 9,
rd_press_msb = 10,
add_press_lsb = 11,
rd_press_lsb = 12,
add_press_xlsb = 13,
rd_press_xlsb = 14,
add_temp_msb = 15,
rd_temp_msb = 16,
add_temp_lsb = 17,
rd_temp_lsb = 18,
add_temp_xlsb = 19,
rd_temp_xlsb = 20;

// Declaração dos sinais
reg [4:0] state, next_state;
reg [4:0] word_cnt, next_word;
reg [5:0] data_words_reg, next_data_words;
reg [7:0] spi_data_reg, next_spi_data;
reg [7:0] uart_data_reg, next_uart_data;
reg tied_SS_reg, next_tied_SS;
reg spi_en_reg, next_spi_en;
reg uart_en_reg, next_uart_en;

// Registradores da máquina de estados para o controlador BMP280
always @(posedge clk, negedge n_rst) begin
    if (~n_rst) begin
        state <= idle;
        word_cnt <= 0;
        data_words_reg <= 0;
        spi_data_reg <= '0;
        uart_data_reg <= '0;
        tied_SS_reg <= 1'b0;
        spi_en_reg <= 1'b0;
        uart_en_reg <= 1'b0;
    end
    else begin
        state <= next_state;
        word_cnt <= next_word;
        data_words_reg <= next_data_words;
        spi_data_reg <= next_spi_data;
        uart_data_reg <= next_uart_data;
        tied_SS_reg <= next_tied_SS;
        spi_en_reg <= next_spi_en;
        uart_en_reg <= next_uart_en;
    end
end

// Lógica combinacional da máquina de estados para o controlador BMP280
always @(*) begin
    next_state = state;
    next_word = word_cnt;
    next_data_words = data_words_reg;
    next_spi_data = spi_data_reg;
    next_uart_data = uart_data_reg;
    next_tied_SS = tied_SS_reg;
    next_spi_en = spi_en_reg;
    next_uart_en = uart_en_reg;
    case (state)
    idle: begin
        next_uart_en = 1'b0;
        next_tied_SS = 1'b0;
        if (uart_valid_in && uart_data_in == "m")
        next_state = add_id;
    end
    add_id: begin
        if (spi_ready_in && uart_ready_in) begin
            next_tied_SS = 1'b1;
            next_data_words = 2;
            next_spi_data = 8'hD0;
            next_spi_en = 1'b1;
            next_word = 0;
            next_state = rd_id;
        end
    end
    rd_id: begin
        next_spi_en = 1'b0;
        if (word_cnt == 2) begin            
            next_uart_en = 1'b1;
            if (~uart_ready_in)
            next_state = add_status;
        end
        else if (spi_valid_in) begin  
            next_uart_data = spi_data_in;          
            next_word = word_cnt + 1;
        end        
    end
    add_status: begin
        next_uart_en = 1'b0;
        if (spi_ready_in && uart_ready_in) begin            
            next_data_words = 2;
            next_spi_data = 8'hF3;
            next_spi_en = 1'b1;
            next_word = 0;
            next_state = rd_status;
        end
    end
    rd_status: begin
        next_spi_en = 1'b0;
        if (word_cnt == 2) begin       
            next_uart_en = 1'b1;
            if (~uart_ready_in)
            next_state = add_ctrl_meas;
        end
        else if (spi_valid_in) begin   
            next_uart_data = spi_data_in;         
            next_word = word_cnt + 1;
        end
    end
    add_ctrl_meas: begin
        next_uart_en = 1'b0;
        if (spi_ready_in) begin         // Somente escrita
            next_data_words = 2;
            next_spi_data = 8'h74;
            next_spi_en = 1'b1;
            next_word = 0;
            next_state = wr_ctrl_meas;
        end
    end
    wr_ctrl_meas: begin
        next_spi_en = 1'b0;
        if (word_cnt == 2) begin
            next_state = add_config;
        end
        else if (spi_valid_in) begin
            next_spi_data = 8'b01011101;
            next_word = word_cnt + 1;
        end
    end
    add_config: begin
        if (spi_ready_in) begin         // Somente escrita
            next_data_words = 2;
            next_spi_data = 8'h75;
            next_spi_en = 1'b1;
            next_word = 0;
            next_state = wr_config;
        end
    end
    wr_config: begin
        next_spi_en = 1'b0;
        if (word_cnt == 2) begin
            next_state = add_press_msb;
        end
        else if (spi_valid_in) begin
            next_spi_data = 8'b00010000;
            next_word = word_cnt + 1;
        end
    end
    add_press_msb: begin
        if (spi_ready_in && uart_ready_in) begin            
            next_data_words = 2;
            next_spi_data = 8'hF7;
            next_spi_en = 1'b1;
            next_word = 0;
            next_state = rd_press_msb;
        end
    end
    rd_press_msb: begin
        next_spi_en = 1'b0;
        if (word_cnt == 2) begin        
            next_uart_en = 1'b1;
            if (~uart_ready_in)
            next_state = add_press_lsb;
        end
        else if (spi_valid_in) begin  
            next_uart_data = spi_data_in;          
            next_word = word_cnt + 1;
        end
    end
    add_press_lsb: begin
        next_uart_en = 1'b0;
        if (spi_ready_in && uart_ready_in) begin            
            next_data_words = 2;
            next_spi_data = 8'hF8;
            next_spi_en = 1'b1;
            next_word = 0;
            next_state = rd_press_lsb;
        end
    end
    rd_press_lsb: begin
        next_spi_en = 1'b0;
        if (word_cnt == 2) begin       
            next_uart_en = 1'b1;
            if (~uart_ready_in)
            next_state = add_press_xlsb;
        end
        else if (spi_valid_in) begin    
            next_uart_data = spi_data_in;        
            next_word = word_cnt + 1;
        end
    end
    add_press_xlsb: begin
        next_uart_en = 1'b0;
        if (spi_ready_in && uart_ready_in) begin            
            next_data_words = 2;
            next_spi_data = 8'hF9;
            next_spi_en = 1'b1;
            next_word = 0;
            next_state = rd_press_xlsb;
        end
    end
    rd_press_xlsb: begin
        next_spi_en = 1'b0;
        if (word_cnt == 2) begin     
            next_uart_en = 1'b1;
            if (~uart_ready_in)
            next_state = add_temp_msb;
        end
        else if (spi_valid_in) begin    
            next_uart_data = spi_data_in;        
            next_word = word_cnt + 1;
        end
    end
    add_temp_msb: begin
        next_uart_en = 1'b0;
        if (spi_ready_in && uart_ready_in) begin            
            next_data_words = 2;
            next_spi_data = 8'hFA;
            next_spi_en = 1'b1;
            next_word = 0;
            next_state = rd_temp_msb;
        end
    end
    rd_temp_msb: begin
        next_spi_en = 1'b0;
        if (word_cnt == 2) begin   
            next_uart_en = 1'b1;
            if (~uart_ready_in)
            next_state = add_temp_lsb;
        end
        else if (spi_valid_in) begin        
            next_uart_data = spi_data_in;    
            next_word = word_cnt + 1;
        end
    end
    add_temp_lsb: begin
        next_uart_en = 1'b0;
        if (spi_ready_in && uart_ready_in) begin            
            next_data_words = 2;
            next_spi_data = 8'hFB;
            next_spi_en = 1'b1;
            next_word = 0;
            next_state = rd_temp_lsb;
        end
    end
    rd_temp_lsb: begin
        next_spi_en = 1'b0;
        if (word_cnt == 2) begin   
            next_uart_en = 1'b1;
            if (~uart_ready_in)
            next_state = add_temp_xlsb;
        end
        else if (spi_valid_in) begin      
            next_uart_data = spi_data_in;      
            next_word = word_cnt + 1;
        end
    end
    add_temp_xlsb: begin
        next_uart_en = 1'b0;
        if (spi_ready_in && uart_ready_in) begin            
            next_data_words = 2;
            next_spi_data = 8'hFC;
            next_spi_en = 1'b1;
            next_word = 0;
            next_state = rd_temp_xlsb;
        end
    end
    rd_temp_xlsb: begin
        next_spi_en = 1'b0;
        if (word_cnt == 2) begin   
            next_uart_en = 1'b1;
            if (~uart_ready_in)
            next_state = idle;
        end
        else if (spi_valid_in) begin         
            next_uart_data = spi_data_in;   
            next_word = word_cnt + 1;
        end
    end
    endcase
end

// Direcionamento dos registradores para as saídas
assign tied_SS = tied_SS_reg;
assign spi_en = spi_en_reg;
assign uart_en = uart_en_reg;
assign uart_data_out = uart_data_reg;
assign spi_data_out = spi_data_reg;
assign spi_data_words = data_words_reg;

/* Após a aquisição dos bits correspondentes às leituras
de pressão e temperatura, deverão ser feitos cálculos para a conversão
para as respectivas unidades de medida.*/

endmodule