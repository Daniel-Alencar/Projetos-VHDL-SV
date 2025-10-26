library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- ============================================================================
-- FIFO TX - Interface AXI-Stream
-- Recebe dados via AXI-Stream (axis_tdata, axis_tvalid, axis_tready)
-- e armazena internamente, disponibilizando-os na saída (fifo_tdata, fifo_tvalid)
-- ============================================================================

entity fifo_tx is
  generic (
    DATA_WIDTH : integer := 8;   -- Largura do dado (bits)
    DEPTH      : integer := 16   -- Profundidade (número de palavras)
  );
  port (
    clk          : in  std_logic;
    reset_n      : in  std_logic;

    -- Interface AXI-Stream de entrada
    axis_tdata   : in  std_logic_vector(DATA_WIDTH-1 downto 0);
    axis_tvalid  : in  std_logic;
    axis_tready  : out std_logic;

    -- Saída do FIFO
    fifo_tdata   : out std_logic_vector(DATA_WIDTH-1 downto 0);
    fifo_tvalid  : out std_logic
  );
end fifo_tx;

architecture rtl of fifo_tx is

  ---------------------------------------------------------------------------
  -- Função auxiliar: retorna o número mínimo de bits para representar "n"
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
  -- Tipos e sinais internos
  ---------------------------------------------------------------------------
  type fifo_mem_t is array (0 to DEPTH-1) of std_logic_vector(DATA_WIDTH-1 downto 0);
  signal fifo_mem : fifo_mem_t := (others => (others => '0'));

  signal wr_ptr   : unsigned(clog2(DEPTH)-1 downto 0) := (others => '0');
  signal rd_ptr   : unsigned(clog2(DEPTH)-1 downto 0) := (others => '0');
  signal count    : unsigned(clog2(DEPTH + 1)-1 downto 0) := (others => '0');

  signal full     : std_logic := '0';
  signal empty    : std_logic := '1';

  -- Sinais internos para as saídas
  signal fifo_tdata_i  : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');
  signal fifo_tvalid_i : std_logic := '0';

begin

  ---------------------------------------------------------------------------
  -- FIFO WRITE LOGIC (entrada AXIS)
  ---------------------------------------------------------------------------
  process(clk, reset_n)
  begin
    if reset_n = '0' then
      wr_ptr <= (others => '0');
      count  <= (others => '0');
      full   <= '0';
      empty  <= '1';
    elsif rising_edge(clk) then
      -- Escrita se houver dado válido e FIFO não estiver cheio
      if axis_tvalid = '1' and full = '0' then
        fifo_mem(to_integer(wr_ptr)) <= axis_tdata;
        wr_ptr <= wr_ptr + 1;
        if count = DEPTH - 1 then
          full <= '1';
        end if;
        count <= count + 1;
        empty <= '0';
      end if;

      -- Atualiza flags se leitura ocorrer (ver lógica abaixo)
      if fifo_tvalid_i = '1' and empty = '0' then
        count <= count - 1;
        if count = 1 then
          empty <= '1';
        end if;
        full <= '0';
      end if;
    end if;
  end process;

  ---------------------------------------------------------------------------
  -- FIFO READ LOGIC (saída para próximo módulo)
  ---------------------------------------------------------------------------
  process(clk, reset_n)
  begin
    if reset_n = '0' then
      rd_ptr <= (others => '0');
    elsif rising_edge(clk) then
      if fifo_tvalid_i = '1' and empty = '0' then
        rd_ptr <= rd_ptr + 1;
      end if;
    end if;
  end process;

  ---------------------------------------------------------------------------
  -- Controle AXI e sinais de status
  ---------------------------------------------------------------------------
  axis_tready   <= not full;

  fifo_tdata_i  <= fifo_mem(to_integer(rd_ptr));
  fifo_tvalid_i <= not empty;

  -- Mapeamento final das saídas
  fifo_tdata  <= fifo_tdata_i;
  fifo_tvalid <= fifo_tvalid_i;

end rtl;
