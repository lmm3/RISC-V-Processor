module mux6in(
	input logic [63:0] first,
	input logic [63:0] second,
	input logic [63:0] third,
	input logic [63:0] fourth,
	input logic [63:0] fifth,
	input logic [63:0] sixth,
	input logic [2:0] sel,
	output logic [63:0] result
	);

	always_comb begin 
		case(sel)
			0:begin
				result = first;
			end
			1:begin
				result = second;
			end
			2:begin
				result = third;
			end
			3:begin
				result = fourth;
			end
			4:begin
				result = fifth;
			end
			5:begin
				result = sixth;
			end
		endcase
	end
endmodule  //