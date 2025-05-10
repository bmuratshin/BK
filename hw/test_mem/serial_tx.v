module serial_tx(
  input wire clk115,
  input wire [7:0] sbyte,
  input wire sbyte_rdy,
  output wire tx,
  output wire end_of_send
);

reg [9:0] sreg;
assign tx = sreg[0];
reg [3:0] cnt = 0;
wire busy = (cnt != 0);

always @(posedge clk115)
begin
  if(sbyte_rdy & ~busy) begin
    sreg <= { 1'b1, sbyte, 1'b0 }; //load
    cnt <= 9;
  end else begin 
    sreg <= { 2'b11, sreg[9:1] }; //shift
    if (busy)
        cnt <= cnt - 1'b1;
  end
end

reg prev_busy;
always @(posedge clk115)
  prev_busy <= busy;
assign end_of_send = busy==1'b0 && prev_busy==1'b1;

endmodule