module clock_divider(rst,clk,clk_div10);
	
	input rst,clk;
	output clk_div10;

	reg [2:0] cnt;
	reg sig;

	always@(posedge clk or posedge rst)
	 if (rst) begin
		cnt <= 3'd0;
		sig <= 1'b0;
		end
	 else begin
		cnt = cnt+1;
		if (cnt == 5)begin
		   cnt = 3'd0;
		   sig = ~sig;
		end
	 end
	assign clk_div10 = sig;
endmodule

