`include "common.h"

module executer_cf (
   input wire reset,
   output logic reset_done,
   input wire	clk,

   input wire	do_it,
   output logic done,
   
   output logic stop,
   output logic goto,
   output logic [`DECODER_MEM_ADDR_WIDTH-1:0] new_addr,
   
   // FIFO
   input  wire	fifo_rd_done,
   output logic fifo_rd,
   input  wire	[`FIFO_ITEM_WIDTH-1:0] fifo_data,
   
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
   output reg [`STACK_MEM_ADDR_WIDTH-1:0] tos_out, // Top Of Stack

   // FP
   input wire [`STACK_MEM_ADDR_WIDTH-1:0] fp_in, // Frame Pointer
   output logic [`STACK_MEM_ADDR_WIDTH-1:0] fp_out // Frame Pointer
  );


  wire [`STACK_MEM_DATA_WIDTH-1:0] tmp_data_out;
  reg [`STACK_MEM_DATA_WIDTH-1:0] tmp_data_reg_in;
  reg [`STACK_MEM_DATA_WIDTH-1:0] tmp_data_reg_out;

  reg [`STACK_MEM_DATA_WIDTH-1:0] tmp_addr;
  reg [`STACK_MEM_DATA_WIDTH-1:0] stack_top;
  reg [`STACK_MEM_DATA_WIDTH-1:0] stack_fp;

  // ret stuff
  reg [`STACK_MEM_DATA_WIDTH-1:0] old_fp;
  reg [`STACK_MEM_DATA_WIDTH-1:0] old_sp;
  reg [`STACK_MEM_DATA_WIDTH-1:0] old_ip;
  reg [`STACK_MEM_DATA_WIDTH-1:0] tos_val;


  assign mem_oe = 1'b1;
  assign mem_addr[`STACK_MEM_ADDR_WIDTH-1:0] = tmp_addr[`STACK_MEM_ADDR_WIDTH + 1 : 2];
  assign mem_data_out = tmp_data_reg_out;
  assign tmp_data_reg_in = mem_data_in;
  
  assign tos_out = stack_top;
  assign fp_out = stack_fp;

  reg working;
  reg has_smth;
  reg exec_waiting;
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
    //new_addr <= 0;
    start_xf <= 0;
    
    working <= 0;
    done <= 0;
    reset_done <= 1;
  end;

  always @ (posedge do_it) begin
    working <= 1;
    stack_top <= tos_in;
    stack_fp <= fp_in;
    fifo_rd <= 1;
    $display("[%0t] let's go it CF", $time );
  end;
                      
  always @ (posedge fifo_rd_done) begin
    
    //$display("[%0t] fifo_rd_done %x %d", $time, stop, working);
    if (!stop && working) begin
      $display("[%0t] FIFO read %x %d", $time, fifo_data, nargs);

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

      $display("[%0t] has_smth=%d cur_instr=%d start_xf=%d nargs=%d", $time, has_smth, cur_instr, start_xf, nargs);
     
      if (has_smth && cur_instr == 0) begin
        stop <= 1'b1;
        done <= 1'b1;
      end else if (!start_xf && has_smth && nargs == 0) begin
        case (cur_instr[7:2])
          6'b000001: // EXEC
          begin
            tmp_addr <= stack_top;
            tmp_data_reg_out[`STACK_MEM_DATA_WIDTH:`FIFO_ITEM_WIDTH] <= 0;
            tmp_data_reg_out[`FIFO_ITEM_WIDTH-1:0] = cur_args[0];

            $display("[%0t] EXEC %d", $time, cur_args[0]);
            start_xf <= 1;
            addr_xf <= cur_args[0];
	    exec_waiting <= 1;
            @(posedge clk);
            
            while (exec_waiting && working) begin
              $display("[%0t] EXEC waiting %d %d", $time, done_xf, working);
              @(posedge clk);
            end;
            start_xf <= 0;
            stack_top <= tos_in;
      	    fifo_rd <= 1;
            
            $display("[%0t] EXECUTED %d", $time, cur_args[0]);
          end
          
          6'b000010: begin // IF2
            $display("[%0t] START IF", $time);

            tmp_addr <= stack_top - `STACK_STEP;
            mem_we <= 0;
            mem_beg <= 1;
            @(posedge clk);
            while (!mem_wrd && working) begin
              @(posedge clk);
            end;

            stack_top <= stack_top - `STACK_STEP;
            @(posedge clk);

            if (tmp_data_reg_in == 0) begin
              new_addr <= cur_args[0];
              goto <= 1;
              done <= 0;
	    end else begin
      	      fifo_rd <= 1;
            end
              

            $display("[%0t] IF(%d) %d = %d", $time, tmp_addr, tmp_data_reg_in, cur_args[0]);
          end
          
          6'b000011: begin // GOTO
            $display("[%0t] START GOTO ", $time);
            tmp_addr <= stack_top - `STACK_STEP;
            mem_we <= 0;
            mem_beg <= 1;
            @(posedge clk);
            while (!mem_wrd && working) begin
              @(posedge clk);
            end;

            if (tmp_data_reg_in != 0) begin
              new_addr <= cur_args[0];
              goto <= 1;
              done <= 0;
            end
              
            $display("[%0t] GOTO %d", $time, new_addr);
          end
          
          6'b000100: begin // CALL           
            // saving the result -----------------------------
            $display("[%0t] CALL BEGIN %d %d %d %d", $time, cur_args[0], cur_args[1], cur_args[2], cur_addr);
            tmp_addr <= stack_top + cur_args[2];  // jump over local args
            tmp_data_reg_out <= cur_addr; // old IP
            mem_we <= 1;
            mem_beg <= 1;
            @(posedge clk);
            while (!mem_wrd && working) begin
              @(posedge clk);
            end;
            
            tmp_addr <= tmp_addr + `STACK_STEP;  
            tmp_data_reg_out <= fp_in; // old FP
            mem_we <= 1;
            mem_beg <= 1;
            @(posedge clk);
            while (!mem_wrd && working) begin
              @(posedge clk);
            end;
            
            tmp_addr <= tmp_addr + `STACK_STEP;  
            tmp_data_reg_out <= stack_top - cur_args[1]; // old SP
            mem_we <= 1;
            mem_beg <= 1;
            @(posedge clk);
            while (!mem_wrd && working) begin
              @(posedge clk);
            end;

            stack_fp <= stack_top - cur_args[1];
            stack_top <= stack_top + cur_args[2] + 3 * `STACK_STEP; // local_vars + SP + FP + IP
//            @(posedge clk);
            new_addr <= cur_args[0];
            //tos_out <= stack_top;
            //fp_out <= stack_top;
            goto <= 1;
            done <= 0;
            $display("[%0t] CALL %d %d %d ret=%d", $time, cur_args[0], cur_args[1], cur_args[2], cur_addr);
            //break;
            
          end
          
          6'b000101: begin // RET

            $display("[%0t] RET START", $time);
            tmp_addr <= stack_top - `STACK_STEP;
            mem_we <= 0;
            mem_beg <= 1;
            @(posedge clk);
            while (!mem_wrd && working) begin
              @(posedge clk);
            end;
	    tos_val <= mem_data_in;

            tmp_addr <= stack_top - 2 * `STACK_STEP;
            mem_we <= 0;
            mem_beg <= 1;
            @(posedge clk);
            while (!mem_wrd && working) begin
              @(posedge clk);
            end;
	    old_sp <= mem_data_in;

            tmp_addr <= stack_top - 3 * `STACK_STEP;
            mem_we <= 0;
            mem_beg <= 1;
            @(posedge clk);
            while (!mem_wrd && working) begin
              @(posedge clk);
            end;
	    old_fp <= mem_data_in;

            tmp_addr <= stack_top - 4 * `STACK_STEP;
            mem_we <= 0;
            mem_beg <= 1;
            @(posedge clk);
            while (!mem_wrd && working) begin
              @(posedge clk);
            end;
	    old_ip <= mem_data_in;

            @(posedge clk);
            new_addr <= old_ip;
	    stack_fp <= old_fp;
	    stack_top <= old_sp;
            @(posedge clk);

            $display("[%0t] RET: sp=%d ip=%d fp=%d val=%d", $time, old_sp, old_ip, old_fp, tos_val);

	    tmp_data_reg_out <= tos_val;
            tmp_addr <= stack_top;
            mem_we <= 1;
            mem_beg <= 1;
            while (!mem_wrd && working) begin
              @(posedge clk);
            end;

	    stack_top <= stack_top + `STACK_STEP;
            goto <= 1;
            done <= 0;

            $display("[%0t] RET", $time);
          end

       	  default: begin

            $display("[%0t] ILLEGAL CF INSTR %d", $time, cur_instr);
	        end 
        endcase
        //$display("[%0t] EXEC opcode=0x%0h nargs=%d arg=%d", $time, cur_instr, cur_arg, cur_arg ? cur_args[0] : 0);
      end else begin
    	fifo_rd <= 1;
      end
    end
    //$display("[%0t] <<", $time);
  end

  always @ (negedge clk) begin
    fifo_rd <= 0;
    stop <= 0;
    goto <= 0;
    done <= 0;
    mem_beg <= 0;
  end;

  always @ (negedge done_xf) begin
    exec_waiting <= 0;
  end;

endmodule