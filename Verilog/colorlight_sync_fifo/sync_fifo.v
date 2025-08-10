module sync_fifo #(parameter DATA_BITS=8, ADDRESS_BITS=10)(
  input clk_in, n_rst, wr_en, rd_en,
  input [DATA_BITS-1:0] wr_data_in,
  output empty, full,
  output [DATA_BITS-1:0] rd_data_out
);
// Declaração dos registradores
reg [ADDRESS_BITS-1:0] wr_ptr, next_wr_ptr;
reg [ADDRESS_BITS-1:0] rd_ptr, next_rd_ptr;
reg [DATA_BITS-1:0] data_reg [0:2**ADDRESS_BITS-1];
reg empty_reg, next_empty;
reg full_reg, next_full;
// Registradores para a máquina de estados do FIFO síncrono
always @(posedge clk_in, negedge n_rst) begin
  if (~n_rst) begin
    wr_ptr <= 0;
    rd_ptr <= 0;
    empty_reg <= 1'b1;
    full_reg <= 1'b0;
  end
  else begin
    wr_ptr <= next_wr_ptr;
    rd_ptr <= next_rd_ptr;
    empty_reg <= next_empty;
    full_reg <= next_full;
  end
end
// Lógica combinacional para a máquina de estados do FIFO síncrono
always @(*) begin
  next_wr_ptr = wr_ptr;
  next_rd_ptr = rd_ptr;
  next_empty = empty_reg;
  next_full = full_reg;
  case ({rd_en, wr_en})
  2'b01: begin
    if (~full_reg) begin
      next_wr_ptr = wr_ptr + 1;
      next_empty = 1'b0;
      if (next_wr_ptr == rd_ptr)
      next_full = 1'b1;
    end
  end
  2'b10: begin
    if (~empty_reg)  begin
      next_rd_ptr = rd_ptr + 1;
      next_full = 1'b0;
      if (next_rd_ptr == wr_ptr)
      next_empty = 1'b1;
    end
  end
  2'b11: begin
    next_wr_ptr = wr_ptr + 1;
    next_rd_ptr = rd_ptr + 1;
  end
  endcase
end
// Bloco de escrita de dados
always @(posedge clk_in)
if (~full_reg & wr_en)
data_reg[wr_ptr] <= wr_data_in;
// Direcionamento do registrador de dados para a saída de leitura
assign rd_data_out = data_reg[rd_ptr];
// Direcionamento dos registradores para as saídas
assign empty = empty_reg;
assign full = full_reg;
endmodule
