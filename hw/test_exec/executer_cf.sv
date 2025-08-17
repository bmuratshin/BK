`include "common.h"

module executer_cf (
   input wire reset,
   input wire	clk,

   input wire	do_it,
   output logic done,
   
   output logic stop,
   output logic [`DECODER_MEM_ADDR_WIDTH-1:0] new_addr,
   
   // FIFO
   input wire	fifo_empty,
   output logic fifo_rd,
   input wire	[`INSTR_WIDTH-1:0] fifo_data,
   
   // MEM(DATA)
   output logic [`STACK_MEM_ADDR_WIDTH-1:0] mem_addr,
   output logic [`STACK_MEM_DATA_WIDTH-1:0] mem_data_out,
   input wire  	[`STACK_MEM_DATA_WIDTH-1:0] mem_data_in,
   output logic mem_we,
   output logic mem_oe,
   input wire  	mem_wrd,
   output logic mem_beg,
   
   // XF
   output logic start_xf,
   output logic [`DECODER_MEM_ADDR_WIDTH-1:0] addr_xf,
   input wire done_xf,
   
   // TOS
   input wire [`STACK_MEM_ADDR_WIDTH-1:0] tos_in, // Top Of Stack
   output wire [`STACK_MEM_ADDR_WIDTH-1:0] tos_out // Top Of Stack
  );


  wire [`STACK_MEM_DATA_WIDTH-1:0] tmp_data_out;
  reg [`STACK_MEM_DATA_WIDTH-1:0] tmp_data_reg_in;
  reg [`STACK_MEM_DATA_WIDTH-1:0] tmp_data_reg_out;

  reg [`STACK_MEM_DATA_WIDTH-1:0] tmp_addr;
  reg [`STACK_MEM_DATA_WIDTH-1:0] stack_top;
  reg loc_beg;
  reg loc_rd;
  reg loc_oe;
  reg loc_we;
  reg loc_wrd;

  reg [`STACK_MEM_DATA_WIDTH-1:0] arg_left;
  reg [`STACK_MEM_DATA_WIDTH-1:0] arg_right;

  assign loc_oe = 1'b1;
  assign mem_addr[`STACK_MEM_ADDR_WIDTH-1:0] = tmp_addr[`STACK_MEM_ADDR_WIDTH + 1 : 2];
  assign mem_data_out = tmp_data_reg_out;
  assign tmp_data_reg_in = mem_data_in;
  assign mem_we = loc_we;
  assign mem_oe = loc_oe;
  assign mem_wrd = loc_wrd;
  assign mem_beg = loc_beg;
  
  assign tos_out = stack_top;

  reg has_smth;
  reg [1:0] nargs;
  reg [1:0] cur_arg;
  reg [`INSTR_WIDTH-1:0] cur_instr;
  reg [`INSTR_WIDTH-1:0] cur_args [4];  

   
  always @ (posedge reset) begin
    integer i;
     
    done <= 0;
    stop <= 0;
    nargs <= 0;
    
    cur_arg <= 0;
    cur_instr <= 0;
    has_smth <= 1'b0;
    
    start_xf <= 0;
  end;
                      
  always @ (posedge do_it) begin
    stack_top <= tos_in;
    
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
      
      if (has_smth && cur_instr == 0) begin
        stop <= 1'b1;
        done <= 1'b1;
      end else if (!start_xf && has_smth && nargs == 0) begin
        case (cur_instr[7:2])
          6'b000001: // EXEC
          begin
            tmp_addr <= stack_top;
            tmp_data_reg_out[`STACK_MEM_DATA_WIDTH:`INSTR_WIDTH] <= 0;
            tmp_data_reg_out[`INSTR_WIDTH-1:0] = cur_args[0];

            $display("[%0t] EXEC %d", $time, cur_args[0]);
            start_xf <= 1;
            addr_xf <= cur_args[0];
            
            while (!done_xf) begin
              @(posedge clk);
            end;
            @(posedge clk);
            start_xf <= 0;
            stack_top <= tos_in;
            
            $display("[%0t] EXECUTED %d", $time, cur_args[0]);
          end
          
          6'b000010: begin // IF2
            tmp_addr <= stack_top - `STACK_STEP;
            loc_we <= 0;
            while (!loc_wrd) begin
              @(posedge clk);
            end;
            @(posedge clk);
            @(posedge clk);

            stack_top <= stack_top - `STACK_STEP;

            if (tmp_data_reg_in == 0) begin
              new_addr <= cur_args[0];
              stop <= 1;
              done <= 0;
            end
              

            $display("[%0t] IF(%d) %d = %d", $time, tmp_addr, tmp_data_reg_in, cur_args[0]);
          end
          
          6'b000011: begin // GOTO
            tmp_addr <= stack_top - `STACK_STEP;
            loc_we <= 0;
            while (!loc_wrd) begin
              @(posedge clk);
            end;
            @(posedge clk);
            @(posedge clk);

            if (tmp_data_reg_in != 0) begin
              new_addr <= cur_args[0];
              stop <= 1;
              done <= 0;
            end
              

            $display("[%0t] GOTO %d", $time, new_addr);
          end
        endcase
        //$display("[%0t] EXEC opcode=0x%0h nargs=%d arg=%d", $time, cur_instr, cur_arg, cur_arg ? cur_args[0] : 0);
      end
    end
  end

endmodule