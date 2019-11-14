module LoadSizeSelector(
	input logic [63:0] MemDataIn,
	input logic [2:0] LoadType,
	output logic [63:0] LoadSelResult
	);

	parameter LB_TYPE = 0, //parametros dos Loads
	LH_TYPE = 1,
	LW_TYPE = 2,
	LD_TYPE = 3,
	LBU_TYPE = 4,
	LHU_TYPE = 5,
	LWU_TYPE = 6;

	always_comb begin 
		case(LoadType)
			LB_TYPE: begin
				if(MemDataIn[7] == 0)
					LoadSelResult = {56'd0, MemDataIn[7:0]};
				else
					LoadSelResult = {56'hFFFFFFFFFFFFFF, MemDataIn[7:0]};
			end // LB_TYPE

			LH_TYPE: begin
				if(MemDataIn[15] == 0)
					LoadSelResult = {48'd0, MemDataIn[15:0]};
				else
					LoadSelResult = {48'hFFFFFFFFFFFF, MemDataIn[15:0]};
			end // LH_TYPE

			LW_TYPE: begin
				if(MemDataIn[31] == 0)
					LoadSelResult = {31'd0, MemDataIn[31:0]};
				else
					LoadSelResult = {31'hFFFFFFFF, MemDataIn[31:0]};
			end // LW_TYPE

			LD_TYPE:
				LoadSelResult = MemDataIn;

			LBU_TYPE:
				LoadSelResult = {56'd0, MemDataIn[7:0]};

			LHU_TYPE:
				LoadSelResult = {48'd0, MemDataIn[15:0]};

			LWU_TYPE:
				LoadSelResult = {32'd0, MemDataIn[31:0]};

			default:
				LoadSelResult = MemDataIn;	

		endcase // LoadType
	end // always_comb
endmodule // LoadSizeSelector