library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity fifo_UART is
  generic (
    DATA_WIDTH : integer := 8;
    DEPTH      : integer := 16
  );
  port (
    clk          : in  std_logic;
    reset_n      : in  std_logic;

    -- AXI-Stream de entrada
    axis_tdata   : in  std_logic_vector(DATA_WIDTH-1 downto 0);
    axis_tvalid  : in  std_logic;
    axis_tready  : out std_logic;

    -- Saída do FIFO com handshake
    fifo_tdata   : out std_logic_vector(DATA_WIDTH-1 downto 0);
    fifo_tvalid  : out std_logic;
    fifo_tready  : in  std_logic
  );
end fifo_UART;

architecture rtl of fifo_UART is

  ---------------------------------------------------------------------------
  -- Função auxiliar
  ---------------------------------------------------------------------------
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

  ---------------------------------------------------------------------------
  -- Sinais internos
  ---------------------------------------------------------------------------
  type fifo_mem_t is array(0 to DEPTH-1) of std_logic_vector(DATA_WIDTH-1 downto 0);
  signal fifo_mem : fifo_mem_t;

  signal wr_ptr   : unsigned(clog2(DEPTH)-1 downto 0) := (others => '0');
  signal rd_ptr   : unsigned(clog2(DEPTH)-1 downto 0) := (others => '0');
  signal count    : unsigned(clog2(DEPTH+1)-1 downto 0) := (others => '0');

  signal full     : std_logic := '0';
  signal empty    : std_logic := '1';

  signal fifo_tdata_i  : std_logic_vector(DATA_WIDTH-1 downto 0);
  signal fifo_tvalid_i : std_logic;

  -- Enable de escrita e leitura reais
  signal write_en : std_logic;
  signal read_en  : std_logic;

begin

  ---------------------------------------------------------------------------
  -- Handshake interno
  ---------------------------------------------------------------------------
  write_en <= axis_tvalid and (not full);
  read_en  <= fifo_tvalid_i and fifo_tready;  -- *** LEITURA REAL ***

  ---------------------------------------------------------------------------
  -- Escrita no FIFO
  ---------------------------------------------------------------------------
  process(clk, reset_n)
  begin
    if reset_n = '0' then
      wr_ptr <= (others => '0');
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
        count <= count - 1;
      end if;

      -- Contagem (caso haja escrita)
      if write_en = '1' then
        count <= count + 1;
      end if;

      -- Atualização de flags
      if (count = DEPTH-1 and write_en = '1' and read_en = '0') then
        full <= '1';
      elsif (read_en = '1') then
        full <= '0';
      end if;

      if (count = 1 and read_en = '1' and write_en = '0') then
        empty <= '1';
      elsif (write_en = '1') then
        empty <= '0';
      end if;

    end if;
  end process;

  ---------------------------------------------------------------------------
  -- Leitura: avanço do ponteiro
  ---------------------------------------------------------------------------
  process(clk, reset_n)
  begin
    if reset_n = '0' then
      rd_ptr <= (others => '0');
    elsif rising_edge(clk) then
      if read_en = '1' then
        rd_ptr <= rd_ptr + 1;
      end if;
    end if;
  end process;

  ---------------------------------------------------------------------------
  -- Saídas
  ---------------------------------------------------------------------------
  fifo_tdata_i  <= fifo_mem(to_integer(rd_ptr));
  fifo_tvalid_i <= not empty;

  axis_tready <= not full;

  fifo_tdata  <= fifo_tdata_i;
  fifo_tvalid <= fifo_tvalid_i;

end rtl;
