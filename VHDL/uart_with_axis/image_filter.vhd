library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity image_filter is
  generic (
    IMG_WIDTH : integer := 150 
    -- IMG_HEIGHT removido daqui para evitar o erro de síntese anterior
    -- Definiremos a altura internamente como constante para simplificar
  );
  port (
    clk          : in  std_logic;
    reset_n      : in  std_logic;
    
    s_axis_tdata : in  std_logic_vector(7 downto 0);
    s_axis_tvalid: in  std_logic;
    s_axis_tready: out std_logic;

    m_axis_tdata : out std_logic_vector(7 downto 0);
    m_axis_tvalid: out std_logic;
    m_axis_tready: in  std_logic
  );
end image_filter;

architecture rtl of image_filter is

  -- ========================================================================
  -- CONFIGURAÇÃO DO TAMANHO DA IMAGEM
  -- ========================================================================
  constant IMG_H_CONST   : integer := 100; -- Defina a altura fixa aqui
  constant TOTAL_PIXELS  : integer := IMG_WIDTH * IMG_H_CONST;

  -- Buffers de Linha
  type line_buffer_t is array (0 to IMG_WIDTH-1) of unsigned(7 downto 0);
  signal lb0, lb1 : line_buffer_t;
  signal wr_ptr : integer range 0 to IMG_WIDTH-1 := 0;

  -- Janela 3x3
  type window_row_t is array (0 to 2) of integer;
  type window_t is array (0 to 2) of window_row_t;
  signal win : window_t;

  -- Armazenamento do Kernel
  type kernel_array_t is array (0 to 8) of signed(7 downto 0);
  signal kernel : kernel_array_t := (others => to_signed(0, 8));

  -- Controle de Estado
  type state_t is (WAIT_HEADER_I, WAIT_HEADER_M, WAIT_HEADER_G, WAIT_HEADER_COLON, PASS_METADATA, LOAD_KERNEL, PROCESS_IMG);
  signal state : state_t := WAIT_HEADER_I;
  signal counter : integer range 0 to 15 := 0;
  
  -- NOVO: Contador de Pixels para saber quando a imagem acabou
  signal pixel_count : integer range 0 to TOTAL_PIXELS := 0;

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
      m_axis_tvalid <= '0';
      m_axis_tdata <= (others => '0');
      kernel <= (others => to_signed(0, 8));
      pixel_count <= 0;
      
    elsif rising_edge(clk) then
    
      m_axis_tvalid <= '0';

      if s_axis_tvalid = '1' and m_axis_tready = '1' then
        
        case state is
          ----------------------------------------------------------------
          -- 1. DETECÇÃO DE CABEÇALHO "IMG:"
          ----------------------------------------------------------------
          when WAIT_HEADER_I =>
            pixel_count <= 0; -- Garante que o contador está zerado
            m_axis_tdata <= s_axis_tdata; m_axis_tvalid <= '1';
            if s_axis_tdata = x"49" then state <= WAIT_HEADER_M; end if; 

          when WAIT_HEADER_M =>
            m_axis_tdata <= s_axis_tdata; m_axis_tvalid <= '1';
            if s_axis_tdata = x"4D" then state <= WAIT_HEADER_G; 
            else state <= WAIT_HEADER_I; end if;

          when WAIT_HEADER_G =>
            m_axis_tdata <= s_axis_tdata; m_axis_tvalid <= '1';
            if s_axis_tdata = x"47" then state <= WAIT_HEADER_COLON; 
            else state <= WAIT_HEADER_I; end if;

          when WAIT_HEADER_COLON =>
            m_axis_tdata <= s_axis_tdata; m_axis_tvalid <= '1';
            if s_axis_tdata = x"3A" then 
               state <= PASS_METADATA;
               counter <= 0;
            else state <= WAIT_HEADER_I; end if;

          ----------------------------------------------------------------
          -- 2. METADADOS
          ----------------------------------------------------------------
          when PASS_METADATA =>
            m_axis_tdata <= s_axis_tdata; m_axis_tvalid <= '1';
            if counter = 7 then
              state <= LOAD_KERNEL;
              counter <= 0;
            else
              counter <= counter + 1;
            end if;

          ----------------------------------------------------------------
          -- 3. CARREGAR KERNEL
          ----------------------------------------------------------------
          when LOAD_KERNEL =>
            m_axis_tdata <= s_axis_tdata; m_axis_tvalid <= '1';
            kernel(counter) <= signed(s_axis_tdata);
            
            if counter = 8 then 
              state <= PROCESS_IMG;
              wr_ptr <= 0;
              pixel_count <= 0; -- Prepara contagem de pixels
            else
              counter <= counter + 1;
            end if;

          ----------------------------------------------------------------
          -- 4. PROCESSAMENTO
          ----------------------------------------------------------------
          when PROCESS_IMG =>
            
            -- Pipeline e Convolução (Mesma lógica anterior) ...
            lb1(wr_ptr) <= lb0(wr_ptr);
            lb0(wr_ptr) <= data_in_u;

            win(0)(0) <= win(0)(1); win(1)(0) <= win(1)(1); win(2)(0) <= win(2)(1);
            win(0)(1) <= win(0)(2); win(1)(1) <= win(1)(2); win(2)(1) <= win(2)(2);
            win(0)(2) <= to_integer(lb1(wr_ptr)); 
            win(1)(2) <= to_integer(lb0(wr_ptr)); 
            win(2)(2) <= to_integer(data_in_u);   

            if wr_ptr = IMG_WIDTH-1 then wr_ptr <= 0; else wr_ptr <= wr_ptr + 1; end if;

            -- Cálculo da Soma
            sum := 0;
            sum := sum + (win(0)(0) * to_integer(kernel(0)));
            sum := sum + (win(0)(1) * to_integer(kernel(1)));
            sum := sum + (win(0)(2) * to_integer(kernel(2)));
            sum := sum + (win(1)(0) * to_integer(kernel(3)));
            sum := sum + (win(1)(1) * to_integer(kernel(4)));
            sum := sum + (win(1)(2) * to_integer(kernel(5)));
            sum := sum + (win(2)(0) * to_integer(kernel(6)));
            sum := sum + (win(2)(1) * to_integer(kernel(7)));
            sum := sum + (win(2)(2) * to_integer(kernel(8)));

            if sum > 255 then m_axis_tdata <= x"FF";
            elsif sum < 0 then m_axis_tdata <= x"00";
            else m_axis_tdata <= std_logic_vector(to_unsigned(sum, 8));
            end if;
            
            m_axis_tvalid <= '1';

            -- === CORREÇÃO CRÍTICA AQUI ===
            -- Verifica se chegamos ao fim da imagem
            if pixel_count = TOTAL_PIXELS - 1 then
               state <= WAIT_HEADER_I; -- Volta a procurar o próximo cabeçalho
               pixel_count <= 0;
            else
               pixel_count <= pixel_count + 1;
            end if;

        end case;
      end if;
    end if;
  end process;
end rtl;