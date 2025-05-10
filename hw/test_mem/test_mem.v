module test_mem (
	input wire	CLK100MHZ,
	input wire	KEY0,
	output wire	[2:0]LED,

	//FTDI serial port signals
	input wire  FTDI_BD0,	//from FTDI, RxD
	output wire FTDI_BD1,	//to FTDI, TxD
	input wire  FTDI_BD2, 	//from FTDI, RTS
	output wire FTDI_BD3 	//to FTDI, CTS
);


wire clk115Khz;
my_pll my_pll_instance(
	.inclk0( CLK100MHZ ),
	.c0( clk115Khz ),
	.locked()
	);

//catch board key press
reg [1:0]prev_key_state;
always @( posedge clk115Khz )
	prev_key_state <= { prev_key_state[0], KEY0 };

reg key_press_event;
always @( posedge clk115Khz )
	key_press_event <= (prev_key_state== 2'b10);
	
reg [2:0]key_press_counter;
always @( posedge clk115Khz )
	if( key_press_event )
		key_press_counter <= key_press_counter + 1;

assign LED = key_press_counter;
//---------------------------------------------------------------
//wire [7:0]out_char;
//wire write_enabled = 0;
//my_mem my_mem_test (
//	.clock( clk115Khz ),
//	.dataout( out_char ),
//	.ram_wren( write_enabled ));
//----------------------------------------------------------------------------
reg [7:0] rd_char;
//wire [7:0] wr_char = 8'h2B;
reg  [7:0] addr2 = 0;
//wire write_enabled = 0;
my_rom my_mem2_test (
	.address( addr2 ),
	.clock( clk115Khz ),
//	.data( wr_char ),
//	.wren( write_enabled ),
	.q ( rd_char ));

//----------------------------------------------------------------------------
//reg [8*15-1:0] message = "*\n\r!dlroW olleH";
wire end_of_send;
wire send;
//reg [15:0]message_bit_index;
wire [7:0]send_char;
assign send_char = rd_char;//message >> message_bit_index;

//use instance of serial port transmitter
serial_tx serial_tx_instance(
  .clk115( clk115Khz ),
  .sbyte( send_char ),
  .sbyte_rdy( send ),
  .tx( FTDI_BD1 ),
  .end_of_send( end_of_send ),
  .ack()
);

localparam STATE_WAIT_KEY_PRESS = 0;
localparam STATE_SEND_CHAR = 1;
localparam STATE_WAIT_CHAR_SENT = 2;

reg [1:0]state = STATE_WAIT_KEY_PRESS;

always @( posedge clk115Khz )
begin
	case( state )
	STATE_WAIT_KEY_PRESS:
		begin
			if( key_press_event ) state <= STATE_SEND_CHAR;
		end
	STATE_SEND_CHAR:
		begin
			state <= STATE_WAIT_CHAR_SENT;
		end
	STATE_WAIT_CHAR_SENT:
		begin
			if( end_of_send ) 
				state <= ((send_char==8'h2A) ? STATE_WAIT_KEY_PRESS : STATE_SEND_CHAR);
		end
	endcase
end

assign send = (state == STATE_SEND_CHAR);

always @( posedge clk115Khz )
	if( state==STATE_WAIT_KEY_PRESS )
		addr2 <= 0;
	else
	if( state==STATE_SEND_CHAR )
		addr2 <= addr2 + 1;

endmodule


