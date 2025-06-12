`include "common.h"

module tb;

  reg 			reset;
  reg 	 	clk;
  reg 			do_it;
  reg [`DECODER_MEM_ADDR_WIDTH-1:0] addr;
  reg [`DECODER_MEM_ADDR_WIDTH-1:0] addr_out;
  reg    stop_exec;
  wire   stop_dec;
  wire   done_dec;
   // FIFO
  wire	fifo_full;
  wire fifo_wr;
  reg [`INSTR_WIDTH-1:0] fifo_data;
  
  decoder u_decoder ( 	
   .reset(reset),
   .clk(clk),
   .do_it(do_it),
   .addr(addr),
   .addr_out(addr_out),
   .stop(stop_dec),
   .done(done_dec),
   .fifo_full(fifo_full),
   .fifo_wr(fifo_wr),
   .fifo_data(fifo_data)
  );  
  
  reg [15:0]   din;
  reg [15:0] 	dout;
  reg 			empty;
  reg 			rd_en;
  reg 			wr_en;
  wire 			full;

  sync_fifo #(.DWIDTH(`INSTR_WIDTH)) u_sync_fifo 
	                (.reset(reset),
                         .wr_en(wr_en),
                         .rd_en(rd_en),
                         .clk(clk),
                         .din(din),
                         .dout(dout),
                         .empty(empty),
                         .full(full)
                        );
  assign wr_en = fifo_wr;
  assign fifo_full = full;
  assign din = fifo_data;
  
  reg 			exec_it;
  wire   exec_done;
  reg    fifo_rd;

  executer stream_exec(
   .reset(reset),
   .clk(clk),

   .do_it(exec_it),
   .done(exec_done),
   .stop(stop_exec),
   
   // FIFO
   .fifo_empty(empty),
   .fifo_rd(fifo_rd),
   .fifo_data(dout)
  );
  assign rd_en = fifo_rd;
  
  always #10 clk <= ~clk;

  initial begin
    clk 	<= 0;
    reset 	<= 1;

    #20 reset <= 0;
  end
  
  // writing FIFO
  initial begin
    #20 @(posedge clk);

    addr <= 0;
    do_it <= 1;
  end

  always @ (posedge done_dec)begin
//    $display("[%0t] addr %d", $time, addr_out);
    do_it <= 0; 
    addr <= addr_out;   
    
    @(posedge clk);
    if (!stop_exec)
      do_it <= 1; 
  end

  // reading FIFO
  initial begin
    #20 @(posedge clk);

    exec_it <= 1;
      // Sample new values from FIFO at random pace
      @(posedge clk);
      //rdata <= dout;
  //    $display("[%0t] clk rd_en=%0d rdata=0x%0h ", $time, rd_en, dout);

  end



endmodule