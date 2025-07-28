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
   input wire done_xf
);

  reg [`DECODER_MEM_ADDR_WIDTH-1:0] addr;
  reg [`DECODER_MEM_ADDR_WIDTH-1:0] addr_out;
  reg    stop_exec;
  wire   stop_dec;
  wire   done_dec;
   // FIFO
  wire	fifo_full;
  wire fifo_wr;
  reg [`INSTR_WIDTH-1:0] fifo_data;


  reg [`INSTR_WIDTH-1:0]  fifo_din;
  reg [`INSTR_WIDTH-1:0] 	fifo_dout;
  reg 			fifo_empty;
  reg 			fifo_rd_en;
  //reg 			fifo_wr_en;
  reg 			dec_do_it;

  sync_fifo #(.DWIDTH(`INSTR_WIDTH)) u_sync_fifo 
	                      (.reset(reset),
                         .wr_en(fifo_wr),
                         .rd_en(fifo_rd_en),
                         .clk(clk),
                         .din(fifo_din),
                         .dout(fifo_dout),
                         .empty(fifo_empty),
                         .full(fifo_full)
                        );

  decoder u_decoder ( .reset(reset),
                         .clk(clk),
                         .do_it(dec_do_it),
                         .addr(addr),
                         .addr_out(addr_out),
                         .stop(stop_dec),
                         .done(done_dec),
                         .fifo_full(fifo_full),
                         .fifo_wr(fifo_wr),
                         .fifo_data(fifo_din),
                         
                         .mem_addr(memc_addr),
                         .mem_data_in(memc_data_in),
                         .mem_we(memc_we),
                         .mem_wrd(memc_wrd),
                         .mem_beg(memc_beg)
  );  

  reg 			exec_it;
  wire   exec_done;

  executer_cf stream_exec(
   .reset(reset),
   .clk(clk),

   .do_it(exec_it),
   .done(exec_done),
   .stop(stop_exec),
   
   // FIFO
   .fifo_empty(fifo_empty),
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
   .done_xf(done_xf)
  );
  
  assign done = exec_done;

  always @ (posedge do_it)begin
    addr <= start_addr;
    dec_do_it <= 1;
    exec_it <= 1;
    $display("[%0t] begin", $time);
  end

  always @ (posedge done_dec)begin
    dec_do_it <= 0; 
    addr <= addr_out;   
    
    @(posedge clk);
    if (!stop)
      exec_it <= 1; 
  end

endmodule