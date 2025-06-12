`include "common.h"

module vluint7 ( 	
   input wire	clk,
   input wire reset,
   input wire	beg,
   input wire [`DECODER_MEM_ADDR_WIDTH-1:0]	addr,

   output logic [`DECODER_MEM_ADDR_WIDTH-1:0]	addr_out,
   output logic rd,
   output logic [`INSTR_WIDTH-1:0]	data
  );

  wire [`DECODER_MEM_DATA_WIDTH-1:0] 	tmp_data;
  reg loc_beg;
  reg loc_rd;
  reg working;
  wire loc_wrd;
  wire loc_oe;
  wire loc_we;
  reg [5:0] loc_shift;
  reg [`DECODER_MEM_ADDR_WIDTH-1:0]	loc_addr;

  assign loc_wrd = loc_rd;
  assign loc_oe = 1'b1;
  assign loc_we = 1'b0;
  
  single_port_sync_ram u0 (
    	.clk(clk),
     .reset(reset),
     .addr(loc_addr),
     .data_out(tmp_data),
     .data_in(),
   		.we(loc_we),
   		.oe(loc_oe),
   		.rd(loc_wrd),
   		.beg(loc_beg)
  );

  always @ (posedge beg) begin
      loc_rd <= 0;      // ожидание чтения записи
      loc_beg <= 1;     // начинаем читать память
      data <= 0;        // 
      loc_shift <= 0;   // распаковка с младших разрядов
      loc_addr <= addr; // 
      rd <= 0;          // результат не готов
      working <= 1;     // распаковываем
      //$display("<<<<< begin vluint7 %d", addr);
  end
  
  always @ (posedge loc_wrd) begin
    //$display("data vluint7 shift=%d %d %x %d %x", loc_shift, loc_addr, tmp_data, tmp_data[7], tmp_data[6:0]);
    if (working) begin
      data <= data | (tmp_data[6:0] << loc_shift);
      loc_addr ++;
      if (tmp_data[7]) begin
        loc_shift += 7;
        loc_beg <= 1;
      end else begin
        rd <= 1;
        working <= 0;
        addr_out = loc_addr;
        loc_beg <= 0;
      end
    end
  end

  always @ (negedge clk) begin
      if (loc_beg) begin
        loc_beg <= 0;
    end
  end
  
endmodule
