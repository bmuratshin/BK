`include "common.h"

module module_cf (
   input wire reset,
   input wire	clk,

   input wire	do_it,
   output logic done,
   output logic stop,
   
   input wire  	[`DECODER_MEM_ADDR_WIDTH-1:0] start_addr,
   
   // MEM(DATA)
   output logic [`STACK_MEM_ADDR_WIDTH-1:0] mem_addr,
   output logic [`STACK_MEM_DATA_WIDTH-1:0] mem_data_out,
   input wire  	[`STACK_MEM_DATA_WIDTH-1:0] mem_data_in,
   output logic mem_we,
   output logic mem_oe,
   input wire  	mem_wrd,
   output logic mem_beg,

   // MEM(CODE)
   output logic [`DECODER_MEM_ADDR_WIDTH-1:0] memc_addr,
   input wire  	[`DECODER_MEM_DATA_WIDTH-1:0] memc_data_in,
   output logic memc_we,
   input wire  	memc_wrd,
   output logic memc_beg,
   
   // XF
   output logic start_xf,
   output logic [`DECODER_MEM_ADDR_WIDTH-1:0] addr_xf,
   input wire done_xf,
   
   // TOS
   input wire [`STACK_MEM_ADDR_WIDTH-1:0] tos_in, // Top Of Stack
   output wire [`STACK_MEM_ADDR_WIDTH-1:0] tos_out, // Top Of Stack

   // FP
   input wire [`STACK_MEM_ADDR_WIDTH-1:0] fp_in, // Frame Pointer
   output wire [`STACK_MEM_ADDR_WIDTH-1:0] fp_out // Frame Pointer
);

  reg [`DECODER_MEM_ADDR_WIDTH-1:0] addr;
  reg [`DECODER_MEM_ADDR_WIDTH-1:0] addr_out;
  reg [`DECODER_MEM_ADDR_WIDTH-1:0] addr_goto;
  wire goto_occured;
  wire exec_reset_done;
  reg    stop_exec;
  wire   stop_dec;
  wire   done_dec;
   // FIFO
  wire	fifo_rd_done;
  wire	fifo_wr_done;
  reg 	fifo_rd_en;
  wire fifo_wr_en;

  reg [`FIFO_ITEM_WIDTH-1:0]  fifo_din;
  reg [`FIFO_ITEM_WIDTH-1:0]  fifo_dout;
  
  reg 			dec_do_it;
  reg    loc_reset;

  sync_fifo #(.DWIDTH(`FIFO_ITEM_WIDTH)) u_sync_fifo 
	                (.reset(loc_reset),
                         .wr_en(fifo_wr_en),
                         .rd_en(fifo_rd_en),
                         .clk(clk),
                         .din(fifo_din),
                         .dout(fifo_dout),
                         .rd_done(fifo_rd_done),
                         .wr_done(fifo_wr_done)
                        );

  decoder #(.name("cf")) u_decoder 
			(.reset(loc_reset),
                         .clk(clk),
                         .do_it(dec_do_it),
                         .addr(addr),
                         .addr_out(addr_out),
                         .stop(stop_dec),
                         .done(done_dec),
                         .fifo_wr_done(fifo_wr_done),
                         .fifo_wr(fifo_wr_en),
                         .fifo_data(fifo_din),
                         
                         .mem_addr(memc_addr),
                         .mem_data_in(memc_data_in),
                         .mem_we(memc_we),
                         .mem_wrd(memc_wrd),
                         .mem_beg(memc_beg)
  );  

  reg 			exec_it;
  wire   exec_done;

  reg [`STACK_MEM_ADDR_WIDTH-1:0] stack_top;
  reg [`STACK_MEM_ADDR_WIDTH-1:0] stack_fp;
  wire [`STACK_MEM_ADDR_WIDTH-1:0] stack_top_out;
  wire [`STACK_MEM_ADDR_WIDTH-1:0] stack_fp_out;
                            
  assign tos_out = stack_top;
  assign fp_out = stack_fp;

  executer_cf stream_exec(
   .reset(loc_reset),
   .reset_done(exec_reset_done),
   .clk(clk),

   .do_it(exec_it),
   .done(exec_done),
   .stop(stop_exec),
   .new_addr(addr_goto),
   .goto(goto_occured),
   
   // FIFO
   .fifo_rd_done(fifo_rd_done),
   .fifo_rd(fifo_rd_en),
   .fifo_data(fifo_dout),

   // MEM
   .mem_addr(mem_addr),
   .mem_data_out(mem_data_out),
   .mem_data_in(mem_data_in),
   .mem_we(mem_we),
   .mem_oe(mem_oe),
   .mem_wrd(mem_wrd),
   .mem_beg(mem_beg),

   // XF   
   .start_xf(start_xf),
   .addr_xf(addr_xf),
   .done_xf(done_xf),
   
   .tos_in(tos_in),
   .tos_out(stack_top_out),
   
   .fp_in(stack_fp),
   .fp_out(stack_fp_out)
  );
  
  always @ (posedge exec_done) begin
    done <= exec_done;
  end

  always @ (posedge reset)begin
    loc_reset <= 1;
    stop <= 0;
    
    while (!done_dec) begin
        @(posedge clk);
    end;
    while (!exec_reset_done) begin
        @(posedge clk);
    end;
    done <= 1;
  end

  always @ (posedge do_it)begin
    addr <= start_addr;
    dec_do_it <= 1;
    exec_it <= 1;
    stack_top <= tos_in;
    stack_fp <= fp_in;

    $display("[%0t] begin branch", $time);
  end

  //always @ (posedge done_dec)begin
  //  addr <= addr_out;   
  //end

  always @ (posedge stop_exec)begin
    addr <= addr_goto;
    stack_top <= tos_out;
    stack_fp <= fp_out;
    if (!stop) begin
      loc_reset <= 1;
      @(posedge clk);
      @(posedge clk);
      dec_do_it <= 1;
      exec_it <= 1;
      $display("[%0t] XXX goto %d %d ", $time, addr_goto, addr);
    end else begin
      $display("[%0t] fin branch", $time);
    end;
  end

  always @ (posedge goto_occured) begin
    addr <= addr_goto;
    @(posedge clk);
    loc_reset <= 1;
    stack_top <= stack_top_out;
    stack_fp <= stack_fp_out;
    
    @(posedge clk);
    dec_do_it <= 1;
    exec_it <= 1;
    $display("[%0t] goto %d %d ", $time, addr_goto, addr);
  end

  always @ (negedge clk)begin
    loc_reset <= 0;
    exec_it <= 0;
    done <= 0;
    dec_do_it <= 0; 
  end

endmodule