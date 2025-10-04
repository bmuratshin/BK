`include "common.h"

module vluint7 ( 	
   input wire	clk,
   input wire reset,
   input wire	beg,
   
   input wire [`DECODER_MEM_ADDR_WIDTH-1:0]	addr,
   output logic [`DECODER_MEM_ADDR_WIDTH-1:0]	addr_out,
   output logic rd,
   output logic [`FIFO_ITEM_WIDTH-1:0]	data,
   
   // MEM
   output logic [`DECODER_MEM_ADDR_WIDTH-1:0] mem_addr,
   input wire  	[`DECODER_MEM_DATA_WIDTH-1:0] mem_data_in,
   output logic mem_we,
   input wire  	mem_wrd,
   output logic mem_beg
  );

  wire [`DECODER_MEM_DATA_WIDTH-1:0] 	tmp_data;
  assign tmp_data = mem_data_in;

  reg [`DECODER_MEM_ADDR_WIDTH-1:0]	loc_addr;
  assign mem_addr = loc_addr;

  reg working;
  reg [5:0] loc_shift;

  assign mem_we = 1'b0;

  always @ (posedge reset) begin
      @(posedge clk);

      mem_beg <= 0;     // read memory disabled
      data <= 0;        // 
      loc_shift <= 0;   // unpacking starts from low bits
      loc_addr <= 0; // 
      addr_out <= 0;
      rd <= 1;          // ready to work
      working <= 0;     // not busy
  end

  always @ (posedge beg) begin

      while (mem_wrd) begin
          @(posedge clk);
      end;

      mem_beg <= 1;     // let's read memory
      data <= 0;        // 
      loc_shift <= 0;   // unpacking starts from low bits
      loc_addr <= addr; // 
      addr_out <= addr;
      rd <= 0;          // result is not ready
      working <= 1;     // busy
      //$display("<<<<< begin vluint7 %d", addr);
  end
  
  always @ (posedge mem_wrd) begin
    //$display("data vluint7 shift=%d %d %x %d %x", loc_shift, loc_addr, tmp_data, tmp_data[7], tmp_data[6:0]);
    if (working) begin
      data <= data | (tmp_data[6:0] << loc_shift);
      loc_addr ++;
      if (tmp_data[7]) begin
        rd <= 0;
        loc_shift += 7;
        while (mem_wrd) begin
          @(posedge clk);
        end;
        mem_beg <= 1;
      end else begin
        rd <= 1;
        working <= 0;
        addr_out = loc_addr;
        mem_beg <= 0;
      end
    end
  end

  always @ (negedge clk) begin
      if (mem_beg) begin
        mem_beg <= 0;
      end
//      if (rd) begin
//        rd <= 0;
//      end
  end
  
endmodule
