`include "common.h"

module decoder ( 	
   input wire reset,
   input wire	clk,

   input wire	do_it,
   input wire [`DECODER_MEM_ADDR_WIDTH-1:0]	addr,

   output logic [`DECODER_MEM_ADDR_WIDTH-1:0]	addr_out,
   output logic done,
   output logic stop,
   
   // FIFO
   input wire	fifo_full,
   output logic fifo_wr,
   output logic [`INSTR_WIDTH-1:0] fifo_data
  );

                    
//---------------------------------------------------                        
  reg [`DECODER_MEM_ADDR_WIDTH-1:0]	addr_tmp;
  reg [`INSTR_WIDTH-1:0]    last_instr;
  reg [`INSTR_WIDTH-1:0]    instr_data;
  reg ready2;
  reg beg2;
  
  
  vluint7 v0 ( 	
    	.clk(clk),
     .reset(reset),
     .addr(addr_tmp),
     .addr_out(addr_out),
     .data(instr_data),
   		.rd(ready2),
   		.beg(beg2)
  );
//---------------------------------------------------                        
         
  always @ (posedge reset) begin
    done <= 0;
    stop <= 0;
  end;
                        
  always @ (posedge ready2)begin
    if (!done && !stop) begin
      //$display("[%0t] instr %d addr %d", $time, instr_data, addr_out);
      beg2 <= 0; 
      addr_tmp <= addr_out;
    
      // Wait until there is space in fifo
      while (fifo_full) begin
   	  @(posedge clk);
         $display("[%0t] FIFO is full, wait for reads to happen", $time);
      end;

      // Drive new values into FIFO
      fifo_wr <= 1'b1;
      fifo_data	<= instr_data;
    
      @(posedge clk);
    
      if (instr_data > 0 || last_instr > 0) begin
        beg2 <= 1'b1;
        fifo_wr <= 1'b0;
      end else begin
        done <= 1'b1;
        fifo_wr <= 1'b0;
        stop <= 1'b1;
      end;
      last_instr <= instr_data;
    end
  end


  always @ (posedge do_it)begin
    addr_tmp <= addr;
    done <= 0;
    beg2 <= 1;
    last_instr <= 0;
  end
endmodule