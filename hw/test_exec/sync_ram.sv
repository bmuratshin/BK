`include "common.h"

module single_port_sync_ram
#(  init_from_file=1,
    file_data  = "rom_image.mem",
    addr_width = `DECODER_MEM_ADDR_WIDTH,
    data_width = `DECODER_MEM_DATA_WIDTH,
    mem_depth  = `DECODER_MEM_DATA_DEPTH
) (
     input wire	clk,
     input wire reset,
     
     input  wire [addr_width-1:0] addr,
     input  wire [data_width-1:0] data_in,
     output reg  [data_width-1:0] data_out,
     input  wire   we,
     input  wire  oe,
     input  wire  beg,
     output logic rd
  );

  reg [data_width-1:0] 	mem [mem_depth];

  initial begin
    if (init_from_file) begin
      $display("Loading rom.");
      $readmemh(file_data, mem);
    end;
  end

  always @ (posedge beg)begin
      if (we) begin
        mem[addr] <= data_in;
      end else begin
    	   data_out <= mem[addr];
      end
      rd <= 1;
  end

  always @ (negedge clk) begin
      rd <= 0;
  end

endmodule

module dual_port_sync_ram
#(  init_from_file=1,
    file_data="rom_image.mem",
    addr_width=`DECODER_MEM_ADDR_WIDTH,
    data_width=`DECODER_MEM_DATA_WIDTH,
    mem_depth=`DECODER_MEM_DATA_DEPTH
) ( 	
    input wire	clk,
    input wire reset,
     
    input wire [addr_width-1:0]	addr_a,
    input wire [data_width-1:0]	data_in_a,
    output reg [data_width-1:0]	data_out_a,
    input wire  			we_a,
    input wire   		oe_a,
    input wire   		beg_a,
    output reg                rd_a,

    input wire [addr_width-1:0]	addr_b,
    input wire [data_width-1:0]	data_in_b,
    output reg [data_width-1:0]	data_out_b,
    input wire  			we_b,
    input wire   		oe_b,
    input wire   		beg_b,
    output reg                rd_b
  );
  reg [data_width-1:0] 	        mem [mem_depth];

  initial begin
    if (init_from_file) begin
      $display("Loading rom.");
      $readmemh(file_data, mem);
    end;
  end
    
  always @ (posedge reset)begin
      rd_a <= 0;
      rd_b <= 0;
  end

  always @ (posedge beg_a)begin
      while (rd_a) begin
        @(posedge clk);
      end;

      if (we_a) begin
          mem[addr_a] <= data_in_a;
      end else begin
          data_out_a <= mem[addr_a];
      end
      $display("[%0t] MEM A[%d]=%d %d", $time, addr_a, data_in_a, we_a);
      @(negedge clk);
      rd_a <= 1;
  end

  always @ (posedge beg_b)begin
      while (rd_b) begin
        @(posedge clk);
      end;

      if (we_b) begin
          mem[addr_b] <= data_in_b;
      end else begin
          data_out_b <= mem[addr_b];
      end
      $display("[%0t] MEM B [%d] %d", $time, addr_b, we_b);

      @(negedge clk);
      rd_b <= 1;
  end

  always @ (negedge clk) begin
      rd_a <= 0;
      rd_b <= 0;
     //$monitor("[%0t] mem clear", $time);
  end

endmodule
