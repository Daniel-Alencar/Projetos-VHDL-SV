library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity fifo_rx is
  generic (
    DATA_LEN : natural := 8;  -- Largura do dado (Bits)
    DEPTH    : natural := 16  -- Profundidade do FIFO
  );
  port (
    clk          : in  std_logic;
    reset_n      : in  std_logic;

    -- Interface de Entrada (Vem do UART RX - AXI Stream)
    axis_tdata   : in  std_logic_vector(DATA_LEN-1 downto 0);
    axis_tvalid  : in  std_logic;
    axis_tready  : out std_logic; -- Flow control para o UART RX

    -- Interface de Saída (Vai para o UART 2 AXIS Controller)
    -- Nomes conforme o diagrama de arquitetura
    frame_data   : out std_logic_vector(DATA_LEN-1 downto 0);
    fifo_valid   : out std_logic; -- Indica que o FIFO tem dados (not empty)
    fifo_ready   : in  std_logic  -- Controller indica que leu o dado
  );
end fifo_rx;

architecture rtl of fifo_rx is

  -- Função para calcular log2 (para dimensionar ponteiros)
  function clog2(n : natural) return natural is
    variable i : natural := 0;
    variable v : natural := 1;
  begin
    while v < n loop
      v := v * 2;
      i := i + 1;
    end loop;
    return i;
  end function;

  -- Definição da Memória
  type fifo_mem_t is array(0 to DEPTH-1) of std_logic_vector(DATA_LEN-1 downto 0);
  signal fifo_mem : fifo_mem_t;

  -- Ponteiros e contadores
  signal wr_ptr : unsigned(clog2(DEPTH)-1 downto 0) := (others => '0');
  signal rd_ptr : unsigned(clog2(DEPTH)-1 downto 0) := (others => '0');
  signal count  : unsigned(clog2(DEPTH+1)-1 downto 0) := (others => '0');

  -- Flags internas
  signal full   : std_logic := '0';
  signal empty  : std_logic := '1';

  -- Sinais de controle de leitura/escrita física
  signal write_en : std_logic;
  signal read_en  : std_logic;

begin

  -- Lógica de Handshake
  -- Escreve se o dado é válido E o FIFO não está cheio
  write_en <= axis_tvalid and (not full);
  
  -- Lê (consome) se o FIFO não está vazio E o consumidor (Controller) está pronto
  read_en  <= (not empty) and fifo_ready;

  ---------------------------------------------------------------------------
  -- Processo Principal do FIFO
  ---------------------------------------------------------------------------
  process(clk, reset_n)
  begin
    if reset_n = '0' then
      wr_ptr <= (others => '0');
      rd_ptr <= (others => '0');
      count  <= (others => '0');
      full   <= '0';
      empty  <= '1';
    elsif rising_edge(clk) then

      -- Escrita
      if write_en = '1' then
        fifo_mem(to_integer(wr_ptr)) <= axis_tdata;
        wr_ptr <= wr_ptr + 1;
      end if;

      -- Leitura
      if read_en = '1' then
        rd_ptr <= rd_ptr + 1;
      end if;

      -- Atualização do Contador (Count)
      if (write_en = '1' and read_en = '0') then
        count <= count + 1;
      elsif (write_en = '0' and read_en = '1') then
        count <= count - 1;
      end if;

      -- Atualização da Flag FULL
      if (count = DEPTH-1 and write_en = '1' and read_en = '0') then
        full <= '1';
      elsif (read_en = '1') then
        full <= '0';
      end if;

      -- Atualização da Flag EMPTY
      if (count = 1 and read_en = '1' and write_en = '0') then
        empty <= '1';
      elsif (write_en = '1') then
        empty <= '0';
      end if;

    end if;
  end process;

  ---------------------------------------------------------------------------
  -- Saídas
  ---------------------------------------------------------------------------
  -- O dado de saída é sempre o apontado pelo ponteiro de leitura (FWFT logic)
  frame_data <= fifo_mem(to_integer(rd_ptr));
  
  fifo_valid  <= not empty;
  axis_tready <= not full;

end rtl;