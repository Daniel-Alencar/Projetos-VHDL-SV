library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity image_filter is
  generic (
    IMG_WIDTH  : integer := 150; -- Largura da imagem
    IMG_HEIGHT : integer := 100  -- Altura da imagem (NOVO)
  );
  port (
    clk          : in  std_logic;
    reset_n      : in  std_logic;
    
    -- Entrada (vem da FIFO RX)
    s_axis_tdata : in  std_logic_vector(7 downto 0);
    s_axis_tvalid: in  std_logic;
    s_axis_tready: out std_logic;

    -- Saída (vai para FIFO TX)
    m_axis_tdata : out std_logic_vector(7 downto 0);
    m_axis_tvalid: out std_logic;
    m_axis_tready: in  std_logic
  );
end image_filter;

architecture rtl of image_filter is

  -- Total de pixels para saber quando parar
  constant TOTAL_PIXELS : integer := IMG_WIDTH * IMG_HEIGHT;
  
  -- Contador de pixels processados
  signal pixel_count : integer range 0 to TOTAL_PIXELS := 0;

  -- Definição dos Line Buffers
  type line_buffer_t is array (0 to IMG_WIDTH-1) of unsigned(7 downto 0);
  signal lb0, lb1 : line_buffer_t;
  
  signal wr_ptr : integer range 0 to IMG_WIDTH-1 := 0;

  -- Janela 3x3
  type window_row_t is array (0 to 2) of integer;
  type window_t is array (0 to 2) of window_row_t;
  signal win : window_t;

  -- Controle de Estado
  type state_t is (WAIT_HEADER_I, WAIT_HEADER_M, WAIT_HEADER_G, WAIT_HEADER_COLON, PASS_METADATA, PROCESS_IMG);
  signal state : state_t := WAIT_HEADER_I;
  signal meta_count : integer range 0 to 15 := 0;

  signal data_in_u : unsigned(7 downto 0);

begin

  s_axis_tready <= m_axis_tready; 
  data_in_u <= unsigned(s_axis_tdata);

  process(clk, reset_n)
    variable sum : integer;
  begin
    if reset_n = '0' then
      state <= WAIT_HEADER_I;
      wr_ptr <= 0;
      pixel_count <= 0;
      m_axis_tvalid <= '0';
      m_axis_tdata <= (others => '0');
      
    elsif rising_edge(clk) then
    
      m_axis_tvalid <= '0';

      -- Só processa se houver dado na entrada e espaço na saída
      if s_axis_tvalid = '1' and m_axis_tready = '1' then
        
        case state is
          ----------------------------------------------------------------
          -- 1. DETECÇÃO DE CABEÇALHO (IMG:)
          ----------------------------------------------------------------
          when WAIT_HEADER_I =>
            m_axis_tdata  <= s_axis_tdata;
            m_axis_tvalid <= '1';
            if s_axis_tdata = x"49" then state <= WAIT_HEADER_M; end if; -- 'I'

          when WAIT_HEADER_M =>
            m_axis_tdata  <= s_axis_tdata;
            m_axis_tvalid <= '1';
            if s_axis_tdata = x"4D" then state <= WAIT_HEADER_G; -- 'M'
            else state <= WAIT_HEADER_I; end if;

          when WAIT_HEADER_G =>
            m_axis_tdata  <= s_axis_tdata;
            m_axis_tvalid <= '1';
            if s_axis_tdata = x"47" then state <= WAIT_HEADER_COLON; -- 'G'
            else state <= WAIT_HEADER_I; end if;

          when WAIT_HEADER_COLON =>
            m_axis_tdata  <= s_axis_tdata;
            m_axis_tvalid <= '1';
            if s_axis_tdata = x"3A" then -- ':'
               state <= PASS_METADATA;
               meta_count <= 0;
            else state <= WAIT_HEADER_I; end if;

          ----------------------------------------------------------------
          -- 2. PASSAR METADADOS (8 bytes: Size, W, H)
          ----------------------------------------------------------------
          when PASS_METADATA =>
            m_axis_tdata  <= s_axis_tdata;
            m_axis_tvalid <= '1';
            
            if meta_count = 7 then
              state <= PROCESS_IMG;
              wr_ptr <= 0; 
              pixel_count <= 0; -- Reseta contador de pixels para a nova imagem
            else
              meta_count <= meta_count + 1;
            end if;

          ----------------------------------------------------------------
          -- 3. PROCESSAMENTO DE IMAGEM
          ----------------------------------------------------------------
          when PROCESS_IMG =>
            -- A. Atualiza Line Buffers e Janela
            lb1(wr_ptr) <= lb0(wr_ptr);
            lb0(wr_ptr) <= data_in_u;

            win(0)(0) <= win(0)(1); win(1)(0) <= win(1)(1); win(2)(0) <= win(2)(1);
            win(0)(1) <= win(0)(2); win(1)(1) <= win(1)(2); win(2)(1) <= win(2)(2);
            
            win(0)(2) <= to_integer(lb1(wr_ptr)); 
            win(1)(2) <= to_integer(lb0(wr_ptr));  
            win(2)(2) <= to_integer(data_in_u);    

            if wr_ptr = IMG_WIDTH-1 then
              wr_ptr <= 0;
            else
              wr_ptr <= wr_ptr + 1;
            end if;

            -- B. Filtro SHARPEN
            -- Kernel: Central * 5 - Vizinhos Cruz
            sum := (5 * win(1)(1)) - (win(0)(1) + win(2)(1) + win(1)(0) + win(1)(2));

            if sum > 255 then m_axis_tdata <= x"FF";
            elsif sum < 0 then m_axis_tdata <= x"00";
            else m_axis_tdata <= std_logic_vector(to_unsigned(sum, 8));
            end if;
            
            m_axis_tvalid <= '1';

            -- C. VERIFICAÇÃO DE FIM DE IMAGEM (A Correção!)
            if pixel_count = TOTAL_PIXELS - 1 then
                state <= WAIT_HEADER_I; -- Volta a esperar nova imagem
                pixel_count <= 0;
            else
                pixel_count <= pixel_count + 1;
            end if;

        end case;
      end if;
    end if;
  end process;
end rtl;