module cnt_60(nRst, clk, digit_ten, digit_one,carry);

	 input clk,nRst;
	 output carry;
	 output [3:0] digit_ten,digit_one;

	 reg carry;
	 reg [3:0] digit_ten;
	 reg [3:0] digit_one;

    reg [5:0] cnt; // 0~59까지 표현 가능

    always @(posedge clk or negedge nRst) begin
        if (!nRst) begin
            cnt   <= 6'd0;
            carry <= 1'b0;
        end 
		  else begin
            if (cnt == 6'd59) begin
                cnt   <= 6'd0;
                carry <= 1'b1; // 60에서 리셋될 때 carry 발생
				end
            else begin
                cnt   <= cnt + 1;
                carry <= 1'b0;
            end
        end
    end

    always @(*) begin
        digit_ten = cnt / 10; // 10의 자리
        digit_one = cnt % 10; // 1의 자리
    end

endmodule
