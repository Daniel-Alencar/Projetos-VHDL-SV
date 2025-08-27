module i2c_master #(parameter OVERSAMPLING=4, RETRY_NUM=3)(
    input clk_in, n_rst, rd_wr, i2c_en, continuous,
    input [6:0] address_in,
    input [7:0] wr_data_in,
    // limite máximo de 32 bytes sequenciais
    input [5:0] wr_data_bytes,
    output ready_out, valid_out,
    inout SCL, SDA
);

// Declaração dos estados simbólicos
localparam reg [3:0]
idle = 4'b0000,
start = 4'b0001,
address = 4'b0010,
address_ack = 4'b0011,
write_data = 4'b0100,
write_data_ack = 4'b0101,
read_data = 4'b0110,
read_data_ack = 4'b0111,
retry = 4'b1000,
stop = 4'b1001;

// Declaração dos sinais
wire SCL_line;
reg [3:0] state, next_state;
reg SCL_reg, next_SCL;
reg SDA_reg, next_SDA;
reg [$clog2(OVERSAMPLING)-1:0] clk_cnt, next_clk;
reg [2:0] bit_cnt, next_bit;
reg [5:0] byte_cnt, next_byte;
reg [6:0] address_reg, next_address;
reg rd_wr_reg, next_rd_wr;
reg [7:0] wr_data_reg, next_wr_data;
reg ready_reg, next_ready;
reg [1:0] shift_valid_reg;
reg [7:0] word_reg, next_word;
reg ack_reg, next_ack;

// Registradores para a máquina de estados do comunicador I2C
always @(posedge clk_in, negedge n_rst)
if (~n_rst) begin
    state <= idle;
    SCL_reg <= 1'b1;
    SDA_reg <= 1'b1;
    clk_cnt <= 0;
    bit_cnt <= 0;
    byte_cnt <= 0;
    address_reg <= 0;
    rd_wr_reg <= 1'b0;
    wr_data_reg <= 0;
    ready_reg <= 1'b0;
    shift_valid_reg <= 2'b00;
    word_reg <= 0;
    ack_reg <= 1'b1;
end
else begin
    state <= next_state;
    SCL_reg <= next_SCL;
    SDA_reg <= next_SDA;
    clk_cnt <= next_clk;
    bit_cnt <= next_bit;
    byte_cnt <= next_byte;
    address_reg <= next_address;
    rd_wr_reg <= next_rd_wr;
    wr_data_reg <= next_wr_data;
    ready_reg <= next_ready;
    shift_valid_reg <= shift_valid_reg >> 1;
    word_reg <= next_word;
    //ack_reg <= next_ack;
    ack_reg <= 1'b0;
end

// Lógica combinacional para a transição entre estados
always @(*) begin
    next_state = state;
    next_clk = clk_cnt;
    next_bit = bit_cnt;
    next_byte = byte_cnt;
    case (state)
    idle:
    if (ready_reg && i2c_en) begin
        next_clk = 0;
        next_state = start;
    end
    start:
    if (clk_cnt == OVERSAMPLING-1) begin
        next_clk = 0;
        next_bit = 0;
        next_state = address;
    end
    else
    next_clk = clk_cnt + 1;
    address:
    if (clk_cnt == (3*OVERSAMPLING/4)-1 && SDA_reg != SDA_line)    
    next_state = retry;
    else if (clk_cnt == OVERSAMPLING-1) begin
        next_clk = 0;
        if (bit_cnt == 7)
        next_state = address_ack;
        else
        next_bit = bit_cnt + 1;
    end
    else if (sync_reg)
    next_clk = clk_cnt + 1;
    address_ack:
    if (clk_cnt == OVERSAMPLING-1) begin
        if (~ack_reg) begin
            next_clk = 0;
            next_bit = 0;
            if (~rd_wr)
            next_state = write_data;
            else
            next_state = read_data;
        end
        else
        next_state = retry;
    end
    else if (sync_reg)
    next_clk = clk_cnt + 1;
    write_data:
    if (clk_cnt == (3*OVERSAMPLING/4)-1 && SDA_reg != SDA_line)
    next_state = retry;
    else if (clk_cnt == OVERSAMPLING-1) begin
        next_clk = 0;
        if (bit_cnt == 7) begin
            if (byte_cnt == wr_data_bytes-1)
            next_byte = 0;
            else
            next_byte = byte_cnt + 1;            
            next_state = write_data_ack;
        end
        else
        next_bit = bit_cnt + 1;
    end
    else if (sync_reg)
    next_clk = clk_cnt + 1;
    write_data_ack:
    if (clk_cnt == OVERSAMPLING-1) begin
        if (~ack_reg) begin
            next_clk = 0;
            next_bit = 0;
            if (byte_cnt > 0)
                if (continuous)
                next_state = write_data;
                else
                next_state = start;
            else
            next_state = stop;
        end
        else
        next_state = retry;
    end
    else if (sync_reg)
    next_clk = clk_cnt + 1;
    read_data:      // a ser desenvolvido
    next_state = idle;
    read_data_ack:  // a ser desenvolvido
    next_state = idle;
    retry:          // a ser desenvolvido
    next_state = idle;
    stop:
    if (clk_cnt == OVERSAMPLING-1)
    next_state = idle;
    else if (sync_reg)
    next_clk = clk_cnt + 1;
    endcase
end

// Lógica combinacional para o clock serial SCL
always @(*) begin
    next_SCL = SCL_reg;
    case (state)
    idle:
    next_SCL = 1'b1;
    start:
    // condição para o "repeated start"
    if (clk_cnt == (OVERSAMPLING/2)-1)
    next_SCL = 1'b1;
    else if (clk_cnt == OVERSAMPLING-1)
    next_SCL = 1'b0;
    address:
    if (clk_cnt == (OVERSAMPLING/2)-1)
    next_SCL = 1'b1;
    else if (clk_cnt == OVERSAMPLING-1)
    next_SCL = 1'b0;
    address_ack:
    if (clk_cnt == (OVERSAMPLING/2)-1)
    next_SCL = 1'b1;
    else if (clk_cnt == OVERSAMPLING-1)
    next_SCL = 1'b0;
    write_data:
    if (clk_cnt == (OVERSAMPLING/2)-1)
    next_SCL = 1'b1;
    else if (clk_cnt == OVERSAMPLING-1)
    next_SCL = 1'b0;
    write_data_ack:
    if (clk_cnt == (OVERSAMPLING/2)-1)
    next_SCL = 1'b1;
    else if (clk_cnt == OVERSAMPLING-1)
    next_SCL = 1'b0;
    read_data:
    next_SCL = SCL_reg;
    read_data_ack:
    next_SCL = SCL_reg;
    retry:
    next_SCL = SCL_reg;
    stop:
    if (clk_cnt == (OVERSAMPLING/2)-1)
    next_SCL = 1'b1;
    endcase
end

// Lógica combinacional para a linha de dados serial SDA e para os demais registradores
always @(*) begin
    next_SDA = SDA_reg;
    next_address = address_reg;
    next_rd_wr = rd_wr_reg;
    next_wr_data = wr_data_reg;
    next_ready = ready_reg;
    shift_valid_reg = shift_valid_reg;
    next_word = word_reg;
    next_ack = ack_reg;
    case (state)
    idle:
    if (ready_reg && i2c_en) begin
        next_address = address_in;
        next_rd_wr = rd_wr;
        // se operação = escrita
        if (~rd_wr)
        next_wr_data = wr_data_in;
        next_ready = 1'b0;        
    end
    else begin
        if (~SCL_busy_reg)
        next_ready = 1'b1;
        shift_valid_reg = 2'b00;
        next_SDA = 1'b1;
    end
    start: begin
        if (clk_cnt == (3*OVERSAMPLING/4)-1)
        next_SDA = 1'b0;
        next_word = {address_reg, rd_wr_reg};
    end
    address:
    if (clk_cnt == (OVERSAMPLING/4)-1)
    next_SDA = word_reg[7];
    else if (clk_cnt == (3*OVERSAMPLING/4)-1)
    next_word = word_reg << 1;
    address_ack:
    if (clk_cnt == (OVERSAMPLING/4)-1)
    // permite verificar o ADDRESS_ACK
    next_SDA = 1'b1;        
    else if (clk_cnt == (3*OVERSAMPLING/4)-1)
    next_ack = SDA_line;
    else if (clk_cnt == OVERSAMPLING-1 && ~ack_reg && ~rd_wr)
    next_word = {wr_data_reg};
    write_data:
    if (clk_cnt == (OVERSAMPLING/4)-1)
    next_SDA = word_reg[7];
    else if (clk_cnt == (3*OVERSAMPLING/4)-1)
    next_word = word_reg << 1;
    write_data_ack:
    if (clk_cnt == (OVERSAMPLING/4)-1)
    // permite verificar o WRITE_DATA_ACK
    next_SDA = 1'b1;        
    else if (clk_cnt == (3*OVERSAMPLING/4)-1) begin
        next_ack = SDA_line;
        //shift_valid_reg = {~SDA_line, 1'b0};
        shift_valid_reg = 2'b10;
    end
    else if (clk_cnt == OVERSAMPLING-1 && ~ack_reg && byte_cnt > 0) begin
        next_wr_data = wr_data_in;
        if (continuous)
        next_word = wr_data_in;
    end
    stop:
    if (clk_cnt == (OVERSAMPLING/4)-1)
    next_SDA = 1'b0;
    else if (clk_cnt == (3*OVERSAMPLING/4)-1)
    next_SDA = 1'b1;
    read_data:
    next_SDA = SDA_reg;
    endcase
end

// verificação da disponibilidade da linha SCL
reg [$clog2(OVERSAMPLING)-1:0] SCL_busy_cnt = 0;
reg SCL_busy_reg = 1'b1;
always @(posedge clk_in)
if (~SCL_line) begin
    SCL_busy_cnt <= 0;
    SCL_busy_reg <= 1'b1;
end
else if (SCL_busy_cnt == OVERSAMPLING-1) begin
    SCL_busy_cnt <= 0;
    SCL_busy_reg <= 1'b0;
end
else
SCL_busy_cnt <= SCL_busy_cnt + 1;

// Verificação do sincronismo entre SCL_reg e SCL_line, feita no flanco
// negativo do clk_in para pausar a contagem de clock no próximo flanco de subida
reg sync_reg = 1'b0;
always @(negedge clk_in)
if (SCL_reg == SCL_line)
sync_reg = 1'b1;
else
sync_reg = 1'b0;

// Direcionamento dos registradores para as saídas
assign ready_out = ready_reg;
assign valid_out = shift_valid_reg[0];
//assign SCL = SCL_reg ? 1'bZ : 1'b0;
assign SCL = SCL_reg ? 1'b1 : 1'b0;
assign SCL_line = SCL;
//assign SDA = SDA_reg ? 1'bZ : 1'b0;
assign SDA = SDA_reg ? 1'b1 : 1'b0;
assign SDA_line = SDA;

endmodule