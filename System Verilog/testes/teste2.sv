module reais;

    // Possui 32 bits
    shortreal n0 = 10;
    // Possui 64 bits
    real n1 = 10;

    initial begin
        $display("Valor de n0: %f", n0);
        $display("Valor de n1: %f", n1);
    end
    
endmodule