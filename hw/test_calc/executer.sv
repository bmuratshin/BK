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


  wire [`STACK_MEM_DATA_WIDTH-1:0] tmp_data_out;
  reg [`STACK_MEM_DATA_WIDTH-1:0] tmp_data_reg_in;
  reg [`STACK_MEM_DATA_WIDTH-1:0] tmp_data_reg_out;

  wire [`STACK_MEM_ADDR_WIDTH-1:0] tmp_addr_wire;
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
  assign tmp_addr_wire = tmp_addr[`STACK_MEM_DATA_WIDTH + 1 : 2];

  single_port_sync_ram 
    #( .init_from_file(1),
       .file_data("data_segment.mem"),
       .data_width(`STACK_MEM_DATA_WIDTH),
       .addr_width(`STACK_MEM_ADDR_WIDTH),
       .mem_depth(`STACK_MEM_DATA_DEPTH)
    ) 
    v_stack (
    	.clk(clk),
     .reset(reset),
     .addr(tmp_addr_wire),
     .data_in(tmp_data_reg_out),
     .data_out(tmp_data_reg_in),
   		.we(loc_we),
   		.oe(loc_oe),
   		.rd(loc_wrd),
   		.beg(loc_beg)
  );

  reg has_smth;
  reg [1:0] nargs;
  reg [1:0] cur_arg;
  reg [`INSTR_WIDTH-1:0] cur_instr;
  reg [`INSTR_WIDTH-1:0] cur_args [4];  

  // word in bytes
  integer stack_step = `STACK_MEM_DATA_WIDTH / 8; 
   
  always @ (posedge reset) begin
    integer i;
     
    done <= 0;
    stop <= 0;
    nargs <= 0;
    
    cur_arg <= 0;
    cur_instr <= 0;
    has_smth <= 1'b0;
    
    stack_top <= 4 * stack_step;
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
          6'b000001: // VARPUSH
          begin
            tmp_addr <= stack_top;
            tmp_data_reg_out[`STACK_MEM_DATA_WIDTH:`INSTR_WIDTH] <= 0;
            tmp_data_reg_out[`INSTR_WIDTH-1:0] = cur_args[0];

            loc_we <= 1;
            while (!loc_wrd) begin
              @(posedge clk);
            end;
            @(posedge clk);
            loc_we <= 0;
            stack_top <= stack_top + stack_step;
            
            $display("[%0t] VARPUSH %d", $time, cur_args[0]);
          end
          6'b000010: begin // EVAL
            tmp_addr <= stack_top - stack_step;
            loc_we <= 0;
            while (!loc_wrd) begin
              @(posedge clk);
            end;
            @(posedge clk);
            @(posedge clk);

            tmp_addr <= tmp_data_reg_in;

            @(posedge clk);
            @(posedge clk);
            
            tmp_addr <= stack_top - stack_step;
            tmp_data_reg_out <= tmp_data_reg_in;

            @(posedge clk);
            loc_we <= 1;
            while (!loc_wrd) begin
              @(posedge clk);
            end;
            @(posedge clk);
            loc_we <= 0;
            
            $display("[%0t] EVAL", $time);
          end
          6'b000011: // IMDPUSH
          begin
            tmp_addr <= stack_top;
            tmp_data_reg_out[`STACK_MEM_DATA_WIDTH:`INSTR_WIDTH] <= 0;
            tmp_data_reg_out[`INSTR_WIDTH-1:0] = cur_args[0];

            loc_we <= 1;
            while (!loc_wrd) begin
              @(posedge clk);
            end;
            @(posedge clk);
            loc_we <= 0;
            stack_top <= stack_top + stack_step;
            
            $display("[%0t] IMDPUSH %d", $time, cur_args[0]);
          end
          6'b000100: begin  // POP
            stack_top <= stack_top - stack_step;
            $display("[%0t] POP", $time); 
          end
          6'b000101: begin  // ADD
            // reading right arg -------------------------------
            tmp_addr <= stack_top - stack_step;
            loc_we <= 0;
            loc_beg <= 1;
            stack_top <= stack_top - stack_step;
            while (!loc_wrd) begin
              @(posedge clk);
            end;
            @(posedge clk);
            loc_beg <= 0;
            @(posedge clk);
            arg_right <= tmp_data_reg_in;
            
            // reading left arg -------------------------------
            tmp_addr <= stack_top - stack_step;
            loc_we <= 0;
            loc_beg <= 1;
            while (!loc_wrd) begin
              @(posedge clk);
            end;
            @(posedge clk);
            @(posedge clk);
            arg_left <= tmp_data_reg_in;
            tmp_data_reg_out <= tmp_data_reg_in + arg_right;
            // saving the result -----------------------------
            loc_we <= 1;
            while (!loc_wrd) begin
              @(posedge clk);
            end;
            @(posedge clk);
            loc_we <= 0;
          
            $display("[%0t] ADD %d+%d=%d", $time, tmp_data_reg_in, arg_right, tmp_data_reg_in + arg_right);
          end
          6'b000111: begin // MUL
            // reading right arg -------------------------------
            tmp_addr <= stack_top - stack_step;
            loc_we <= 0;
            loc_beg <= 1;
            stack_top <= stack_top - stack_step;
            while (!loc_wrd) begin
              @(posedge clk);
            end;
            @(posedge clk);
            loc_beg <= 0;
            @(posedge clk);
            arg_right <= tmp_data_reg_in;
            
            // reading left arg -------------------------------
            tmp_addr <= stack_top - stack_step;
            loc_we <= 0;
            loc_beg <= 1;
            while (!loc_wrd) begin
              @(posedge clk);
            end;
            @(posedge clk);
            @(posedge clk);
            arg_left <= tmp_data_reg_in;
            tmp_data_reg_out <= tmp_data_reg_in * arg_right;
            // saving the result -----------------------------
            loc_we <= 1;
            while (!loc_wrd) begin
              @(posedge clk);
            end;
            @(posedge clk);
            loc_we <= 0;
          
            $display("[%0t] MUL %d*%d=%d", $time, tmp_data_reg_in, arg_right, tmp_data_reg_in * arg_right);
          end
          6'b000110: begin // SUB
            // reading right arg -------------------------------
            tmp_addr <= stack_top - stack_step;
            loc_we <= 0;
            loc_beg <= 1;
            stack_top <= stack_top - stack_step;
            while (!loc_wrd) begin
              @(posedge clk);
            end;
            @(posedge clk);
            loc_beg <= 0;
            @(posedge clk);
            arg_right <= tmp_data_reg_in;
            
            // reading left arg -------------------------------
            tmp_addr <= stack_top - stack_step;
            loc_we <= 0;
            loc_beg <= 1;
            while (!loc_wrd) begin
              @(posedge clk);
            end;
            @(posedge clk);
            @(posedge clk);
            arg_left <= tmp_data_reg_in;
            tmp_data_reg_out <= tmp_data_reg_in - arg_right;
            // saving the result -----------------------------
            loc_we <= 1;
            while (!loc_wrd) begin
              @(posedge clk);
            end;
            @(posedge clk);
            loc_we <= 0;
          
            $display("[%0t] SUB %d-%d=%d", $time, tmp_data_reg_in, arg_right, tmp_data_reg_in - arg_right);
          end
        endcase
        //$display("[%0t] EXEC opcode=0x%0h nargs=%d arg=%d", $time, cur_instr, cur_arg, cur_arg ? cur_args[0] : 0);
      end
    end
  end

endmodule