//PAREI NOS BRANCHES

module controlUnit(
	input logic clk,					//Clock (Geral)
	input logic reset,					//Reset (Geral)
	input logic [6:0] opcode,			//Opcode da Instrução
	input logic [31:0] instruction,		//Instrução Completa  
	output logic PcWrite,				//Condição de escrita do registrador PC
	output logic IMemRead,				//Condição de escrita/leitura da memória de instrução (0 = somente leitura; 1 = leitura e escrita)
	output logic DMemRead,				//Condição de escrita/leitura da memória de dados (0 = somente leitura; 1 = leitura e escrita)
	output logic IrWrite,				//Condição de escrita do registrador de Instrução 
	output logic WriteReg,				//Condição de escrita no rd (Register Destination) do Banco de Registradores	
	output logic LoadRegA,				//Condição de escrita do registrador A
	output logic [1:0] AluSrcA,			//Seleção do Mux A
	output logic LoadRegB,				//Condição de escrita do registrador B
	output logic [1:0] AluSrcB,			//Seleção do Mux B
	output logic [2:0] MemToReg,		//Seleção do Mux MemToReg
	output logic LoadAOut,				//Condição de escrita do registrador AluOut
	output logic LoadMDR,				//Condição de escrita do Memory Data Register 
	output logic PCSrc,					//Seleção do Mux PCSrc
	output logic [2:0] SEFct,			//Seleção do tipo para extensão do immediate no módulo SignExtend 
	output logic [2:0] AluFct,			//Seleção da operação a ser realizada na ULA 
	output logic PcWriteCond,			//Condicional dos branchs
	output logic [1:0] ShiftType,
	output logic [1:0] BranchType,		//Flag que dita o tipo do branch a ser dado(0 para BEQ, 1 para BNE)	
	output logic [2:0] LoadType,
	output logic [1:0] StoreType,
	output logic [6:0] state_out);		//Variável para mostrar o estado atual da máquina

	enum bit [6:0] { //Estados da máquina
	FETCH = 0, 
	INSTRUCTION_WRITE = 1,
	DECODE = 2,
	ADD_ARITHMETIC = 3,
	SUB_ARITHMETIC = 4,
	AND_LOGIC = 5,
	SLT_COMPARISON_WRITE_IN_REGISTER = 6,
	ADDI_ARITHMETIC = 7,
	SLTI_COMPARISON_WRITE_IN_REGISTER = 8,
	LD_ARITHMETIC = 9,
	MEM_64_LOAD_REQUISITION = 10,
	MEM_64_STORE_REQUISITION = 11,
	MDR_WRITE_LB = 12,
	MDR_WRITE_LH = 13,
	MDR_WRITE_LW = 14,
	MDR_WRITE_LD = 15,
	MDR_WRITE_LBU = 16,
	MDR_WRITE_LHU = 17,
	MDR_WRITE_LWU = 18,
	SRLI_WRITE_IN_REGISTER = 19,
	SRAI_WRITE_IN_REGISTER =20,
	SLLI_WRITE_IN_REGISTER = 21,
	SD_ARITHMETIC = 22,
	BEQ_COMPARISON = 23,
	BNE_COMPARISON = 24,
	BGE_COMPARISON = 25,
	BLT_COMPARISON = 26,
	LUI_STORE_IN_REG = 27,
	SB_MEM_64_WRITE = 28,
	SH_MEM_64_WRITE = 29,
	SW_MEM_64_WRITE = 30,
	SD_MEM_64_WRITE = 31,
	WRITE_IN_REGISTER_ALU = 32,
	WRITE_IN_REGISTER_MEM= 33,
	BREAK_EXECUTION = 34,
	JAL_WRITE_IN_REGISTER = 35,
	JALR_WRITE_IN_REGISTER = 36
	} state , next_state;

	parameter SIGN_R = 0, //parametros do SEFct
	SIGN_I = 1,
	SIGN_S = 2, 
	SIGN_SB = 3, 
	SIGN_U = 4,
	SIGN_UJ = 5;

	parameter BEQ_TYPE = 0,
	BNE_TYPE = 1,
	BGE_TYPE = 2,
	BLT_TYPE = 3,
	NO_BRANCH = 5;

	parameter LB_TYPE = 0, //parametros dos Loads
	LH_TYPE = 1,
	LW_TYPE = 2,
	LD_TYPE = 3,
	LBU_TYPE = 4,
	LHU_TYPE = 5,
	LWU_TYPE = 6;

	parameter SB_TYPE = 0,
	SH_TYPE = 1,
	SW_TYPE = 2,
	SD_TYPE = 3;

	parameter PASS_ULA = 3'b000, //parametros da Ula
	SUM_ULA = 3'b001,
	SUB_ULA = 3'b010,
	AND_ULA = 3'b011,
	INC_ULA = 3'b100,
	NOT_ULA = 3'b101,
	XOR_ULA= 3'b110,
	CMP_ULA = 3'b111;

	parameter SHIFT_LEFT_L = 0,
	SHIFT_RIGHT_L = 1,
	SHIFT_RIGHT_A = 2,
	SHIFT_PASS = 3;

	parameter R_TYPE = 7'b0110011, //paramtros do opcode
	I_TYPE = 7'b0010011,
	LOAD_TYPE = 7'b0000011,
	STORE_TYPE = 7'b0100011,
	BRANCH_EQUAL_TYPE = 7'b1100011,
	BRANCH_NON_EQUAL_TYPE = 7'b1100111,
	U_TYPE = 7'b0110111,
	BREAK_TYPE = 7'b1110011,
	UJ_TYPE = 7'b1101111,
	JALR_TYPE = 7'b1100111;

	always_ff @(posedge clk or posedge reset) begin
		if(reset) 
			state <= FETCH;
		else
			state <= next_state;
	end

	always_comb begin 
		case(state)
			
			FETCH: begin		//Faz a requisição a memória de Instrução com o endereço guardado em PC
				PcWrite = 0; 
				IMemRead = 0; 
				DMemRead = 0;
				IrWrite = 0; 
				WriteReg = 0; 
				LoadRegA = 0; 
				AluSrcA = 0; 
				LoadRegB = 0; 
				AluSrcB = 1; 
				MemToReg = 0;
				LoadAOut = 0;	
				LoadMDR = 0;
				PCSrc = 0;	
				SEFct = SIGN_R; 
				AluFct = PASS_ULA; 
				PcWriteCond = 0;
				ShiftType = SHIFT_PASS;
				BranchType = NO_BRANCH;
				LoadType = LD_TYPE;
				StoreType = SD_TYPE;
				next_state = INSTRUCTION_WRITE;	
			end //FETCH
			
			INSTRUCTION_WRITE:	begin	//Apos um ciclo de espera, escreve no Registrador de Instrução e faz PC = PC + 4
				PcWrite = 1;
				IMemRead = 0;
				DMemRead = 0;
				IrWrite = 1;
				WriteReg = 0;
				LoadRegA = 0;
				AluSrcA = 0;
				LoadRegB = 0;
				AluSrcB = 1;
				MemToReg = 0;
				LoadAOut = 0;
				LoadMDR = 0;
				PCSrc = 0;
				SEFct = SIGN_R;
				AluFct = SUM_ULA;
				PcWriteCond = 0;
				ShiftType = SHIFT_PASS;
				BranchType = NO_BRANCH;
				LoadType = LD_TYPE;
				StoreType = SD_TYPE;
				next_state = DECODE;
			end // INSTRUCTION_WRITE:
			
			DECODE: begin 		//Decodificação da Instrução, cálculo do Endereço de Branch(Resultado guardado em AluOut)
				PcWrite = 0;
				IMemRead = 0;				
				DMemRead = 0;
				IrWrite = 0;
				WriteReg = 0;
				LoadRegA = 1;
				AluSrcA = 0;
				LoadRegB = 1;
				AluSrcB = 3; 
				MemToReg = 0;
				LoadAOut = 1;
				LoadMDR = 0;
				PCSrc = 0;
				SEFct = SIGN_SB;
				AluFct = SUM_ULA;
				PcWriteCond = 0;
				ShiftType = SHIFT_PASS;
				BranchType = NO_BRANCH;
				LoadType = LD_TYPE;
				StoreType = SD_TYPE;
				
				case(opcode) 	//Decodificação da intrução para definir o proximo estado
					R_TYPE: begin
						if(instruction[31:25] == 0) begin
							if(instruction [14:12] == 0)
								next_state = ADD_ARITHMETIC;
							
							else if(instruction [14:12] == 7)
								next_state = AND_LOGIC;
							
							else
								next_state = SLT_COMPARISON_WRITE_IN_REGISTER;
						end
						
						else 
							next_state = SUB_ARITHMETIC;
					end // R_TYPE
					
					I_TYPE: begin
						if(instruction[14:12] == 0)
							next_state = ADDI_ARITHMETIC;
						
						else begin
							if(instruction[14:12] == 2)
								next_state = SLTI_COMPARISON_WRITE_IN_REGISTER;
							
							else if(instruction[14:12] == 5) begin
								if(instruction[31:26] == 0)
									next_state = SRLI_WRITE_IN_REGISTER;
								else
									next_state = SRAI_WRITE_IN_REGISTER;
							end

							else 
								next_state = SLLI_WRITE_IN_REGISTER;
						end
					end // I_TYPE
					
					JALR_TYPE:
						next_state = JALR_WRITE_IN_REGISTER;
					
					LOAD_TYPE:
						next_state = LD_ARITHMETIC;
					
					STORE_TYPE: 
						next_state = SD_ARITHMETIC;
					
					BRANCH_EQUAL_TYPE:
						next_state = BEQ_COMPARISON;
					
					BRANCH_NON_EQUAL_TYPE: begin
						if(instruction[14:12] == 1)
							next_state = BNE_COMPARISON;
						else if(instruction[14:12] == 4)
							next_state = BLT_COMPARISON;
						else
							next_state = BGE_COMPARISON;
					end

					U_TYPE: 
						next_state = LUI_STORE_IN_REG;

					BREAK_TYPE:
						next_state = BREAK_EXECUTION;
					
					UJ_TYPE:
						next_state = JAL_WRITE_IN_REGISTER;

					default: 
						next_state = FETCH;

				endcase//opcode
			end //DECODE
				
			ADD_ARITHMETIC: begin		//soma o conteudo de rs1 com o conteudo de rs2 e guarda o resultado em AluOut
				PcWrite = 0;
				IMemRead = 0;				
				DMemRead = 0;
				IrWrite = 0;
				WriteReg = 0;
				LoadRegA = 0;
				AluSrcA = 1;
				LoadRegB = 0;
				AluSrcB = 0; 
				MemToReg = 0;
				LoadAOut = 1;
				LoadMDR = 0;
				PCSrc = 0;
				SEFct = SIGN_R;
				AluFct = SUM_ULA;
				PcWriteCond = 0;
				ShiftType = SHIFT_PASS;
				BranchType = NO_BRANCH;
				LoadType = LD_TYPE;
				StoreType = SD_TYPE;
				next_state = WRITE_IN_REGISTER_ALU;
			end // ADD_ARITHMETIC
			
			SUB_ARITHMETIC: begin			//subtrai o conteudo de rs1 pelo conteudo de rs2 e guarda o resultado em AluOut
				PcWrite = 0;
				IMemRead = 0;				
				DMemRead = 0;
				IrWrite = 0;
				WriteReg = 0;
				LoadRegA = 0;
				AluSrcA = 1;
				LoadRegB = 0;
				AluSrcB = 0; 
				MemToReg = 0;
				LoadAOut = 1;
				LoadMDR = 0;
				PCSrc = 0;
				SEFct = SIGN_R;
				AluFct = SUB_ULA;
				PcWriteCond = 0;
				ShiftType = SHIFT_PASS;
				BranchType = NO_BRANCH;
				LoadType = LD_TYPE;
				StoreType = SD_TYPE;
				next_state = WRITE_IN_REGISTER_ALU;
			end // SUB_ARITHMETIC
			
			AND_LOGIC: begin			
				PcWrite = 0;
				IMemRead = 0;				
				DMemRead = 0;
				IrWrite = 0;
				WriteReg = 0;
				LoadRegA = 0;
				AluSrcA = 1;
				LoadRegB = 0;
				AluSrcB = 0; 
				MemToReg = 0;
				LoadAOut = 1;
				LoadMDR = 0;
				PCSrc = 0;
				SEFct = SIGN_R;
				AluFct = AND_ULA;
				PcWriteCond = 0;
				ShiftType = SHIFT_PASS;
				BranchType = NO_BRANCH;
				LoadType = LD_TYPE;
				StoreType = SD_TYPE;
				next_state = WRITE_IN_REGISTER_ALU;
			end // AND_LOGIC

			SLT_COMPARISON_WRITE_IN_REGISTER: begin
				PcWrite = 0;
				IMemRead = 0;				
				DMemRead = 0;
				IrWrite = 0;
				WriteReg = 0;
				LoadRegA = 0;
				AluSrcA = 1;
				LoadRegB = 0;
				AluSrcB = 0; 
				MemToReg = 3;
				LoadAOut = 0;
				LoadMDR = 0;
				PCSrc = 0;
				SEFct = SIGN_R;
				AluFct = CMP_ULA;
				PcWriteCond = 0;
				ShiftType = SHIFT_PASS;
				BranchType = NO_BRANCH;
				LoadType = LD_TYPE;
				StoreType = SD_TYPE;
				next_state = FETCH;
			end // SLT_COMPARISON_WRITE_IN_REGISTER

			ADDI_ARITHMETIC: begin			//soma o conteudo de rs1 com o immediate e guarda o resultado em AluOut
				PcWrite = 0;
				IMemRead = 0;				
				DMemRead = 0;
				IrWrite = 0;
				WriteReg = 0;
				LoadRegA = 0;
				AluSrcA = 1;
				LoadRegB = 0;
				AluSrcB = 2; 
				MemToReg = 0;
				LoadAOut = 1;
				LoadMDR = 0;
				PCSrc = 0;
				SEFct = SIGN_I;
				AluFct = SUM_ULA;
				PcWriteCond = 0;
				ShiftType = SHIFT_PASS;
				BranchType = NO_BRANCH;
				LoadType = LD_TYPE;
				StoreType = SD_TYPE;
				next_state = WRITE_IN_REGISTER_ALU;
			end // ADDI_ARITHMETIC

			SLTI_COMPARISON_WRITE_IN_REGISTER: begin
				PcWrite = 0;
				IMemRead = 0;				
				DMemRead = 0;
				IrWrite = 0;
				WriteReg = 1;
				LoadRegA = 0;
				AluSrcA = 1;
				LoadRegB = 0;
				AluSrcB = 2; 
				MemToReg = 3;
				LoadAOut = 0;
				LoadMDR = 0;
				PCSrc = 0;
				SEFct = SIGN_I;
				AluFct = CMP_ULA;
				PcWriteCond = 0;
				ShiftType = SHIFT_PASS;
				BranchType = NO_BRANCH;
				LoadType = LD_TYPE;
				StoreType = SD_TYPE;
				next_state = FETCH;
			end // SLTI_COMPARISON_WRITE_IN_REGISTER

			LD_ARITHMETIC: begin			//calcula o endereço para fazer leitura da memoria de dados  e guarda o resultado em AluOut
				PcWrite = 0;
				IMemRead = 0;				
				DMemRead = 0;
				IrWrite = 0;
				WriteReg = 0;
				LoadRegA = 0;
				AluSrcA = 1;
				LoadRegB = 0;
				AluSrcB = 2; 
				MemToReg = 0;
				LoadAOut = 1;
				LoadMDR = 0;
				PCSrc = 0;
				SEFct = SIGN_I;
				AluFct = SUM_ULA;
				PcWriteCond = 0;
				ShiftType = SHIFT_PASS;
				BranchType = NO_BRANCH;
				LoadType = LD_TYPE;
				StoreType = SD_TYPE;
				next_state = MEM_64_LOAD_REQUISITION;
			end //LD

			SLLI_WRITE_IN_REGISTER: begin
				PcWrite = 0;
				IMemRead = 0;				
				DMemRead = 0;
				IrWrite = 0;
				WriteReg = 1;
				LoadRegA = 0;
				AluSrcA = 1;
				LoadRegB = 0;
				AluSrcB = 0; 
				MemToReg = 3'b100;
				LoadAOut = 0;
				LoadMDR = 0;
				PCSrc = 0;
				SEFct = SIGN_R;
				AluFct = PASS_ULA;
				PcWriteCond = 0;
				ShiftType = SHIFT_LEFT_L;
				BranchType = NO_BRANCH;
				LoadType = LD_TYPE;
				StoreType = SD_TYPE;
				next_state = FETCH;
			end // SLLI_WRITE_IN_REGISTER:

			SRLI_WRITE_IN_REGISTER: begin
				PcWrite = 0;
				IMemRead = 0;				
				DMemRead = 0;
				IrWrite = 0;
				WriteReg = 1;
				LoadRegA = 0;
				AluSrcA = 1;
				LoadRegB = 0;
				AluSrcB = 0; 
				MemToReg = 3'b100;
				LoadAOut = 0;
				LoadMDR = 0;
				PCSrc = 0;
				SEFct = SIGN_R;
				AluFct = PASS_ULA;
				PcWriteCond = 0;
				ShiftType = SHIFT_RIGHT_L;
				BranchType = NO_BRANCH;
				LoadType = LD_TYPE;
				StoreType = SD_TYPE;
				next_state = FETCH;
			end // SRLI_WRITE_IN_REGISTER:

			SRAI_WRITE_IN_REGISTER: begin
				PcWrite = 0;
				IMemRead = 0;				
				DMemRead = 0;
				IrWrite = 0;
				WriteReg = 1;
				LoadRegA = 0;
				AluSrcA = 1;
				LoadRegB = 0;
				AluSrcB = 0; 
				MemToReg = 3'b100;
				LoadAOut = 0;
				LoadMDR = 0;
				PCSrc = 0;
				SEFct = SIGN_R;
				AluFct = PASS_ULA;
				PcWriteCond = 0;
				ShiftType = SHIFT_RIGHT_A;
				BranchType = NO_BRANCH;
				LoadType = LD_TYPE;
				StoreType = SD_TYPE;
				next_state = FETCH;
			end // SRAI_WRITE_IN_REGISTER:

			BREAK_EXECUTION: begin
				PcWrite = 0; 
				IMemRead = 0; 
				DMemRead = 0;
				IrWrite = 0; 
				WriteReg = 0; 
				LoadRegA = 0; 
				AluSrcA = 0; 
				LoadRegB = 0; 
				AluSrcB = 0; 
				MemToReg = 0;
				LoadAOut = 0;	
				LoadMDR = 0;
				PCSrc = 0;	
				SEFct = SIGN_R; 
				AluFct = PASS_ULA; 
				PcWriteCond = 0;
				ShiftType = SHIFT_PASS;
				BranchType = NO_BRANCH;
				LoadType = LD_TYPE;
				StoreType = SD_TYPE;
				next_state = BREAK_EXECUTION;	
			end

			SD_ARITHMETIC: begin			//calcula o endereço para armazenar na memoria de dados e guarda o resultado em AluOut 
				PcWrite = 0;
				IMemRead = 0;				
				DMemRead = 0;
				IrWrite = 0;
				WriteReg = 0;
				LoadRegA = 0;
				AluSrcA = 1;
				LoadRegB = 0;
				AluSrcB = 2; 
				MemToReg = 0;
				LoadAOut = 1;
				LoadMDR = 0;
				PCSrc = 0;
				SEFct = SIGN_S;
				AluFct = SUM_ULA;
				PcWriteCond = 0;
				ShiftType = SHIFT_PASS;
				BranchType = NO_BRANCH;
				LoadType = LD_TYPE;
				StoreType = SD_TYPE;
				
				if(instruction[14:12] == 7)
					next_state = SD_MEM_64_WRITE;
				else
					next_state = MEM_64_STORE_REQUISITION;

			end //SD_ARITHMETIC

			LUI_STORE_IN_REG: begin			//soma o upper immediate (imm[31:12]) com zero e guarda o resultado em AluOut
				PcWrite = 0;
				IMemRead = 0;				
				DMemRead = 0;
				IrWrite = 0;
				WriteReg = 1;
				LoadRegA = 0;
				AluSrcA = 1;
				LoadRegB = 0;
				AluSrcB = 2; 
				MemToReg = 2;
				LoadAOut = 0;
				LoadMDR = 0;
				PCSrc = 0;
				SEFct = SIGN_U;
				AluFct = PASS_ULA;
				PcWriteCond = 0;
				ShiftType = SHIFT_PASS;
				BranchType = NO_BRANCH;
				LoadType = LD_TYPE;
				StoreType = SD_TYPE;
				next_state = FETCH;
			end //LUI

			BEQ_COMPARISON: begin			//subtrai o valor de rs2 de rs1 e caso seja igual a zero, faz o branch
				PcWrite = 0;
				IMemRead = 0;				
				DMemRead = 0;
				IrWrite = 0;
				WriteReg = 0;
				LoadRegA = 0;
				AluSrcA = 1;
				LoadRegB = 0;
				AluSrcB = 0; 
				MemToReg = 0;
				LoadAOut = 0;
				LoadMDR = 0;
				PCSrc = 1;
				SEFct = SIGN_SB;
				AluFct = SUB_ULA;
				PcWriteCond = 1;
				ShiftType = SHIFT_PASS;
				BranchType = BEQ_TYPE;
				LoadType = LD_TYPE;
				StoreType = SD_TYPE;
				next_state = FETCH;
			end // BEQ

			BNE_COMPARISON: begin			//subtrai o valor de rs2 de rs1 e caso não seja igual a zero, faz o branch
				PcWrite = 0;
				IMemRead = 0;				
				DMemRead = 0;
				IrWrite = 0;
				WriteReg = 0;
				LoadRegA = 0;
				AluSrcA = 1;
				LoadRegB = 0;
				AluSrcB = 0; 
				MemToReg = 0;
				LoadAOut = 0;
				LoadMDR = 0;
				PCSrc = 1;
				SEFct = SIGN_SB;
				AluFct = SUB_ULA;
				PcWriteCond = 1;
				ShiftType = SHIFT_PASS;
				BranchType = BNE_TYPE;
				LoadType = LD_TYPE;
				StoreType = SD_TYPE;
				next_state = FETCH;
			end // BNE

			BGE_COMPARISON: begin			//subtrai o valor de rs2 de rs1 e caso não seja igual a zero, faz o branch
				PcWrite = 0;
				IMemRead = 0;				
				DMemRead = 0;
				IrWrite = 0;
				WriteReg = 0;
				LoadRegA = 0;
				AluSrcA = 1;
				LoadRegB = 0;
				AluSrcB = 0; 
				MemToReg = 0;
				LoadAOut = 0;
				LoadMDR = 0;
				PCSrc = 1;
				SEFct = SIGN_SB;
				AluFct = SUB_ULA;
				PcWriteCond = 1;
				ShiftType = SHIFT_PASS;
				BranchType = BGE_TYPE;
				LoadType = LD_TYPE;
				StoreType = SD_TYPE;
				next_state = FETCH;
			end // BNE

			BLT_COMPARISON: begin			//subtrai o valor de rs2 de rs1 e caso não seja igual a zero, faz o branch
				PcWrite = 0;
				IMemRead = 0;				
				DMemRead = 0;
				IrWrite = 0;
				WriteReg = 0;
				LoadRegA = 0;
				AluSrcA = 1;
				LoadRegB = 0;
				AluSrcB = 0; 
				MemToReg = 0;
				LoadAOut = 0;
				LoadMDR = 0;
				PCSrc = 1;
				SEFct = SIGN_SB;
				AluFct = SUB_ULA;
				PcWriteCond = 1;
				ShiftType = SHIFT_PASS;
				BranchType = BLT_TYPE;
				LoadType = LD_TYPE;
				StoreType = SD_TYPE;
				next_state = FETCH;
			end // BNE



			MEM_64_LOAD_REQUISITION: begin //Faz uma requisçao de leitura da memoria de dados com o endereco guardado em AluOut
				PcWrite = 0;
				IMemRead = 0;				
				DMemRead = 0;
				IrWrite = 0;
				WriteReg = 0;
				LoadRegA = 0;
				AluSrcA = 1;
				LoadRegB = 0;
				AluSrcB = 2; 
				MemToReg = 0;
				LoadAOut = 0;
				LoadMDR = 0;
				PCSrc = 0;
				SEFct = SIGN_R;
				AluFct = PASS_ULA;
				PcWriteCond = 0;
				ShiftType = SHIFT_PASS;
				BranchType = NO_BRANCH;
				LoadType = LD_TYPE;
				StoreType = SD_TYPE;
				
				case (instruction[14:12])
					LB_TYPE:
						next_state = MDR_WRITE_LB;
					LH_TYPE:
						next_state = MDR_WRITE_LH;
					LW_TYPE:
						next_state = MDR_WRITE_LW;
					LD_TYPE:
						next_state = MDR_WRITE_LD;
					LBU_TYPE:
						next_state = MDR_WRITE_LBU;
					LHU_TYPE:
						next_state = MDR_WRITE_LHU;
					LWU_TYPE:
						next_state = MDR_WRITE_LWU;				
					default : 
						next_state = MDR_WRITE_LD;
				endcase

			end //MEM_64_REQUISITION

			MEM_64_STORE_REQUISITION: begin
				PcWrite = 0;
				IMemRead = 0;				
				DMemRead = 0;
				IrWrite = 0;
				WriteReg = 0;
				LoadRegA = 0;
				AluSrcA = 1;
				LoadRegB = 0;
				AluSrcB = 2; 
				MemToReg = 0;
				LoadAOut = 0;
				LoadMDR = 0;
				PCSrc = 0;
				SEFct = SIGN_R;
				AluFct = PASS_ULA;
				PcWriteCond = 0;
				ShiftType = SHIFT_PASS;
				BranchType = NO_BRANCH;
				LoadType = LD_TYPE;
				StoreType = SD_TYPE;

				case(instruction[14:12])
					SB_TYPE:
						next_state = SB_MEM_64_WRITE;
					SH_TYPE:
						next_state = SH_MEM_64_WRITE;
					SW_TYPE:
						next_state = SW_MEM_64_WRITE;
					default:
						next_state = SD_MEM_64_WRITE;
				endcase
			end // MEM_64_STORE_REQUISITION:

			MDR_WRITE_LB: begin	
				PcWrite = 0;
				IMemRead = 0;
				DMemRead = 0;
				IrWrite = 0;
				WriteReg = 0;
				LoadRegA = 0;
				AluSrcA = 0;
				LoadRegB = 0;
				AluSrcB = 0;
				MemToReg = 0;
				LoadAOut = 0;
				LoadMDR = 1;
				PCSrc = 0;
				SEFct = SIGN_R;
				AluFct = PASS_ULA;
				PcWriteCond = 0;
				ShiftType = SHIFT_PASS;
				BranchType = NO_BRANCH;
				LoadType = LB_TYPE;
				StoreType = SD_TYPE;
				next_state = WRITE_IN_REGISTER_MEM;
			end // MDR_WRITE_LB

			MDR_WRITE_LH: begin	
				PcWrite = 0;
				IMemRead = 0;
				DMemRead = 0;
				IrWrite = 0;
				WriteReg = 0;
				LoadRegA = 0;
				AluSrcA = 0;
				LoadRegB = 0;
				AluSrcB = 0;
				MemToReg = 0;
				LoadAOut = 0;
				LoadMDR = 1;
				PCSrc = 0;
				SEFct = SIGN_R;
				AluFct = PASS_ULA;
				PcWriteCond = 0;
				ShiftType = SHIFT_PASS;
				BranchType = NO_BRANCH;
				LoadType = LH_TYPE;
				StoreType = SD_TYPE;
				next_state = WRITE_IN_REGISTER_MEM;
			end // MDR_WRITE_LH:

			MDR_WRITE_LW: begin	
				PcWrite = 0;
				IMemRead = 0;
				DMemRead = 0;
				IrWrite = 0;
				WriteReg = 0;
				LoadRegA = 0;
				AluSrcA = 0;
				LoadRegB = 0;
				AluSrcB = 0;
				MemToReg = 0;
				LoadAOut = 0;
				LoadMDR = 1;
				PCSrc = 0;
				SEFct = SIGN_R;
				AluFct = PASS_ULA;
				PcWriteCond = 0;
				ShiftType = SHIFT_PASS;
				BranchType = NO_BRANCH;
				LoadType = LW_TYPE;
				StoreType = SD_TYPE;
				next_state = WRITE_IN_REGISTER_MEM;
			end // MDR_WRITE_LW:

			MDR_WRITE_LD: begin	
				PcWrite = 0;
				IMemRead = 0;
				DMemRead = 0;
				IrWrite = 0;
				WriteReg = 0;
				LoadRegA = 0;
				AluSrcA = 0;
				LoadRegB = 0;
				AluSrcB = 0;
				MemToReg = 0;
				LoadAOut = 0;
				LoadMDR = 1;
				PCSrc = 0;
				SEFct = SIGN_R;
				AluFct = PASS_ULA;
				PcWriteCond = 0;
				ShiftType = SHIFT_PASS;
				BranchType = NO_BRANCH;
				LoadType = LD_TYPE;
				StoreType = SD_TYPE;
				next_state = WRITE_IN_REGISTER_MEM;
			end // MDR_WRITE_LD:

			MDR_WRITE_LBU: begin	
				PcWrite = 0;
				IMemRead = 0;
				DMemRead = 0;
				IrWrite = 0;
				WriteReg = 0;
				LoadRegA = 0;
				AluSrcA = 0;
				LoadRegB = 0;
				AluSrcB = 0;
				MemToReg = 0;
				LoadAOut = 0;
				LoadMDR = 1;
				PCSrc = 0;
				SEFct = SIGN_R;
				AluFct = PASS_ULA;
				PcWriteCond = 0;
				ShiftType = SHIFT_PASS;
				BranchType = NO_BRANCH;
				LoadType = LBU_TYPE;
				StoreType = SD_TYPE;
				next_state = WRITE_IN_REGISTER_MEM;
			end // MDR_WRITE_LBU:

			MDR_WRITE_LHU: begin	
				PcWrite = 0;
				IMemRead = 0;
				DMemRead = 0;
				IrWrite = 0;
				WriteReg = 0;
				LoadRegA = 0;
				AluSrcA = 0;
				LoadRegB = 0;
				AluSrcB = 0;
				MemToReg = 0;
				LoadAOut = 0;
				LoadMDR = 1;
				PCSrc = 0;
				SEFct = SIGN_R;
				AluFct = PASS_ULA;
				PcWriteCond = 0;
				ShiftType = SHIFT_PASS;
				BranchType = NO_BRANCH;
				LoadType = LHU_TYPE;
				StoreType = SD_TYPE;
				next_state = WRITE_IN_REGISTER_MEM;
			end // MDR_WRITE_LHU:

			MDR_WRITE_LWU: begin	
				PcWrite = 0;
				IMemRead = 0;
				DMemRead = 0;
				IrWrite = 0;
				WriteReg = 0;
				LoadRegA = 0;
				AluSrcA = 0;
				LoadRegB = 0;
				AluSrcB = 0;
				MemToReg = 0;
				LoadAOut = 0;
				LoadMDR = 1;
				PCSrc = 0;
				SEFct = SIGN_R;
				AluFct = PASS_ULA;
				PcWriteCond = 0;
				ShiftType = SHIFT_PASS;
				BranchType = NO_BRANCH;
				LoadType = LWU_TYPE;
				StoreType = SD_TYPE;
				next_state = WRITE_IN_REGISTER_MEM;
			end // MDR_WRITE_LWU:

			SB_MEM_64_WRITE: begin 	//Escreve no eSD_ARITHMETICereço guardado em AluOut o valor de rs2
				PcWrite = 0;
				IMemRead = 0;				
				DMemRead = 1;
				IrWrite = 0;
				WriteReg = 0;
				LoadRegA = 0;
				AluSrcA = 1;
				LoadRegB = 0;
				AluSrcB = 2; 
				MemToReg = 0;
				LoadAOut = 0;
				LoadMDR = 0;
				PCSrc = 0;
				SEFct = SIGN_R;
				AluFct = PASS_ULA;
				PcWriteCond = 0;
				ShiftType = SHIFT_PASS;
				BranchType = NO_BRANCH;
				LoadType = LD_TYPE;
				StoreType = SB_TYPE;
				next_state = FETCH;
			end //MEM_64_WRITE

			SH_MEM_64_WRITE: begin 	//Escreve no eSD_ARITHMETICereço guardado em AluOut o valor de rs2
				PcWrite = 0;
				IMemRead = 0;				
				DMemRead = 1;
				IrWrite = 0;
				WriteReg = 0;
				LoadRegA = 0;
				AluSrcA = 1;
				LoadRegB = 0;
				AluSrcB = 2; 
				MemToReg = 0;
				LoadAOut = 0;
				LoadMDR = 0;
				PCSrc = 0;
				SEFct = SIGN_R;
				AluFct = PASS_ULA;
				PcWriteCond = 0;
				ShiftType = SHIFT_PASS;
				BranchType = NO_BRANCH;
				LoadType = LD_TYPE;
				StoreType = SH_TYPE;
				next_state = FETCH;
			end //MEM_64_WRITE

			SW_MEM_64_WRITE: begin 	//Escreve no eSD_ARITHMETICereço guardado em AluOut o valor de rs2
				PcWrite = 0;
				IMemRead = 0;				
				DMemRead = 1;
				IrWrite = 0;
				WriteReg = 0;
				LoadRegA = 0;
				AluSrcA = 1;
				LoadRegB = 0;
				AluSrcB = 2; 
				MemToReg = 0;
				LoadAOut = 0;
				LoadMDR = 0;
				PCSrc = 0;
				SEFct = SIGN_R;
				AluFct = PASS_ULA;
				PcWriteCond = 0;
				ShiftType = SHIFT_PASS;
				BranchType = NO_BRANCH;
				LoadType = LD_TYPE;
				StoreType = SW_TYPE;
				next_state = FETCH;
			end //MEM_64_WRITE

			SD_MEM_64_WRITE: begin 	//Escreve no eSD_ARITHMETICereço guardado em AluOut o valor de rs2
				PcWrite = 0;
				IMemRead = 0;				
				DMemRead = 1;
				IrWrite = 0;
				WriteReg = 0;
				LoadRegA = 0;
				AluSrcA = 1;
				LoadRegB = 0;
				AluSrcB = 2; 
				MemToReg = 0;
				LoadAOut = 0;
				LoadMDR = 0;
				PCSrc = 0;
				SEFct = SIGN_R;
				AluFct = PASS_ULA;
				PcWriteCond = 0;
				ShiftType = SHIFT_PASS;
				BranchType = NO_BRANCH;
				LoadType = LD_TYPE;
				StoreType = SD_TYPE;
				next_state = FETCH;
			end //MEM_64_WRITE

			WRITE_IN_REGISTER_ALU: begin	//Escreve no Banco de Registradores o valor guardado no AluOut
				PcWrite = 0;
				IMemRead = 0;				
				DMemRead = 0;
				IrWrite = 0;
				WriteReg = 1;
				LoadRegA = 0;
				AluSrcA = 1;
				LoadRegB = 0;
				AluSrcB = 2; 
				MemToReg = 0;
				LoadAOut = 0;
				LoadMDR = 0;
				PCSrc = 0;
				SEFct = SIGN_R;
				AluFct = PASS_ULA;
				PcWriteCond = 0;
				ShiftType = SHIFT_PASS;
				BranchType = NO_BRANCH;
				LoadType = LD_TYPE;
				StoreType = SD_TYPE;
				next_state = FETCH;
			end // WRITE_IN_REGISTER_ALU

			WRITE_IN_REGISTER_MEM: begin	//Escreve no Banco de Registradores o valor guardado em Memory Data Register
				PcWrite = 0;
				IMemRead = 0;				
				DMemRead = 0;
				IrWrite = 0;
				WriteReg = 1;
				LoadRegA = 0;
				AluSrcA = 1;
				LoadRegB = 0;
				AluSrcB = 2; //Extended + Shift2
				MemToReg = 1;
				LoadAOut = 0;
				LoadMDR = 0;
				PCSrc = 0;
				SEFct = SIGN_R;
				AluFct = PASS_ULA;
				PcWriteCond = 0;
				ShiftType = SHIFT_PASS;
				BranchType = NO_BRANCH;
				LoadType = LD_TYPE;
				StoreType = SD_TYPE;
				next_state = FETCH;
			end //WRITE_IN_REGISTER_MEM

			JAL_WRITE_IN_REGISTER: begin	//SALVA NO REGISTRADOR O ENDEREÇO DE PC E PULA PARA A LABEL
				PcWrite = 1;
				IMemRead = 0;				
				DMemRead = 0;
				IrWrite = 0;
				WriteReg = 1;
				LoadRegA = 0;
				AluSrcA = 0;
				LoadRegB = 0;
				AluSrcB = 3; //Extended + Shift2
				MemToReg = 5;
				LoadAOut = 0;
				LoadMDR = 0;
				PCSrc = 0;
				SEFct = SIGN_UJ;
				AluFct = SUM_ULA;
				PcWriteCond = 0;
				ShiftType = SHIFT_PASS;
				BranchType = NO_BRANCH;
				LoadType = LD_TYPE;
				StoreType = SD_TYPE;
				next_state = FETCH;
			end //WRITE_IN_REGISTER_MEM

			JALR_WRITE_IN_REGISTER: begin	//SALVA NO REGISTRADOR O ENDEREÇO DE PC E PULA PARA O ENDEREÇO QUE ESTA NO REGISTRADOR 
				PcWrite = 1;
				IMemRead = 0;				
				DMemRead = 0;
				IrWrite = 0;
				WriteReg = 1;
				LoadRegA = 0;
				AluSrcA = 1;
				LoadRegB = 0;
				AluSrcB = 2; //Extended + Shift2
				MemToReg = 5;
				LoadAOut = 0;
				LoadMDR = 0;
				PCSrc = 0;
				SEFct = SIGN_I;
				AluFct = SUM_ULA;
				PcWriteCond = 0;
				ShiftType = SHIFT_PASS;
				BranchType = NO_BRANCH;
				LoadType = LD_TYPE;
				StoreType = SD_TYPE;
				next_state = FETCH;
			end //WRITE_IN_REGISTER_MEM

		endcase // state
		
		state_out = state;
	end
endmodule // controlUnit