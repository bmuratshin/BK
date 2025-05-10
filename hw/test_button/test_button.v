module test_button (
     input wire key0,
     output wire led0,
     output wire led1
     );

assign led0 = key0;
assign led1 = !key0;

endmodule