module cnt_24(nRst, clk, digit_ten, digit_one);

	input clk,nRst;
	output [3:0] digit_ten,digit_one;

	reg [3:0] digit_ten;
	reg [3:0] digit_one;
	reg [4:0] cnt;
	
	always @ (posedge clk or negedge nRst)begin
		if (!nRst)begin
            cnt = 5'd0;
      end 
		else begin
            if (cnt == 5'd23)begin
                cnt = 5'd0;
				end
            else begin
                cnt = cnt + 1;
				end
		end
	end
	
	always @(*) begin
        digit_ten = cnt / 10; // 10의 자리
        digit_one = cnt % 10; // 1의 자리
   end

endmodule
