module test_timer (
	input wire	CLK100MHZ,
	input wire	KEY0,
	output wire	[2:0]LED	
);

wire clk128Mhz;
my_pll my_pll_instance(
	.inclk0( CLK100MHZ ),
	.c0( clk128Mhz ),
	.locked()
	);
reg [31:0]counter128;
always @(posedge clk128Mhz)
	if( KEY0 )
		counter128 <= counter128+1;
assign LED[1] = counter128[27];
	
reg [31:0]counter;
always @(posedge CLK100MHZ)
	if( KEY0 )
		counter <= counter+1;

assign LED[0] = counter[27];

endmodule
