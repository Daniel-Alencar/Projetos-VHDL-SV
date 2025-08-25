module iobuf (
    input data_in,
    inout line,
    output line_monit
);

assign line = data_in ? 1'bZ : 1'b0;
assign line_monit = line;

endmodule
