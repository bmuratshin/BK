`include "common.h"

module executer (
   input wire reset,
   input wire	clk,

   input wire	do_it,
   output logic done,
   output logic stop,
   
   // FIFO
   input wire	fifo_empty,
   output logic fifo_rd,
   input wire	[`INSTR_WIDTH-1:0] fifo_data
  );

  reg has_smth;
  reg [1:0] nargs;
  reg [1:0] cur_arg;
  reg [`INSTR_WIDTH-1:0] cur_instr;
  reg [`INSTR_WIDTH-1:0] cur_args [4];  
  
  always @ (posedge reset) begin
    done <= 0;
    stop <= 0;
    nargs <= 0;
    
    cur_arg <= 0;
    cur_instr <= 0;
    has_smth <= 1'b0;
  end;
                      
  always @ (posedge do_it) begin
    while (!stop) begin
      // Wait until there is data in fifo
      while (fifo_empty) begin
        fifo_rd <= 0;
        $display("[%0t] FIFO is empty, wait for writes to happen", $time);
        @(posedge clk);
      end;
      
      // Sample new values from FIFO 
      fifo_rd <= 1'b1;
      @(posedge clk);
      fifo_rd <= 1'b0;
      @(posedge clk);

      if (nargs) begin
        cur_args[cur_arg] <= fifo_data;
        nargs <= nargs - 1;
        cur_arg <= cur_arg + 1;
      end else begin
        cur_instr <= fifo_data;
        has_smth <= 1'b1;
        cur_arg <= 0;
        nargs <= fifo_data[1:0];
      end;
      
      if (has_smth && cur_instr == 0)
        stop <= 1'b1;
      else if (has_smth && nargs == 0) begin
        case (cur_instr[7:2])
          6'b000001: $display("[%0t] VARPUSH %d", $time, cur_args[0]);
          6'b000010: $display("[%0t] EVAL", $time);
          6'b000011: $display("[%0t] IMDPUSH %d", $time, cur_args[0]);
          6'b000101: $display("[%0t] ADD", $time);
          6'b000111: $display("[%0t] MUL", $time);
          6'b000110: $display("[%0t] MINUS", $time);
        endcase
        //$display("[%0t] EXEC opcode=0x%0h nargs=%d arg=%d", $time, cur_instr, cur_arg, cur_arg ? cur_args[0] : 0);
      end
    end
  end

endmodule