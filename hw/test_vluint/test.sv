`include "common.h"

module tb;

  reg clk;
  reg reset;
  reg [`MEM_ADDR_WIDTH-1:0] addr;
  reg [`WORD_WIDTH-1:0] instr_data;
  reg [`MEM_ADDR_WIDTH-1:0] addr_out;
  reg ready2;
  reg beg2;
  
  
  vluint7 v0 ( 	
    	.clk(clk),
     .reset(reset),
     .addr(addr),
     .addr_out(addr_out),
     .data(instr_data),
   		.rd(ready2),
   		.beg(beg2)
  );

  always #10 clk = ~clk;

  initial begin
    {clk, addr} <= 0;
    
    reset <= 1;
    repeat (2) @ (posedge clk);
    reset <= 0;
/*
    repeat (1) @(posedge clk) addr <= 0; we <= 1; oe <= 0; tb_data <= 8'b11101110; beg <= 1;
    repeat (1) @(posedge clk) beg <= 0;
    repeat (1) @(posedge clk) addr <= 1; we <= 1; oe <= 0; tb_data <= 8'b10010110; beg <= 1;
    repeat (1) @(posedge clk) beg <= 0;
    repeat (1) @(posedge clk) addr <= 2; we <= 1; oe <= 0; tb_data <= 8'b00000001; beg <= 1;
    repeat (1) @(posedge clk) beg <= 0;
    repeat (1) @(posedge clk) addr <= 3; we <= 1; oe <= 0; tb_data <= 8'b01011000; beg <= 1;
    repeat (1) @(posedge clk) beg <= 0;
    repeat (1) @(posedge clk) addr <= 4; we <= 1; oe <= 0; tb_data <= 8'b10011101; beg <= 1;
    repeat (1) @(posedge clk) beg <= 0;
    repeat (1) @(posedge clk) addr <= 5; we <= 1; oe <= 0; tb_data <= 8'b11010110; beg <= 1;
    repeat (1) @(posedge clk) beg <= 0;
    repeat (1) @(posedge clk) addr <= 6; we <= 1; oe <= 0; tb_data <= 8'b00000110; beg <= 1;
    repeat (1) @(posedge clk) beg <= 0;
*/
    repeat (1) @(posedge clk) addr <= 0;
    repeat (1) @(posedge clk) beg2 <= 1; 
    repeat (10) @ (posedge clk); beg2 <= 0; addr <= addr_out;
    repeat (1) @(posedge clk) beg2 <= 1; 
    repeat (10) @ (posedge clk); beg2 <= 0; addr <= addr_out;
    repeat (1) @(posedge clk) beg2 <= 1; 
    repeat (100) @ (posedge clk); beg2 <= 0; addr <= addr_out;


//    for (integer i = 0; i < 2**`MEM_ADDR_WIDTH; i= i+1) begin
//      repeat (1) @(posedge clk) addr <= i; we <= 1; cs <=1; oe <= 0; tb_data <= $random; beg <= 1;
//      repeat (1) @(posedge clk) beg <= 0;
//    end

//    for (integer i = 0; i < 2**`MEM_ADDR_WIDTH; i= i+1) begin
//      repeat (1) @(posedge clk) addr <= i; we <= 0; oe <= 1; beg <= 1;
//      repeat (1) @(posedge clk) beg <= 0;
//    end

    #200 $finish;
  end
endmodule