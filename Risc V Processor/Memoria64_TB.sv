`timescale 1ps/1ps

module Memoria64_TB;
	localparam CLKPERIOD = 10;
	localparam CLKDELAY = CLKPERIOD /2;


	logic  [63:0]raddress;
    logic  [63:0]waddress;
    logic  Clk;
    logic  [63:0]Datain;
    logic  [63:0]Dataout;
    logic  Wr;

    Memoria64 dut(
    	.raddress(raddress),
    	.waddress(waddress),
    	.Clk     (Clk),
    	.Datain  (Datain),
    	.Dataout (Dataout),
    	.Wr      (Wr)
    	);

    initial begin
    	Clk = 1'b1;
    	raddress = 0;
    	waddress = 0;
    	Datain = 64'hFFFFFFFFFFFFFFFF;
    	Wr = 1;
    end

	always #(CLKDELAY) Clk = ~Clk;

endmodule // Memoria64_TB