module conversao;

    real n0 = 90.125;
    bit [63:0] n1; 
    integer n1;
    real n2;

    initial begin
        $display("Valor de n0: %f", n0);
        n1 = $realtobits(n0);
        $display("Valor de n1: %f", r);
        i = $rtoi(r);
        $display("Valor de n2: %f", r);
        nr = $itor(i);
        $display("Valor de n3: %f", r);
        nb = $realtobits(nr);
        $display("Valor de n4: %f", r);
    end
    
endmodule