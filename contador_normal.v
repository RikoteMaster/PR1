module contador_normal
#(parameter final_count=32, WIDTH = $clog2(final_count-1))
(
	input CLOCK, ENA, RESET_N,CLEAR_N,
	output reg [WIDTH-1:0] count
);

	// RESET_N if needed, or increment if counting is ENAd
	always @ (posedge CLOCK or negedge RESET_N)
	begin
		if (!RESET_N)
			count <= 0;
		else if (CLEAR_N == 0)
			count <= 0;
		else if (ENA == 1'b1)
			count <= (count == final_count - 1) ? 1'b0 : count + 1'b1;
			
	end


endmodule
