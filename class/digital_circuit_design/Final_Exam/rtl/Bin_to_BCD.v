module Bin_to_BCD (
    input [3:0] in,
    output [3:0] out
);
    wire ni3, ni2, ni1, ni0;
    not (ni3, in[3]); not (ni2, in[2]); 
    not (ni1, in[1]); not (ni0, in[0]);

    // out[3] 로직
    wire w_o3_1, w_o3_2;
    and (w_o3_1, in[2], in[0]);
    and (w_o3_2, in[2], in[1]);
    or  (out[3], in[3], w_o3_1, w_o3_2);

    // out[2] 로직
    wire w_o2_1, w_o2_2;
    and (w_o2_1, in[2], ni1, ni0);
    and (w_o2_2, in[3], in[0]);
    or  (out[2], w_o2_1, w_o2_2);

    // out[1] 로직
    wire w_o1_1, w_o1_2, w_o1_3;
    and (w_o1_1, ni2, in[1]);
    and (w_o1_2, in[1], in[0]);
    and (w_o1_3, in[3], ni1, ni0);
    or  (out[1], w_o1_1, w_o1_2, w_o1_3);

    // out[0] 로직 
    wire w_o0_1, w_o0_2, w_o0_3;
    // 기존 오류: and (w_o0_1, ni2, in[0]);
    and (w_o0_1, ni3, ni2, in[0]);
    and (w_o0_2, in[2], in[1], ni0);
    and (w_o0_3, in[3], ni0);
    or  (out[0], w_o0_1, w_o0_2, w_o0_3);
    
endmodule