module top_hdmi_pong (
    input dev_clk,      // Xtal 25MHz
    input n_rst,        // Botão Reset
    input n_btn,        // Botão Player
    // Saídas HDMI
    output HCK_P, HCK_N,
    output HD0_P, HD0_N,
    output HD1_P, HD1_N,
    output HD2_P, HD2_N,
    output led_D2       // Led piscante para debug
);

    // --- Geração de Clock (PLL) ---
    wire clk_pixel;    // 25 MHz
    wire clk_serial;   // 250 MHz (10x pixel clock para serializador SDR)
    wire clk_fb;       // Feedback interno
    wire locked;

    // Primitiva MMCME2_BASE para Artix-7
    // Entrada: 25MHz. VCO alvo: 1000MHz.
    // Pixel: 1000 / 40 = 25MHz. Serial: 1000 / 4 = 250MHz.
    MMCME2_BASE #(
        .BANDWIDTH("OPTIMIZED"),
        .CLKFBOUT_MULT_F(40.0),   // 25MHz * 40 = 1000MHz VCO
        .CLKIN1_PERIOD(40.0),     // 25MHz input
        .CLKOUT0_DIVIDE_F(40.0),  // 1000 / 40 = 25MHz (Pixel)
        .CLKOUT1_DIVIDE(4),       // 1000 / 4  = 250MHz (Serial)
        .DIVCLK_DIVIDE(1)
    ) clk_gen (
        .CLKOUT0(clk_pixel),
        .CLKOUT1(clk_serial),
        .CLKFBOUT(clk_fb),
        .LOCKED(locked),
        .CLKIN1(dev_clk),
        .PWRDWN(1'b0),
        .RST(~n_rst),
        .CLKFBIN(clk_fb)
    );

    // --- Sinais de Vídeo e Controle ---
    wire h_sync, v_sync;
    wire ctl_0, ctl_1, ctl_2, ctl_3;
    wire active_video, video_gb, data_island_gb;
    wire [9:0] sx, sy; // Coordenadas X, Y
    wire [7:0] red, green, blue;
    wire [9:0] tmds_ch0, tmds_ch1, tmds_ch2;

    // --- Instância de Timing (Modificada) ---
    timings_480p timing_inst (
        .pixel_clk(clk_pixel),
        .n_rst(locked), // Só libera reset quando clock estiver estável
        .h_sync(h_sync), .v_sync(v_sync),
        .ctl_0(ctl_0), .ctl_1(ctl_1), .ctl_2(ctl_2), .ctl_3(ctl_3),
        .active_video(active_video),
        .video_gb(video_gb),
        .data_island_gb(data_island_gb),
        .sx(sx), .sy(sy)
    );

    // --- Instância do Jogo (Substitui color_bars) ---
    pong_game game_inst (
        .pixel_clk(clk_pixel),
        .n_rst(locked),
        .active_video(active_video),
        .v_sync_pulse(v_sync), // Usa vsync para controlar velocidade
        .n_btn(n_btn),
        .sx(sx), .sy(sy),
        .red(red), .green(green), .blue(blue)
    );

    // --- Encoders TMDS (8b -> 10b) ---
    tmds_encoder #(.CHANNEL(0)) enc_blue (
        .pixel_clk(clk_pixel), .n_rst(locked),
        .active_video(active_video),
        .d_0(h_sync), .d_1(v_sync),
        .video_gb(video_gb), .data_island_gb(data_island_gb),
        .data_in(blue), .data_out(tmds_ch0)
    );

    tmds_encoder #(.CHANNEL(1)) enc_green (
        .pixel_clk(clk_pixel), .n_rst(locked),
        .active_video(active_video),
        .d_0(ctl_0), .d_1(ctl_1),
        .video_gb(video_gb), .data_island_gb(data_island_gb),
        .data_in(green), .data_out(tmds_ch1)
    );

    tmds_encoder #(.CHANNEL(2)) enc_red (
        .pixel_clk(clk_pixel), .n_rst(locked),
        .active_video(active_video),
        .d_0(ctl_2), .d_1(ctl_3),
        .video_gb(video_gb), .data_island_gb(data_island_gb),
        .data_in(red), .data_out(tmds_ch2)
    );

    // --- Serializadores e Buffers de Saída ---
    
    // Canal 0 (Blue + Syncs)
    tmds_serializer serializer_0 (
        .pixel_clk(clk_pixel), .bit_clk(clk_serial),
        .data_in(tmds_ch0), .q_out_n(HD0_N), .q_out_p(HD0_P)
    );
    
    // Canal 1 (Green)
    tmds_serializer serializer_1 (
        .pixel_clk(clk_pixel), .bit_clk(clk_serial),
        .data_in(tmds_ch1), .q_out_n(HD1_N), .q_out_p(HD1_P)
    );
    
    // Canal 2 (Red)
    tmds_serializer serializer_2 (
        .pixel_clk(clk_pixel), .bit_clk(clk_serial),
        .data_in(tmds_ch2), .q_out_n(HD2_N), .q_out_p(HD2_P)
    );
    
    // Canal Clock
    tmds_clock clock_driver (
        .pixel_clk(clk_pixel), .tmds_clk_n(HCK_N), .tmds_clk_p(HCK_P)
    );

    // --- LED Debug (apenas para saber se clock está rodando) ---
    blink blink_inst (
        .clk_in(clk_pixel),
        .n_rst(locked),
        .n_btn(n_btn),
        .led_out(led_D2)
    );

endmodule