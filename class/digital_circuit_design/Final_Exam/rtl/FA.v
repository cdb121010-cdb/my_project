// 전가산기 (Full Adder)
module FA (
    input a, input b, input cin,
    output sum, output carry
);
    wire w_sum, w_c1, w_c2;
    xor (w_sum, a, b);
    xor (sum, w_sum, cin);
    and (w_c1, w_sum, cin);
    and (w_c2, a, b);
    or  (carry, w_c1, w_c2);
endmodule