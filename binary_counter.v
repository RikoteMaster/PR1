module binary_counter
#(parameter MODULO=32, WIDTH=$clog2(MODULO-1)-1)
(
	input clk,clear_n, enable, up_down, reset,
	output reg [WIDTH:0] count,
	output TC1,TC2
);

	// Reset if needed, increment or decrement if counting is enabled
	always @ (posedge clk or negedge reset)
	begin
		if (!reset)
			count <= 1'b0;
		else if(!clear_n)
			count <= 1'b0;
		else if (enable == 1'b1)
		begin
			if(up_down) //up_down normal == 1
				count <= count == MODULO-1'b1 ? 1'b0 : count + 1'b1;
			else
				count <= count == 1'b0 ? MODULO-1'b1 : count - 1'b1; 
		end
	end
assign TC1 = ( count == MODULO-1 ) ? 1'b1 : 1'b0 ; //31
assign TC2 = ( count == 1 ) ? 1'b1 : 1'b0   ;//1
endmodule 