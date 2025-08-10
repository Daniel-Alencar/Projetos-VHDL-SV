module pinout_test (
    input clk_in,
    output [9:0] led,
    output led_D2
);
    // Mesma coisa que 10'b0000000001
    reg [9:0] led_reg = 1;
    
    always @(posedge clk_in) begin
        led_reg <= (led_reg << 1) | (led_reg >> 9);
    end

    assign led = led_reg;
    assign led_D2 = ~clk_in;
endmodule
