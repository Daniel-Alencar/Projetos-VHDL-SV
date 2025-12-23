library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity image_filter is
  generic (
    IMG_WIDTH : integer := 150 -- Largura da imagem
  );
  port (
    clk          : in  std_logic;
    reset_n      : in  std_logic;
    
    -- 1 byte de pixel entrando
    s_axis_tdata : in  std_logic_vector(7 downto 0);
    -- "tenho dado válido para você"
    s_axis_tvalid: in  std_logic;
    -- "estou pronto para receber"
    s_axis_tready: out std_logic;

    -- "1 byte de pixel saindo"
    m_axis_tdata : out std_logic_vector(7 downto 0);
    -- "Tenho dado válido processado"
    m_axis_tvalid: out std_logic;
    -- "O próximo bloco pode receber?"
    m_axis_tready: in  std_logic
  );
end image_filter;

architecture rtl of image_filter is

  -- ========================================================================
  -- CONFIGURAÇÃO DO TAMANHO DA IMAGEM
  -- ========================================================================
  -- Definição da altura e total de pixels para saber quando parar
  constant IMG_H_CONST   : integer := 100;
  constant TOTAL_PIXELS  : integer := IMG_WIDTH * IMG_H_CONST;

  -- LINE BUFFERS (Memória de Linha)
  -- Cria um array do tamanho de UMA linha da imagem.
  -- Usamos 'unsigned' porque pixels são 0-255 (sempre positivos).
  type line_buffer_t is array (0 to IMG_WIDTH-1) of unsigned(7 downto 0);

  -- lb0: Linha imediatamente anterior à atual
  -- lb1: Linha antes da anterior
  signal lb0, lb1 : line_buffer_t;

  -- Ponteiro de escrita: Diz em qual coluna (X) estamos escrevendo no buffer
  signal wr_ptr : integer range 0 to IMG_WIDTH-1 := 0;

  -- JANELA 3x3 (Window)
  -- Uma matriz 3x3 de inteiros para acesso rápido aos vizinhos
  type window_row_t is array (0 to 2) of integer;
  type window_t is array (0 to 2) of window_row_t;
  signal win : window_t;

  -- KERNEL (Os pesos do filtro)
  -- Aqui usamos 'SIGNED' (com sinal) pois filtros como Edge Detection usam negativos (-1)
  type kernel_array_t is array (0 to 8) of signed(7 downto 0);
  signal kernel : kernel_array_t := (others => to_signed(0, 8));

  -- MÁQUINA DE ESTADOS
  -- Define os passos lógicos do processamento
  type state_t is (WAIT_HEADER_I, WAIT_HEADER_M, WAIT_HEADER_G, WAIT_HEADER_COLON, PASS_METADATA, LOAD_KERNEL, PROCESS_IMG);
  signal state : state_t := WAIT_HEADER_I;

  -- Contadores auxiliares
  -- Para contar bytes do header/kernel
  signal counter : integer range 0 to 15 := 0;
  -- Contador de Pixels para saber quando a imagem acabou
  signal pixel_count : integer range 0 to TOTAL_PIXELS := 0;

  -- Sinal auxiliar para converter entrada std_logic_vector -> unsigned
  signal data_in_u : unsigned(7 downto 0);

begin

  -- Conexão direta do controle de fluxo: Se a saída trava, a entrada trava.
  s_axis_tready <= m_axis_tready;
  data_in_u <= unsigned(s_axis_tdata);

  process(clk, reset_n)
    -- Variável temporária para a soma da convolução
    variable sum : integer;
  begin
    -- RESET: Zera tudo se apertar o botão de reset ou ligar a placa
    if reset_n = '0' then
      state <= WAIT_HEADER_I;
      wr_ptr <= 0;
      m_axis_tvalid <= '0';
      m_axis_tdata <= (others => '0');
      kernel <= (others => to_signed(0, 8));
      pixel_count <= 0;
      
    elsif rising_edge(clk) then

      -- Por padrão, não enviamos nada (exceto se definido abaixo)
      m_axis_tvalid <= '0';

      -- Só processamos se tiver dado chegando (valid) E se pudermos enviar (ready)
      if s_axis_tvalid = '1' and m_axis_tready = '1' then
        
        case state is
          ----------------------------------------------------------------
          -- DETECÇÃO DE CABEÇALHO "IMG:"
          -- Serve para alinhar o início da transmissão
          ----------------------------------------------------------------
          when WAIT_HEADER_I =>
            pixel_count <= 0; -- Garante contador zerado
            -- Ecoa o dado de volta para a serial do PC
            m_axis_tdata <= s_axis_tdata; m_axis_tvalid <= '1';
            -- Se recebeu 'I' (0x49), avança
            if s_axis_tdata = x"49" then state <= WAIT_HEADER_M; end if; 

          when WAIT_HEADER_M =>
            -- Ecoa o dado de volta para a serial do PC
            m_axis_tdata <= s_axis_tdata; m_axis_tvalid <= '1';

            -- Se recebeu 'M' (0x4D), avança
            if s_axis_tdata = x"4D" then state <= WAIT_HEADER_G; 
            else state <= WAIT_HEADER_I; end if;

          when WAIT_HEADER_G =>
            -- Ecoa o dado de volta para a serial do PC
            m_axis_tdata <= s_axis_tdata; m_axis_tvalid <= '1';

            -- Se recebeu 'G' (0x47), avança
            if s_axis_tdata = x"47" then state <= WAIT_HEADER_COLON; 
            else state <= WAIT_HEADER_I; end if;

          when WAIT_HEADER_COLON =>
            -- Ecoa o dado de volta para a serial do PC
            m_axis_tdata <= s_axis_tdata; m_axis_tvalid <= '1';

            -- Se recebeu ':' (0x3A), avança
            if s_axis_tdata = x"3A" then 
               state <= PASS_METADATA;
               counter <= 0;
            else state <= WAIT_HEADER_I; end if;

          ----------------------------------------------------------------
          -- PULAR METADADOS (8 bytes: Size, W, H)
          ----------------------------------------------------------------
          when PASS_METADATA =>
            -- Ecoa o dado de volta para a serial do PC
            m_axis_tdata <= s_axis_tdata; m_axis_tvalid <= '1';
            if counter = 7 then
              state <= LOAD_KERNEL;
              counter <= 0;
            else
              counter <= counter + 1;
            end if;

          ----------------------------------------------------------------
          -- CARREGAR KERNEL (9 bytes)
          ----------------------------------------------------------------
          when LOAD_KERNEL =>
            -- Ecoa o dado de volta para a serial do PC
            m_axis_tdata <= s_axis_tdata; m_axis_tvalid <= '1';

            -- O dado que chega via UART é salvo na memória interna 'kernel'
            kernel(counter) <= signed(s_axis_tdata);
            
            if counter = 8 then -- Contou 9 bytes (0 a 8) do kernel
              state <= PROCESS_IMG; -- Agora vamos para o processamento da imagem
              wr_ptr <= 0;
              pixel_count <= 0;
            else
              counter <= counter + 1;
            end if;

          ----------------------------------------------------------------
          -- 4. PROCESSAMENTO
          ----------------------------------------------------------------
          when PROCESS_IMG =>
            
            -- A. ATUALIZAÇÃO DOS BUFFERS DE LINHA (Pipeline)
            -- Imagine uma esteira rolante vertical.
            lb1(wr_ptr) <= lb0(wr_ptr); -- A linha velha vira a linha muito velha
            lb0(wr_ptr) <= data_in_u; -- A linha atual recebe o novo pixel

            -- B. JANELA DESLIZANTE (Shift Registers)
            -- Imagine uma esteira rolante horizontal (da direita pra esquerda)

            -- Coluna 0 (Esquerda) recebe o que estava na Coluna 1
            win(0)(0) <= win(0)(1); win(1)(0) <= win(1)(1); win(2)(0) <= win(2)(1);
            -- Coluna 1 (Centro) recebe o que estava na Coluna 2
            win(0)(1) <= win(0)(2); win(1)(1) <= win(1)(2); win(2)(1) <= win(2)(2);
            -- Coluna 2 (Direita/Nova) é alimentada pelos Buffers e Entrada
            win(0)(2) <= to_integer(lb1(wr_ptr)); -- Pixel de CIMA (Linha -2)
            win(1)(2) <= to_integer(lb0(wr_ptr)); -- Pixel do MEIO (Linha -1)
            win(2)(2) <= to_integer(data_in_u);   -- Pixel de BAIXO (Linha atual)

            -- Avança o ponteiro horizontal da linha
            if wr_ptr = IMG_WIDTH-1 then 
              wr_ptr <= 0; 
            else 
              wr_ptr <= wr_ptr + 1; 
            end if;

            -- C. CÁLCULO DA CONVOLUÇÃO (MAC - Multiply Accumulate)
            sum := 0;
            -- Multiplica cada posição da janela pelo peso correspondente do kernel carregado
            sum := sum + (win(0)(0) * to_integer(kernel(0)));
            sum := sum + (win(0)(1) * to_integer(kernel(1)));
            sum := sum + (win(0)(2) * to_integer(kernel(2)));
            sum := sum + (win(1)(0) * to_integer(kernel(3)));
            sum := sum + (win(1)(1) * to_integer(kernel(4)));
            sum := sum + (win(1)(2) * to_integer(kernel(5)));
            sum := sum + (win(2)(0) * to_integer(kernel(6)));
            sum := sum + (win(2)(1) * to_integer(kernel(7)));
            sum := sum + (win(2)(2) * to_integer(kernel(8)));

            -- D. SATURAÇÃO (Clamping)
            -- O resultado matemático pode ser -500 ou +1200,
            -- mas o pixel só vai de 0 a 255.
            if sum > 255 then 
              m_axis_tdata <= x"FF";
            elsif sum < 0 then 
              m_axis_tdata <= x"00";
            else 
              m_axis_tdata <= std_logic_vector(to_unsigned(sum, 8));
            end if;
            
            -- Diz para a saída: "O resultado está pronto!"
            m_axis_tvalid <= '1';

            -- E. CONDIÇÃO DE PARADA (Correção do Bug)
            if pixel_count = TOTAL_PIXELS - 1 then
              -- Acabou a imagem? Volte a esperar o 'I' de 'IMG:'
               state <= WAIT_HEADER_I;
               pixel_count <= 0;
            else
               pixel_count <= pixel_count + 1;
            end if;

        end case;
      end if;
    end if;
  end process;
end rtl;