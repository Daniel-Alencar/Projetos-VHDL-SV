`timescale 1ns / 1ps

module blink (
    input clk,
    output led_out
);  
    // O oscilador de clock possui 25000000 Hz
    // A cada meio segundo iremos mudar o estado do led
    localparam DIV = 12500000 - 1;
    
    reg [$clog2(DIV)-1:0] clk_cnt = 0;
    reg led_reg = 1'b0;

    always_ff @( posedge clk ) begin
        if(clk_cnt == DIV) begin
            clk_cnt <= 0; 
            led_reg <= ~led_reg;
        end
        else begin
            clk_cnt <= clk_cnt + 1;
        end
    end

    assign led_out = led_reg;
endmodule