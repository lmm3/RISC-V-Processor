module mux2in(
	input logic[63:0] first,
	input logic [63:0] second,
	input logic sel,
	output logic [63:0] result
);
	
	always_comb begin
		if(sel == 0)
			result = first;
		else
			result = second;
	end
endmodule  //