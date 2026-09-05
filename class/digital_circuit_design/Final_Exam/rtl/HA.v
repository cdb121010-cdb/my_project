module HA(
    input a, b,
    output sum, carry
);
    xor u_xor (sum, a, b);
    and u_and (carry, a, b);
	 
endmodule
