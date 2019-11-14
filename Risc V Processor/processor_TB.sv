`timescale 1ps/1ps

module processor_TB;
	localparam CLKPERIOD = 10;
	localparam CLKDELAY = CLKPERIOD /2;

	logic clk;
	logic reset;
	logic [63:0] PCData;
	logic [31:0] Mem32Out;
	logic [63:0] Mem64Out;
	logic [63:0] MDRData;
	logic [4:0] rs1;//rs1
	logic [4:0]	rs2;//rs2
	logic [4:0]	rd;//rd
	logic [6:0]	opcode; //opcode
	logic [31:0] instruction;
	logic [63:0] AData;
	logic [63:0] BData;
	logic [63:0] SEResult;
	logic [63:0] ShiftLeft1Result;
	logic [63:0] GeneralShiftResult;
	logic [63:0] LoadSelResult;
	logic [63:0] StoreSelResult;
	logic [63:0] MuxAOut;
	logic [63:0] MuxBOut;
	logic [63:0] MuxRegOut;
	logic [63:0] MuxPCOut;
	logic [63:0] AluResult;
	logic [63:0] AluOutData;
	logic [6:0]state_out;
 
	
	processor dut(
		.clk(clk),
		.reset(reset),
		.PCData(PCData),
		.Mem32Out(Mem32Out),
		.Mem64Out(Mem64Out),
		.MDRData(MDRData),
		.i19_15(rs1),
		.i24_20(rs2),
		.i11_7(rd),
		.i6_0(opcode),
		.i31_0(instruction),
		.AData(AData),
		.BData(BData),
		.SEResult(SEResult),
		.ShiftLeft1Result(ShiftLeft1Result),
		.GeneralShiftResult(GeneralShiftResult),
		.LoadSelResult(LoadSelResult),
		.StoreSelResult(StoreSelResult),
		.MuxAOut(MuxAOut),
		.MuxBOut(MuxBOut),
		.MuxRegOut(MuxRegOut),
		.MuxPCOut(MuxPCOut),
		.AluResult(AluResult),
		.AluOutData(AluOutData),
		.state_out(state_out)
	);

	initial begin
		clk = 1'b1;
		reset = 1'b1;
		#(CLKPERIOD)
		reset = ~reset;
	end

	always #(CLKDELAY) clk = ~clk;

endmodule // processor_TB