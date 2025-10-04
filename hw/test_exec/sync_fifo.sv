module sync_fifo #(parameter DEPTH=8, DWIDTH=16)
(
        input               	reset,      // Active low reset
                            	clk,         // Clock
                            	wr_en, 		    // Write enable
                            	rd_en, 		    // Read enable
        input      [DWIDTH-1:0] din, 	    // Data written into FIFO
        output reg [DWIDTH-1:0] dout,     // Data read from FIFO
        output logic        	rd_done,
                            	wr_done
);

  reg [DWIDTH-1 : 0]    fifo[DEPTH];

  reg [$clog2(DEPTH)-1:0]   wptr;
  reg [$clog2(DEPTH)-1:0]   rptr;

  wire empty, full;
  assign full  = (wptr + 1) == rptr;
  assign empty = wptr == rptr;

  always @ (posedge reset) begin
      wptr <= 0;
      rptr <= 0;
  end

  always @ (posedge wr_en) begin

    while (full) begin
        @(posedge clk);
    end;

    fifo[wptr] <= din;
    wptr <= wptr + 1;
    wr_done <= 1;
    
  end

  always @ (posedge rd_en) begin

    while (empty) begin
        @(posedge clk);
    end;

    dout <= fifo[rptr];
    rptr <= rptr + 1;
    rd_done <= 1;

  end

  always @ (negedge clk) begin
    rd_done <= 0;
    wr_done <= 0;
  end
  
endmodule
