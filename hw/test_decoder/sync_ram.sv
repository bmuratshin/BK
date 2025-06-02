`include "common.h"

module single_port_sync_ram
  ( 	input wire	clk,
     input wire reset,
     
   		input wire [`MEM_ADDR_WIDTH-1:0]	addr,
   		inout wire [`MEM_DATA_WIDTH-1:0]	data,
   		input wire			  we,
   		input wire   		oe,
   		input wire   		beg,
   		output logic   rd
  );

  reg [`MEM_DATA_WIDTH-1:0] 	tmp_data;
  reg [`MEM_DATA_WIDTH-1:0] 	mem [`MEM_DEPTH];

  initial begin
    $display("Loading rom.");
    $readmemh("rom_image.mem", mem);
  end
    

  always @ (posedge beg)begin
      rd <= 0;
  end

  always @ (posedge clk) begin

    if (reset) begin    
      rd <= 0;
    end else 
    begin
      //$display("mem %d %d", we, oe, addr);
      if (we) begin
        mem[addr] <= data;
      end else begin
    	   tmp_data <= mem[addr];
      end
      rd <= 1;
    end
  
  end  // always

  assign data = oe & !we ? tmp_data : 'hz;
endmodule
