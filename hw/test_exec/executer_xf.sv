`include "common.h"

module executer_xf (
   input wire reset,
   input wire	clk,

   input wire	do_it,
   output logic done,
   output logic stop,
   
   // FIFO
   input wire	fifo_rd_done,
   output logic fifo_rd,
   input wire	[`FIFO_ITEM_WIDTH-1:0] fifo_data,
   
   // MEM(DATA)
   output logic [`STACK_MEM_ADDR_WIDTH-1:0] mem_addr,
   output logic [`STACK_MEM_DATA_WIDTH-1:0] mem_data_out,
   input wire  	[`STACK_MEM_DATA_WIDTH-1:0] mem_data_in,
   output reg mem_we,
   output logic mem_oe,
   input wire  	mem_wrd,
   output reg mem_beg,
   // TOS
   input wire [`STACK_MEM_ADDR_WIDTH-1:0] tos_in, // Top Of Stack
   output wire [`STACK_MEM_ADDR_WIDTH-1:0] tos_out, // Top Of Stack
   // FP
   input wire [`STACK_MEM_ADDR_WIDTH-1:0] fp_in // Frame Pointer
  );

  reg fifo_rd_cnt;
  wire [`STACK_MEM_DATA_WIDTH-1:0] tmp_data_out;
  reg [`STACK_MEM_DATA_WIDTH-1:0] tmp_data_reg_in;
  reg [`STACK_MEM_DATA_WIDTH-1:0] tmp_data_reg_out;

  reg [`STACK_MEM_DATA_WIDTH-1:0] tmp_addr;
  reg [`STACK_MEM_DATA_WIDTH-1:0] stack_top;

  reg [`STACK_MEM_DATA_WIDTH-1:0] arg_left;
  reg [`STACK_MEM_DATA_WIDTH-1:0] arg_right;

  assign mem_addr[`STACK_MEM_ADDR_WIDTH-1:0] = tmp_addr[`STACK_MEM_ADDR_WIDTH + 1 : 2];
  assign mem_data_out = tmp_data_reg_out;
  assign tmp_data_reg_in = mem_data_in;
  
  assign tos_out = stack_top;

  reg has_smth;
  reg working;
  reg [1:0] nargs;
  reg [1:0] cur_arg;
  reg [`DECODER_MEM_ADDR_WIDTH-1:0] cur_addr;
  reg [`INSTR_WIDTH-1:0] cur_instr;
  reg [`INSTR_WIDTH-1:0] cur_args [4];  

  always @ (posedge reset) begin

    nargs <= 0;
    
    cur_arg <= 0;
    cur_instr <= 0;
    cur_addr <= 0;
    has_smth <= 0;
    
    working <= 0;
    stop <= 0;
    done <= 1;
    mem_oe <= 1;
  end;

  always @ (posedge do_it) begin
    working <= 1;
    fifo_rd <= 1;
    fifo_rd_cnt <= 1;
    stack_top <= tos_in;
  end;

  always @ (posedge fifo_rd_done) begin

    if (!stop && working) begin
//      $display("[%0t] FIFO read %x %d", $time, fifo_data, nargs);

      if (nargs) begin
        cur_args[cur_arg] <= fifo_data[`INSTR_WIDTH-1:0];
        cur_addr <= fifo_data[`FIFO_ITEM_WIDTH-1:`INSTR_WIDTH];
        nargs <= nargs - 1;
        cur_arg <= cur_arg + 1;
      end else begin
        cur_instr <= fifo_data[`INSTR_WIDTH-1:0];
        cur_addr <= fifo_data[`FIFO_ITEM_WIDTH-1:`INSTR_WIDTH];
        has_smth <= 1'b1;
        cur_arg <= 0;
        nargs <= fifo_data[1:0];
      end;
      @(posedge clk);
      $display("[%0t] XF has_smth=%d cur_instr=%d nargs=%d", $time, has_smth, cur_instr, nargs);
      
      if (has_smth && cur_instr == 0) begin
        stop <= 1'b1;
        done <= 1'b1;
      end else if (has_smth && nargs == 0) begin
        case (cur_instr[7:2])
          6'b000001: // VARPUSH
          begin
            tmp_addr <= stack_top;
            tmp_data_reg_out[`STACK_MEM_DATA_WIDTH:`FIFO_ITEM_WIDTH] <= 0;
            tmp_data_reg_out[`FIFO_ITEM_WIDTH-1:0] = cur_args[0];

            mem_beg <= 1;
            mem_we <= 1;
            while (!mem_wrd && working) begin
              @(posedge clk);
            end;
            stack_top <= stack_top + `STACK_STEP;
            
            $display("[%0t] VARPUSH %d", $time, cur_args[0]);
          end
          6'b000010: begin // EVAL
            $display("[%0t] EVAL BEGIN", $time);
            tmp_addr <= stack_top - `STACK_STEP;
            mem_we <= 0;
            mem_beg <= 1;
            @(posedge clk);
            while (!mem_wrd && working) begin
              @(posedge clk);
            end;

            tmp_addr <= tmp_data_reg_in;
            mem_beg <= 1;
            @(posedge clk);

            while (!mem_wrd && working) begin
              @(posedge clk);
            end;
            
            tmp_addr <= stack_top - `STACK_STEP;
            tmp_data_reg_out <= tmp_data_reg_in;

            @(posedge clk);
            mem_we <= 1;
            mem_beg <= 1;
            while (!mem_wrd && working) begin
              @(posedge clk);
            end;
            
            $display("[%0t] EVAL", $time);
          end
          6'b000011: // IMDPUSH
          begin
            tmp_addr <= stack_top;
            tmp_data_reg_out[`STACK_MEM_DATA_WIDTH:`INSTR_WIDTH] <= 0;
            tmp_data_reg_out[`INSTR_WIDTH-1:0] = cur_args[0];
            $display("[%0t] IMDPUSH BEG", $time);

            mem_beg <= 1;
            mem_we <= 1;
            while (!mem_wrd && working) begin
              @(posedge clk);
            end;
            stack_top <= stack_top + `STACK_STEP;
            
            $display("[%0t] IMDPUSH %d", $time, cur_args[0]);
          end
          6'b000100: begin  // POP
            stack_top <= stack_top - `STACK_STEP;
            $display("[%0t] POP", $time); 
          end
          6'b000101: begin  // ADD
            // reading right arg -------------------------------
            tmp_addr <= stack_top - `STACK_STEP;
            mem_we <= 0;
            mem_beg <= 1;
            stack_top <= stack_top - `STACK_STEP;
            while (!mem_wrd && working) begin
              @(posedge clk);
            end;
            arg_right <= tmp_data_reg_in;
            
            // reading left arg -------------------------------
            tmp_addr <= stack_top - `STACK_STEP;
            mem_we <= 0;
            mem_beg <= 1;
            while (!mem_wrd && working) begin
              @(posedge clk);
            end;
            arg_left <= tmp_data_reg_in;
            tmp_data_reg_out <= tmp_data_reg_in + arg_right;
            // saving the result -----------------------------
            mem_we <= 1;
            mem_beg <= 1;
            while (!mem_wrd && working) begin
              @(posedge clk);
            end;
          
            $display("[%0t] ADD %d+%d=%d", $time, tmp_data_reg_in, arg_right, tmp_data_reg_in + arg_right);
          end
          6'b000111: begin // MUL
            // reading right arg -------------------------------
            tmp_addr <= stack_top - `STACK_STEP;
            mem_we <= 0;
            mem_beg <= 1;
            stack_top <= stack_top - `STACK_STEP;
            while (!mem_wrd && working) begin
              @(posedge clk);
            end;
            @(posedge clk);
            arg_right <= tmp_data_reg_in;
            
            // reading left arg -------------------------------
            tmp_addr <= stack_top - `STACK_STEP;
            mem_we <= 0;
            mem_beg <= 1;
            while (!mem_wrd && working) begin
              @(posedge clk);
            end;
            @(posedge clk);
            arg_left <= tmp_data_reg_in;
            tmp_data_reg_out <= tmp_data_reg_in * arg_right;
            // saving the result -----------------------------
            mem_we <= 1;
            mem_beg <= 1;
            while (!mem_wrd && working) begin
              @(posedge clk);
            end;
          
            $display("[%0t] MUL %d*%d=%d", $time, tmp_data_reg_in, arg_right, tmp_data_reg_in * arg_right);
          end
          6'b000110: begin // SUB
            $display("[%0t] SUB BEGIN", $time);
            // reading right arg -------------------------------
            tmp_addr <= stack_top - `STACK_STEP;
            mem_we <= 0;
            mem_beg <= 1;
            stack_top <= stack_top - `STACK_STEP;
            @(posedge clk);
            while (!mem_wrd && working) begin
              @(posedge clk);
            end;
            arg_right <= tmp_data_reg_in;
            
            // reading left arg -------------------------------
            tmp_addr <= stack_top - `STACK_STEP;
            mem_we <= 0;
            mem_beg <= 1;
            @(posedge clk);
            while (!mem_wrd && working) begin
              @(posedge clk);
            end;
            arg_left <= tmp_data_reg_in;
            tmp_data_reg_out <= tmp_data_reg_in - arg_right;
            // saving the result -----------------------------
            mem_we <= 1;
            mem_beg <= 1;
            @(posedge clk);
            while (!mem_wrd && working) begin
              @(posedge clk);
            end;
          
            $display("[%0t] SUB %d-%d=%d", $time, tmp_data_reg_in, arg_right, tmp_data_reg_in - arg_right);
          end

          6'b001000: begin // GT
            // reading right arg -------------------------------
            tmp_addr <= stack_top - `STACK_STEP;
            mem_we <= 0;
            mem_beg <= 1;
            stack_top <= stack_top - `STACK_STEP;
            while (!mem_wrd && working) begin
              @(posedge clk);
            end;
            @(posedge clk);
            arg_right <= tmp_data_reg_in;
            
            // reading left arg -------------------------------
            tmp_addr <= stack_top - `STACK_STEP;
            mem_we <= 0;
            mem_beg <= 1;
            while (!mem_wrd && working) begin
              @(posedge clk);
            end;
            arg_left <= tmp_data_reg_in;
            
            tmp_data_reg_out <= (tmp_data_reg_in > arg_right ? 1 : 0);
            // saving the result -----------------------------
            mem_we <= 1;
            mem_beg <= 1;
            while (!mem_wrd && working) begin
              @(posedge clk);
            end;
          
            $display("[%0t] GT %d>%d=%d", $time, tmp_data_reg_in, arg_right, tmp_data_reg_out);
          end

          6'b001001: begin // ASSIGN
            // reading right arg (value) -------------------------------
            tmp_addr <= stack_top - `STACK_STEP;
            mem_we <= 0;
            mem_beg <= 1;
            stack_top <= stack_top - `STACK_STEP;
            while (!mem_wrd && working) begin
              @(posedge clk);
            end;
            @(posedge clk);
            mem_beg <= 0;
            @(posedge clk);
            arg_right <= tmp_data_reg_in;
            
            // reading left arg (addr) -------------------------------
            tmp_addr <= stack_top - `STACK_STEP;
            mem_we <= 0;
            mem_beg <= 1;
            while (!mem_wrd && working) begin
              @(posedge clk);
            end;
            @(posedge clk);
            @(posedge clk);
            
            tmp_addr <= tmp_data_reg_in;
            tmp_data_reg_out <= arg_right;

            @(posedge clk);
           
            // saving the result -----------------------------

            mem_we <= 1;
            while (!mem_wrd && working) begin
              @(posedge clk);
            end;
            @(posedge clk);
            mem_we <= 0;

            // and to the top of stack
            tmp_addr <= stack_top - `STACK_STEP;
            @(posedge clk);
            mem_we <= 1;
            @(posedge clk);
            while (!mem_wrd && working) begin
              @(posedge clk);
            end;
            @(posedge clk);
            mem_we <= 0;

            $display("[%0t] ASSIGN *(%d)=%d", $time, arg_left, tmp_data_reg_out);
          end

          6'b001010: begin // locpush
            tmp_addr <= stack_top;
            tmp_data_reg_out[`STACK_MEM_DATA_WIDTH:`INSTR_WIDTH] <= 0;
            tmp_data_reg_out[`INSTR_WIDTH-1:0] <= cur_args[0] + fp_in;
            $display("[%0t] LOCPUSH BEG", $time);

            mem_beg <= 1;
            mem_we <= 1;
            while (!mem_wrd && working) begin
              @(posedge clk);
            end;
            stack_top <= stack_top + `STACK_STEP;
            
            $display("[%0t] LOCPUSH %d", $time, tmp_data_reg_out);
          end

          6'b001011: begin // EQ
            $display("[%0t] EQ BEG", $time);

            // reading right arg -------------------------------
            tmp_addr <= stack_top - `STACK_STEP;
            mem_we <= 0;
            mem_beg <= 1;
            stack_top <= stack_top - `STACK_STEP;
	    @(posedge clk);
            while (!mem_wrd && working) begin
              @(posedge clk);
            end;
            arg_right <= tmp_data_reg_in;
            
            // reading left arg -------------------------------
            tmp_addr <= stack_top - `STACK_STEP;
            mem_we <= 0;
            mem_beg <= 1;
	    @(posedge clk);
            while (!mem_wrd && working) begin
              @(posedge clk);
            end;
            arg_left <= tmp_data_reg_in;
            tmp_data_reg_out <= (tmp_data_reg_in == arg_right ? 1 : 0);
            // saving the result -----------------------------
            mem_we <= 1;
            mem_beg <= 1;
	    tmp_addr <= stack_top - `STACK_STEP;
	    @(posedge clk);
            while (!mem_wrd && working) begin
              @(posedge clk);
            end;
          
            $display("[%0t] EQ %d==%d=%d", $time, tmp_data_reg_in, arg_right, tmp_data_reg_out);
          end
          
          default: begin
            $display("[%0t] ILLEGAL XF INSTR %d", $time, cur_instr);
          end 
        endcase
        //$display("[%0t] EXEC opcode=0x%0h nargs=%d arg=%d", $time, cur_instr, cur_arg, cur_arg ? cur_args[0] : 0);
      end
      fifo_rd <= 1;
      $display("[%0t] let read fifo after instr=%x", $time, fifo_data);
    end
  end

  always @ (negedge clk) begin
    fifo_rd <= 0;
    mem_beg <= 0;
//    mem_we <= 0;
    stop <= 0;
    done <= 0;
  end;

endmodule