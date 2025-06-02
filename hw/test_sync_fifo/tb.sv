`include "common.h"

module tb;

  reg 	 		clk;
  reg [15:0]    din;
  wire [15:0] 	dout;
  reg 			empty;
  reg 			rd_en;
  reg 			wr_en;
  wire 			full;
  reg 			reset;
  reg 			stop;

  sync_fifo #(.DWIDTH(`INST_WIDTH)) u_sync_fifo 
			(.reset(reset),
                         .wr_en(wr_en),
                         .rd_en(rd_en),
                         .clk(clk),
                         .din(din),
                         .dout(dout),
                         .empty(empty),
                         .full(full)
                        );

  always #10 clk <= ~clk;

  initial begin
    clk 	<= 0;
    reset 	<= 1;
    wr_en 	<= 0;
    rd_en 	<= 0;
    stop  	<= 0;

    #20 reset <= 0;
  end

  initial begin
    @(posedge clk);

    for (int i = 0; i < 20; i = i+1) begin

      // Wait until there is space in fifo
      while (full) begin
      	@(posedge clk);
        $display("[%0t] FIFO is full, wait for reads to happen", $time);
      end;

      // Drive new values into FIFO
      wr_en <= 1'b1;
      din 	<= $random;
      $display("[%0t] clk i=%0d wr_en=%0d din=0x%0h ", $time, i, wr_en, din);

      // Wait for next clock edge
      @(posedge clk);
    end

     wr_en <= 1'b0;
    repeat (200) @ (posedge clk);

    stop = 1;
  end

  initial begin
    @(posedge clk);

    while (!stop) begin
      // Wait until there is data in fifo
      while (empty) begin
        rd_en <= 0;
        $display("[%0t] FIFO is empty, wait for writes to happen", $time);
        @(posedge clk);
      end;

      // Sample new values from FIFO at random pace
      rd_en <= $random;//1'b1;
      @(posedge clk);
      //rdata <= dout;
      $display("[%0t] clk rd_en=%0d rdata=0x%0h ", $time, rd_en, dout);
    end

    #500 $finish;
  end
endmodule