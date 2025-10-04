`include "common.h"

module decoder #( name  = "hz")
( 
   input wire reset,
   input wire	clk,

   input wire	do_it,
   input wire [`DECODER_MEM_ADDR_WIDTH-1:0]	addr,

   output logic [`DECODER_MEM_ADDR_WIDTH-1:0]	addr_out,
   output logic done,
   output logic stop,
   
   // FIFO
   input wire	fifo_wr_done,
   output logic fifo_wr,
   output logic [`FIFO_ITEM_WIDTH-1:0] fifo_data,
   
   // MEM(VLUINT)
   output logic [`DECODER_MEM_ADDR_WIDTH-1:0] mem_addr,
   input wire  	[`DECODER_MEM_DATA_WIDTH-1:0] mem_data_in,
   output logic mem_we,
   input wire  	mem_wrd,
   output logic mem_beg
  
  );

                    
//---------------------------------------------------                        
  reg [`DECODER_MEM_ADDR_WIDTH-1:0]	addr_tmp;
  reg [`FIFO_ITEM_WIDTH-1:0]    last_instr;
  reg [`FIFO_ITEM_WIDTH-1:0]    instr_data;
  wire ready2;
  reg beg2;
  
  vluint7 v0 ( 	
    	.clk(clk),
     .reset(reset),
     .addr(addr_tmp),
     .addr_out(addr_out),
     .data(instr_data),
   		.rd(ready2),
   		.beg(beg2),
   		
   		.mem_addr(mem_addr),
   		.mem_data_in(mem_data_in),
   		.mem_we(mem_we),
   		.mem_wrd(mem_wrd),
   		.mem_beg(mem_beg)
  );
//---------------------------------------------------                        

  assign fifo_data[`INSTR_WIDTH-1:0] = instr_data;
  assign fifo_data[`FIFO_ITEM_WIDTH-1:`INSTR_WIDTH] = addr_out;
         
  always @ (posedge reset) begin
    stop <= 1;
    addr_tmp <= 0;
    beg2 <= 0;
    last_instr <= 0;
    while (!ready2) begin
        @(posedge clk);
    end;
    done <= 1;
  end;
                        
  always @ (posedge ready2)begin
    if (!done && !stop) begin
      $display("[%0t] decoder(%s) instr %d addr %d fifo=%x beg2=%d", $time, name, instr_data, addr_out, fifo_data, beg2);

      if (instr_data == 0 && last_instr == 0) begin
          done <= 1;
          stop <= 1;
          $display("[%0t] decoder(%s) stop", $time, name);
      end else begin
        addr_tmp <= addr_out;
        fifo_wr <= 1;
        beg2 <= 1;
        last_instr <= instr_data;

        // Wait until there is space in fifo
        while (!fifo_wr_done && !stop) begin
     	  @(posedge clk);
        end;
      end;
    end;
  end


  always @ (posedge do_it)begin
    addr_tmp <= addr;
    done <= 0;
    stop <= 0;
    last_instr <= 0;
    beg2 <= 1;
  end

  always @ (negedge clk)begin
    fifo_wr <= 0;
    beg2 <= 0;
  end

endmodule