module StoreSizeSelector(
	input logic [63:0] MemDataOut,
	input logic [63:0] StoreSizeIn,
	input logic [1:0] StoreType,
	output logic [63:0] StoreSelResult
	);

	parameter SB_TYPE = 0,
	SH_TYPE = 1,
	SW_TYPE = 2,
	SD_TYPE = 3;

	always_comb begin
		case(StoreType) 
			SB_TYPE:
				StoreSelResult = {MemDataOut[63:8], StoreSizeIn[7:0]};
			SH_TYPE:
				StoreSelResult = {MemDataOut[63:16], StoreSizeIn[15:0]};
			SW_TYPE:
				StoreSelResult = {MemDataOut[63:31], StoreSizeIn[31:0]};
			SD_TYPE:
				StoreSelResult = MemDataOut;
		endcase // StoreType
	end // always_comb
endmodule // StoreSizeSelector