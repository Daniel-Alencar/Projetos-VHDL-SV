module inteiros;

    bit n0 = 1;

    // Pode assumir valores negativos (complemento de 2)

    byte n1 = -4;
    byte n2 = 225;
    byte n3 = "j";
    // É composto de 2 bytes
    shortint n4 = -42;
    // É composto de 2 shortint
    int n5 = -42;
    // É composto de 2 int
    longint n6 = -42;

    // Pode assumir os valores 0, 1, x e z
    // Ela não possui valores negativos
    reg n7;

    // Do jeito que está, não tem bits suficientes para representar o 10
    reg [2:0] n8 = 10;

    // Podemos sinalizar e dessinalizar variáveis com:
    // 'signed' e 'unsigned'

    // É a mesma coisa do reg, só que mais usado para system verilog
    // '0' — nível lógico baixo

    // '1' — nível lógico alto

    // 'x' — valor indefinido

    // 'z' — alta impedância
    logic n9;

    // Não sinalizada, é um int de 64 bits
    time n10 = 9999;

    integer n11 = 11;

    initial begin
        $display("Valor de n0: %b", n0);
        $display("Valor de n1: %d", n1);
        $display("Valor de n2: %c", n2);
        $display("Valor de n3: %s", n3);
        $display("Valor de n3: %b", n3);
        $display("Valor de n3: %c", n3);
        $display("Valor de n3: %d", n3);
        $display("Valor de n3: %d", n3);
        $display("Valor de n3: %d", n3);
        $display("Valor de n4: %b", n4);
        $display("Valor de n5: %b", n5);
        $display("Valor de n6: %b", n6);
        $display("Valor de n7: %b", n7);
        $display("Valor de n8: %b", n8);
        $display("Valor de n9: %b", n9);
        $display("Valor de n10: %d", n10);
    end
    
endmodule