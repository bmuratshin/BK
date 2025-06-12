`include "common.h"

module single_port_sync_ram
#(  init_from_file=1,
    file_data="rom_image.mem",
    addr_width=`DECODER_MEM_ADDR_WIDTH,
    data_width=`DECODER_MEM_DATA_WIDTH,
    mem_depth=`DECODER_MEM_DATA_DEPTH
) ( 	input wire	clk,
     input wire reset,
     
   		input wire [addr_width-1:0]	addr,
   		input wire [data_width-1:0]	data_in,
   		output reg [data_width-1:0]	data_out,
   		input wire			  we,
   		input wire   		oe,
   		input wire   		beg,
   		output logic   rd
  );

  //reg [data_width-1:0] 	tmp_data;
  reg [data_width-1:0] 	mem [mem_depth];

//  assign data_out = tmp_data;

  initial begin
    if (init_from_file) begin
      $display("Loading rom.");
      $readmemh(file_data, mem);
    end;
  end
    

  always @ (posedge beg)begin
      rd <= 0;
  end

  always @ (posedge clk) begin

    if (reset) begin    
      rd <= 0;
    end else 
    begin
      $display("mem %d %d %d", we, oe, addr);
      if (we) begin
        mem[addr] <= data_in;
      end else begin
    	   data_out <= mem[addr];
      end
      rd <= 1;
    end
  
  end  // always

endmodule
