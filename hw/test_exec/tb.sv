`include "common.h"

module tb;

  reg 			reset;
  reg 	 	clk;
  reg 			do_it;
  reg [`DECODER_MEM_ADDR_WIDTH-1:0] start_addr_cf;

  // MEM
  wire loc_we_cf;
  wire loc_oe_cf;
  wire loc_wrd_cf;
  wire loc_beg_cf;
  wire [`STACK_MEM_ADDR_WIDTH-1:0] loc_addr_cf;
  wire [`STACK_MEM_DATA_WIDTH-1:0] loc_data_out_cf;
  wire [`STACK_MEM_DATA_WIDTH-1:0] loc_data_in_cf;

  wire loc_we_xf;
  wire loc_oe_xf;
  wire loc_wrd_xf;
  wire loc_beg_xf;
  wire [`STACK_MEM_ADDR_WIDTH-1:0] loc_addr_xf;
  wire [`STACK_MEM_DATA_WIDTH-1:0] loc_data_out_xf;
  wire [`STACK_MEM_DATA_WIDTH-1:0] loc_data_in_xf;

  reg    stop_exec_xf;
  reg 			exec_it_cf;
  wire   exec_done_cf;
  reg    stop_exec_cf;

  wire [`DECODER_MEM_ADDR_WIDTH-1:0] code_addr_cf;
  wire [`DECODER_MEM_DATA_WIDTH-1:0] code_data_in_cf;
  wire code_we_cf;
  wire code_wrd_cf;
  wire code_beg_cf;

  wire [`DECODER_MEM_ADDR_WIDTH-1:0] code_addr_xf;
  wire [`DECODER_MEM_DATA_WIDTH-1:0] code_data_in_xf;
  wire code_we_xf;
  wire code_wrd_xf;
  wire code_beg_xf;
  
  // XF
  wire cf_starts_xf;
  wire [`DECODER_MEM_ADDR_WIDTH-1:0] cf_addr_for_xf;
  wire cf_done_xf;
  
    
  module_cf mod_cf(
   .reset(reset),
   .clk(clk),
   // CTL
   .do_it(exec_it_cf),
   .done(exec_done_cf),
   .stop(stop_exec_cf),
   // CODE
   .start_addr(start_addr_cf),
   // MEM/STACK
   .mem_addr(loc_addr_cf),
   .mem_data_out(loc_data_out_cf),
   .mem_data_in(loc_data_in_cf),
   .mem_we(loc_we_cf),
   .mem_oe(loc_oe_cf),
   .mem_wrd(loc_wrd_cf),
   .mem_beg(loc_beg_cf),
   // MEM/CODE
   .memc_addr(code_addr_cf),
   .memc_data_in(code_data_in_cf),
   .memc_we(code_we_cf),
   .memc_wrd(code_wrd_cf),
   .memc_beg(code_beg_cf),
   
   // XF
   .start_xf(cf_starts_xf),
   .addr_xf(cf_addr_for_xf),
   .done_xf(cf_done_xf)
  );
    
  module_xf mod_xf(
   .reset(reset),
   .clk(clk),
   // CTL
   .do_it(cf_starts_xf),
   .done(cf_done_xf),
   .stop(stop_exec_xf),
   // CODE
   .start_addr(cf_addr_for_xf),
   // MEM/STACK
   .mem_addr(loc_addr_xf),
   .mem_data_out(loc_data_out_xf),
   .mem_data_in(loc_data_in_xf),
   .mem_we(loc_we_xf),
   .mem_oe(loc_oe_xf),
   .mem_wrd(loc_wrd_xf),
   .mem_beg(loc_beg_xf),
   // MEM/CODE
   .memc_addr(code_addr_xf),
   .memc_data_in(code_data_in_xf),
   .memc_we(code_we_xf),
   .memc_wrd(code_wrd_xf),
   .memc_beg(code_beg_xf)
  );
    
    
  dual_port_sync_ram 
    #( .init_from_file(1),
       .file_data("data_segment.mem"),
       .data_width(`STACK_MEM_DATA_WIDTH),
       .addr_width(`STACK_MEM_ADDR_WIDTH),
       .mem_depth(`STACK_MEM_DATA_DEPTH)
    ) 
    v_stack (
     .clk(clk),
     .reset(reset),

     .addr_a(loc_addr_cf),
     .data_in_a(loc_data_out_cf),
     .data_out_a(loc_data_in_cf),
     .we_a(loc_we_cf),
     .oe_a(loc_oe_cf),
     .rd_a(loc_wrd_cf),
     .beg_a(loc_beg_cf),

     .addr_b(loc_addr_xf),
     .data_in_b(loc_data_out_xf),
     .data_out_b(loc_data_in_xf),
     .we_b(loc_we_xf),
     .oe_b(loc_oe_xf),
     .rd_b(loc_wrd_xf),
     .beg_b(loc_beg_xf)
  );
  

  dual_port_sync_ram v_code (
     .clk(clk),
     .reset(reset),
     
     .addr_a(code_addr_cf),
     .data_in_a(),
     .data_out_a(code_data_in_cf),
     .we_a(code_we_cf),
     .oe_a(1'b1),
     .rd_a(code_wrd_cf),
     .beg_a(code_beg_cf),

     .addr_b(code_addr_xf),
     .data_in_b(),
     .data_out_b(code_data_in_xf),
     .we_b(code_we_xf),
     .oe_b(1'b1),
     .rd_b(code_wrd_xf),
     .beg_b(code_beg_xf)
  );
  
  always #10 clk <= ~clk;

  initial begin
    clk 	<= 0;
    reset 	<= 1;

    #20 reset <= 0;
  end
  
  initial begin
    #20 @(posedge clk);

    start_addr_cf <= 0;
    exec_it_cf <= 1;
    $display("[%0t] let's start it", $time);
  end

  always @ (posedge exec_done_cf)begin
    $display("[%0t] that's it", $time);
  end


endmodule