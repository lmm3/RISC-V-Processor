`timescale 1ps/1ps 

module signExtend_TB;

	logic [31:0] instruction;
	logic [2:0] sel_type;
	logic [63:0] extension;

	signExtend dut(
		.instruction(instruction),
		.sel_type   (sel_type),
		.extension  (extension)
		);

	initial begin 
		instruction = 32'hF0000000;
		sel_type = 0;
		#10 sel_type = 1;
		#10 sel_type = 2;
		#10 sel_type = 3;
		#10 sel_type = 4;
		#10 sel_type = 5;


	end

endmodule // signExtend_TB