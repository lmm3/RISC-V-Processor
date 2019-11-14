
module controlUnit_tb;
	localparam CLKPERIOD = 10;
	localparam CLKDELAY = CLKPERIOD /2;

	logic clk;
	logic reset;
	logic PcWrite;
	logic IMemRead;
	logic DMemRead;
	logic IrWrite;
	logic WriteReg;
	logic LoadRegA;
	logic AluSrcA;
	logic LoadRegB;
	logic [1:0] AluSrcB;
	logic MemToReg;
	logic LoadAOut;
	logic LoadMDR;
	logic PCSrc;
	logic [2:0] SEFct;
	logic [2:0] AluFct;
	logic [1:0] state_out;

	controlUnit dut(
		.clk(clk),
		.reset(reset),
		.PcWrite(PcWrite),
		.IMemRead(IMemRead),
		.DMemRead(DMemRead),
		.IrWrite(IrWrite),
		.WriteReg(WriteReg),
		.LoadRegA(LoadRegA) ,
		.AluSrcA(AluSrcA),
		.LoadRegB(LoadRegB),
		.AluSrcB(AluSrcB),
		.MemToReg(MemToReg),
		.LoadAOut(LoadAOut),
		.LoadMDR(LoadMDR),
		.PCSrc(PCSrc),
		.SEFct(SEFct),
		.AluFct(AluFct),
		.state_out(state_out)
	);

	initial clk = 1'b1;

	always #(CLKDELAY) clk = ~clk;

	initial begin
		reset = 1;
		#(CLKPERIOD)
		reset = 0;
	end

endmodule // controlUnit_tb