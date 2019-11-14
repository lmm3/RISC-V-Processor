module BranchSelector(
	input logic zero,
	input logic lessThan,
	input logic[1:0] BranchType,
	input logic PcWriteCond,
	output logic BranchResult);

	always_comb begin
		if(PcWriteCond == 0) begin
			BranchResult = 0;
		end
		else begin
			if(BranchType == 0 && zero == 1) begin
				BranchResult = 1;
			end
			else if(BranchType == 1 && zero == 0) begin
				BranchResult = 1;
			end
			else if(BranchType == 2 && lessThan == 0) begin	//BGE
				BranchResult = 1;
			end
			else if(BranchType == 3 && lessThan == 1) begin	//BLT
				BranchResult = 1;
			end
			else begin
				BranchResult = 0;
			end
		end
	end
endmodule