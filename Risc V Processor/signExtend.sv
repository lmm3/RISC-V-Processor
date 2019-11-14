module signExtend(
	input logic [31:0] instruction,
	input logic [2:0] sel_type,
	output logic [63:0] extension);

	parameter R = 0,
	I = 1,
	S = 2,
	SB = 3,
	U = 4,
	UJ = 5;

	always_comb begin  
		case(sel_type)
			R: begin
				if(instruction[31] == 0)
					extension = {32'd0, instruction};
				else
					extension = {32'hFFFFFFFF, instruction};
			end
			I: begin
				if(instruction[31] == 0)
					extension = {52'd0, instruction[31:20]};
				else
					extension = {52'hFFFFFFFFFFFFF, instruction[31:20]};
			end 
			S: begin
				if(instruction[31] == 0)
					extension = {52'd0, instruction[31:25], instruction[11:7]};
				else
					extension = {52'hFFFFFFFFFFFFF, instruction[31:25], instruction[11:7]};
			end
			SB: begin
				if(instruction[31] == 0)
					extension = {51'd0, instruction[31], instruction[7], instruction[30:25], instruction[11:8], 1'b0};
				else
				extension = {51'h7FFFFFFFFFFFF, instruction[31], instruction[7], instruction[30:25], instruction[11:8], 1'b0};
			end
			UJ: begin
				if(instruction[31] == 0)
					extension = {43'd0 , instruction[31] , instruction[19:12] , instruction[20]  , instruction[30:21], 1'b0};
				else
					extension = {43'h7FFFFFFFFFF , instruction[31] , instruction[19:12] , instruction[20]  , instruction[30:21], 1'b0};
			end
			U: begin
				if(instruction[31] == 0)
					extension = {32'd0 , instruction[31:12], 12'd0};
				else
					extension = {32'hFFFFFFFF , instruction[31:12], 12'd0};
			end
			
			default: begin
				if(instruction[31] == 0)
					extension = {32'd0, instruction};
				else
					extension = {32'hFFFFFFFF, instruction};
			end
		endcase // i_type
	end
endmodule // signExtend