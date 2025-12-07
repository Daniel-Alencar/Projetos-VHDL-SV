module timings_480p (
    input pixel_clk, n_rst,
    output h_sync, v_sync, ctl_0, ctl_1, ctl_2, ctl_3,
    output active_video, video_gb, data_island_gb,
    // Novas saídas de coordenadas para o jogo
    output [$clog2(800)-1:0] sx,
    output [$clog2(525)-1:0] sy
);

// Parâmetros VGA 640x480@60Hz  
localparam H_SYNC=96, H_BP=40, H_LB=8, H_ADDR=640, H_RB=8, H_FP=8;
localparam V_SYNC=2, V_BP=25, V_TB=8, V_ADDR=480, V_BB=8, V_FP=2;
localparam H_TOTAL = H_SYNC + H_BP + H_LB + H_ADDR + H_RB + H_FP;
localparam V_TOTAL = V_SYNC + V_BP + V_TB + V_ADDR + V_BB + V_FP;

reg [$clog2(H_TOTAL)-1:0] h_cnt;
reg [$clog2(V_TOTAL)-1:0] v_cnt;

always @(posedge pixel_clk, negedge n_rst)
if (~n_rst) begin
    h_cnt <= 0;
    v_cnt <= 0;
end 
else begin
    if (h_cnt == H_TOTAL-1) begin
        h_cnt <= 0;
        v_cnt <= (v_cnt == V_TOTAL-1)? 0 : v_cnt + 1;
    end
    else
        h_cnt <= h_cnt + 1;
end

assign h_sync = (h_cnt < H_SYNC) ? 1'b0 : 1'b1;
assign v_sync = (v_cnt < V_SYNC) ? 1'b0 : 1'b1;

// Define a área ativa
assign active_video = (h_cnt >= (H_SYNC + H_BP + H_LB) && h_cnt < (H_SYNC + H_BP + H_LB + H_ADDR) &&
                       v_cnt >= (V_SYNC + V_BP + V_TB) && v_cnt < (V_SYNC + V_BP + V_TB + V_ADDR));

// Calcula coordenadas relativas à tela (0,0 no topo esquerdo da área ativa)
assign sx = active_video ? (h_cnt - (H_SYNC + H_BP + H_LB)) : 10'd0;
assign sy = active_video ? (v_cnt - (V_SYNC + V_BP + V_TB)) : 10'd0;

assign video_gb = (h_cnt >= (H_SYNC + H_BP + H_LB - 2) && h_cnt < (H_SYNC + H_BP + H_LB));
assign data_island_gb = 1'b0;
assign ctl_0 = (h_cnt >= (H_SYNC + H_BP + H_LB - 10) && h_cnt < H_SYNC + H_BP + H_LB - 2);
assign ctl_1 = 1'b0;
assign ctl_2 = 1'b0;
assign ctl_3 = 1'b0;

endmodule