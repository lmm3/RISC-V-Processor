module processor(
	input logic clk,
	input logic reset,
	output logic [63:0] PCData,
	output logic [31:0] Mem32Out,
	output logic [63:0] Mem64Out,
	output logic [63:0] MDRData,
	output logic [4:0]	i19_15,//rs1
	output logic [4:0]	i24_20,//rs2
	output logic [4:0]	i11_7,//rd
	output logic [6:0]	i6_0, //opcode
	output logic [31:0] i31_0,
	output logic [63:0] AData,
	output logic [63:0] BData,
	output logic [63:0] SEResult,
	output logic [63:0] ShiftLeft1Result,
	output logic [63:0] GeneralShiftResult,
	output logic [63:0] LoadSelResult,
	output logic [63:0] StoreSelResult,
	output logic [63:0] MuxAOut,
	output logic [63:0] MuxBOut,
	output logic [63:0] MuxRegOut,
	output logic [63:0] MuxPCOut,
	output logic [63:0] AluResult,
	output logic [63:0] AluOutData,
	output logic [6:0] state_out
	);
	

	logic [2:0] AluFct; //Operacao da Ula
	logic [2:0] SEFct;	//Operacao do SignExtend
	logic [2:0] MemToReg;
	logic [1:0] AluSrcA;
	logic [1:0] AluSrcB;
	logic [63:0] RegSrc1;
	logic [63:0] RegSrc2;
	logic [1:0] ShiftType;
	logic [2:0] LoadType;
	logic [1:0] StoreType;
	logic [1:0] BranchType;


	controlUnit UC(
		.clk(clk),
		.reset(reset),
		.opcode(i6_0),
		.instruction(i31_0),
		.PcWrite(PcWrite),
		.IMemRead(IMemRead),
		.DMemRead(DMemRead),
		.IrWrite(IrWrite),
		.WriteReg(WriteReg),
		.LoadRegA(LoadRegA),
		.AluSrcA(AluSrcA),
		.LoadRegB(LoadRegB),
		.AluSrcB(AluSrcB),
		.MemToReg(MemToReg),
		.LoadAOut(LoadAOut),
		.LoadMDR(LoadMDR),
		.PCSrc(PCSrc),
		.SEFct(SEFct),
		.AluFct(AluFct),
		.PcWriteCond(PcWriteCond),
		.ShiftType(ShiftType),
		.BranchType(BranchType),
		.LoadType(LoadType),
		.StoreType(StoreType),
		.state_out(state_out)
		);

	or Ou(
		OuOut,
		BranchResult,
		PcWrite
		);

	BranchSelector BS(
		.zero(zero),
		.lessThan(lessThan),
		.BranchType(BranchType),
		.PcWriteCond(PcWriteCond),
		.BranchResult(BranchResult)
		);

	LoadSizeSelector LS(
		.MemDataIn(Mem64Out),
		.LoadType(LoadType),
		.LoadSelResult(LoadSelResult)
		);

	StoreSizeSelector SS(
		.MemDataOut(Mem64Out),
		.StoreSizeIn(BData),
		.StoreType(StoreType),
		.StoreSelResult(StoreSelResult)
		);

	mux2in muxPC(
		.first(AluResult),
		.second(AluOutData),
		.sel(PCSrc),
		.result(MuxPCOut)
		);

	mux2in muxA(
		.first(PCData),
		.second(AData),
		.sel(AluSrcA),
		.result(MuxAOut)
		);

	mux6in muxReg(
		.first(AluOutData),
		.second(MDRData),
		.third (SEResult),
		.fourth({63'd0, lessThan}),
		.fifth(GeneralShiftResult),
		.sixth(PCData),
		.sel(MemToReg),
		.result(MuxRegOut)
		);

	mux4in muxB(
		.first(BData),
		.second(64'd4),
		.third(SEResult),
		.fourth(ShiftLeft1Result),
		.sel(AluSrcB),
		.result(MuxBOut)
		);

	Memoria32 IstructionMemory(
		.raddress(PCData[31:0]),
		.Clk(clk),
		.Dataout(Mem32Out),
		.Wr(IMemRead)
		);

	Memoria64 DataMemory(
		.raddress(AluOutData),
		.waddress(AluOutData),
		.Clk(clk),
		.Datain(StoreSelResult),
		.Dataout(Mem64Out),
		.Wr(DMemRead)
		);

	Ula64 Alu(
		.A(MuxAOut),
		.B(MuxBOut),
		.Seletor(AluFct),
		.S(AluResult),
		.z(zero),
		.Menor(lessThan)
		);

	Deslocamento ShiftLeft1(
		.Shift(2'd0),
		.Entrada(SEResult),
		.N(6'd1),
		.Saida(ShiftLeft1Result)
		);

	Deslocamento GeneralShift(
		.Shift(ShiftType),
		.Entrada(AData),
		.N(i31_0[25:20]),
		.Saida(GeneralShiftResult)
		);

	signExtend immediateExtender(
		.instruction(i31_0),
		.sel_type   (SEFct),
		.extension  (SEResult)
		);

	bancoReg Registers64(
		.write(WriteReg),
		.clock(clk),
		.reset(reset),
		.regreader1(i19_15),
		.regreader2(i24_20),
		.regwriteaddress(i11_7),
		.datain(MuxRegOut),
		.dataout1(RegSrc1),
		.dataout2(RegSrc2)
		);

	register PC(
		.clk(clk),
		.reset(reset),
		.regWrite(OuOut),
		.DadoIn(MuxPCOut),
		.DadoOut(PCData)
		);

	register RegA(
		.clk(clk),
		.reset(reset),
		.regWrite(LoadRegA),
		.DadoIn(RegSrc1),
		.DadoOut(AData)
		);

	register RegB(
		.clk(clk),
		.reset(reset),
		.regWrite(LoadRegB),
		.DadoIn(RegSrc2),
		.DadoOut(BData)
		);

	register AluOut(
		.clk(clk),
		.reset(reset),
		.regWrite(LoadAOut),
		.DadoIn(AluResult),
		.DadoOut(AluOutData)
		);

	register MemDataRegister(
		.clk(clk),
		.reset(reset),
		.regWrite(LoadMDR),
		.DadoIn(LoadSelResult),
		.DadoOut(MDRData)
		);

	Instr_Reg_RISC_V Instr_Reg(
		.Clk(clk),
		.Reset(reset),
		.Load_ir(IrWrite),
		.Entrada(Mem32Out),
		.Instr19_15(i19_15),
		.Instr24_20(i24_20),
		.Instr11_7(i11_7),
		.Instr6_0(i6_0),
		.Instr31_0(i31_0)
		);

endmodule // processor