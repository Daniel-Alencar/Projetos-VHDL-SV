module pong_game (
    input pixel_clk, n_rst,
    input active_video, v_sync_pulse, // v_sync_pulse usado para atualizar física 60x por seg
    input n_btn,                      // Botão do jogador
    input [9:0] sx, sy,               // Coordenadas da tela
    output [7:0] red, green, blue
);

    // --- Parâmetros do Jogo ---
    localparam SCREEN_W = 640;
    localparam SCREEN_H = 480;
    localparam PADDLE_X = 20;     // Posição X da raquete
    localparam PADDLE_W = 10;     // Largura da raquete
    localparam PADDLE_H = 80;     // Altura da raquete
    localparam BALL_SIZE = 10;    // Tamanho da bola
    localparam PADDLE_SPEED = 6;  // Pixels por frame
    localparam BALL_SPEED = 5;    // Pixels por frame

    // --- Estado do Jogo ---
    reg [9:0] paddle_y;
    reg [9:0] ball_x, ball_y;
    reg [9:0] ball_dx, ball_dy; // Direção: 0 (negativo/esq/cima) ou 1 (positivo/dir/baixo)
    reg ball_dir_x, ball_dir_y; 
    
    // Detecção de bordas dos objetos
    wire paddle_on = (sx >= PADDLE_X && sx < PADDLE_X + PADDLE_W) &&
                     (sy >= paddle_y && sy < paddle_y + PADDLE_H);
                     
    wire ball_on = (sx >= ball_x && sx < ball_x + BALL_SIZE) &&
                   (sy >= ball_y && sy < ball_y + BALL_SIZE);

    // --- Lógica de Atualização (roda 1x por frame no V_SYNC) ---
    // Detecta borda de subida do vsync para atualizar a física apenas uma vez por quadro
    reg prev_vsync;
    wire frame_tick = v_sync_pulse & ~prev_vsync;
    
    always @(posedge pixel_clk or negedge n_rst) begin
        if (!n_rst) begin
            prev_vsync <= 0;
            paddle_y <= (SCREEN_H - PADDLE_H) / 2;
            ball_x <= SCREEN_W / 2;
            ball_y <= SCREEN_H / 2;
            ball_dir_x <= 1; // Começa indo para direita
            ball_dir_y <= 1; // Começa indo para baixo
        end else begin
            prev_vsync <= v_sync_pulse;

            if (frame_tick) begin
                // 1. Movimento da Raquete (Botão pressionado = 0 = CIMA)
                if (!n_btn) begin 
                    if (paddle_y >= PADDLE_SPEED) 
                        paddle_y <= paddle_y - PADDLE_SPEED;
                    else 
                        paddle_y <= 0;
                end else begin
                    if (paddle_y + PADDLE_H + PADDLE_SPEED < SCREEN_H)
                        paddle_y <= paddle_y + PADDLE_SPEED;
                    else
                        paddle_y <= SCREEN_H - PADDLE_H;
                end

                // 2. Movimento da Bola Horizontal
                if (ball_dir_x == 1) begin // Indo para direita
                    if (ball_x + BALL_SIZE + BALL_SPEED >= SCREEN_W) begin
                        ball_dir_x <= 0; // Bateu na parede direita, volta
                    end else begin
                        ball_x <= ball_x + BALL_SPEED;
                    end
                end else begin // Indo para esquerda
                    // Verifica colisão com raquete ou parede esquerda (Game Over/Reset)
                    if (ball_x <= PADDLE_X + PADDLE_W + BALL_SPEED && 
                        ball_x + BALL_SIZE >= PADDLE_X &&
                        ball_y + BALL_SIZE >= paddle_y && 
                        ball_y <= paddle_y + PADDLE_H) begin
                        
                        ball_dir_x <= 1; // Bateu na raquete
                    end else if (ball_x <= BALL_SPEED) begin
                        // Errou a raquete (Reset simples para o centro)
                        ball_x <= SCREEN_W / 2;
                        ball_y <= SCREEN_H / 2;
                        ball_dir_x <= 1;
                    end else begin
                        ball_x <= ball_x - BALL_SPEED;
                    end
                end

                // 3. Movimento da Bola Vertical
                if (ball_dir_y == 1) begin // Descendo
                    if (ball_y + BALL_SIZE + BALL_SPEED >= SCREEN_H) begin
                        ball_dir_y <= 0; // Bateu no chão
                    end else begin
                        ball_y <= ball_y + BALL_SPEED;
                    end
                end else begin // Subindo
                    if (ball_y <= BALL_SPEED) begin
                        ball_dir_y <= 1; // Bateu no teto
                    end else begin
                        ball_y <= ball_y - BALL_SPEED;
                    end
                end
            end
        end
    end

    // --- Desenho (Saída de Cor) ---
    assign red   = (active_video && (paddle_on || ball_on)) ? 8'hFF : 8'h00;
    assign green = (active_video && (paddle_on || ball_on)) ? 8'hFF : 8'h00;
    assign blue  = (active_video && (paddle_on || ball_on)) ? 8'hFF : 8'h00;

endmodule