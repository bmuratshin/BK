`include "common.h"

module vluint7 ( 	
   input wire	clk,
   input wire reset,
   input wire	beg,
   
   input wire [`DECODER_MEM_ADDR_WIDTH-1:0]	addr,
   output logic [`DECODER_MEM_ADDR_WIDTH-1:0]	addr_out,
   output logic rd,
   output logic [`INSTR_WIDTH-1:0]	data,
   
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

  wire loc_we;
  assign mem_we = loc_we;

  wire loc_wrd;
  assign loc_wrd = mem_wrd;
  
  reg loc_beg;
  assign mem_beg = loc_beg;

  //reg loc_rd;
  reg working;
  wire loc_oe;
  reg [5:0] loc_shift;

  //assign loc_wrd = loc_rd;
  assign loc_oe = 1'b1;
  assign loc_we = 1'b0;

  always @ (posedge reset) begin
      @(posedge clk);

      loc_beg <= 0;     // начинаем читать память
      data <= 0;        // 
      loc_shift <= 0;   // распаковка с младших разрядов
      loc_addr <= 0; // 
      addr_out <= 0;
      rd <= 0;          // результат не готов
      working <= 0;     // распаковываем
  end

  always @ (posedge beg) begin
      //loc_rd <= 0;      // ожидание чтения записи
      loc_beg <= 1;     // начинаем читать память
      data <= 0;        // 
      loc_shift <= 0;   // распаковка с младших разрядов
      loc_addr <= addr; // 
      addr_out <= addr;
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
