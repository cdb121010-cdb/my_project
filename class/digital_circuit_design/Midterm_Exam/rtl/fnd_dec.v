module fnd_dec(data,fnd_data);

	input [3:0] data;
	output [6:0] fnd_data;
	
	reg [6:0] fnd_data;
	
    always @(data) begin
        case (data)
			4'd0: fnd_data = 7'b1000000; // 0 → a,b,c,d,e,f ON, g OFF
			4'd1: fnd_data = 7'b1111001; // 1 → b,c ON
			4'd2: fnd_data = 7'b0100100; // 2 → a,b,d,e,g ON
			4'd3: fnd_data = 7'b0110000; // 3 → a,b,c,d,g ON
			4'd4: fnd_data = 7'b0011001; // 4 → b,c,f,g ON
			4'd5: fnd_data = 7'b0010010; // 5 → a,c,d,f,g ON
			4'd6: fnd_data = 7'b0000010; // 6 → a,c,d,e,f,g ON
			4'd7: fnd_data = 7'b1111000; // 7 → a,b,c ON
			4'd8: fnd_data = 7'b0000000; // 8 → 모든 segment ON
			4'd9: fnd_data = 7'b0010000; // 9 → a,b,c,d,f,g ON
			default: fnd_data = 7'b1111111; // 아무 것도 표시하지 않음
        endcase
    end
		
endmodule
