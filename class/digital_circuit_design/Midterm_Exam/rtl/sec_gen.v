module sec_gen(nRst, clk, sec_sig);

	input nRst,clk;
	output sec_sig;

	reg [31:0] cnt;
	reg sig;

	always @ (posedge clk or negedge nRst)
		if (!nRst) begin
			cnt = 32'd0;
			sig = 1'b0;
			end
		else begin
			cnt = cnt+1;
			if(cnt == 32'd25000000)begin
				cnt = 32'd0;
				sig = ~sig;
			end
		end
	assign sec_sig = sig;
endmodule