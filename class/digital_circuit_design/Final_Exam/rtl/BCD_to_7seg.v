module BCD_to_7seg(
    input A, B, C, D, // A가 MSB, D가 LSB
    output a, b, c, d, e, f, g
);
    wire nA, nB, nC, nD;
    not (nA, A); not (nB, B); not (nC, C); not (nD, D);

    // Segment 'a'
    wire w_a1, w_a2;
    and (w_a1, B, D);
    and (w_a2, nB, nD);
    or  (a, A, C, w_a1, w_a2);

    // Segment 'b'
    wire w_b1, w_b2;
    and (w_b1, nC, nD);
    and (w_b2, C, D);
    or  (b, nB, w_b1, w_b2);

    // Segment 'c'
    or  (c, B, nC, D);

    // Segment 'd'
    wire w_d1, w_d2, w_d3, w_d4;
    and (w_d1, nB, nD);
    and (w_d2, C, nD);
    and (w_d3, B, nC, D);
    and (w_d4, nB, C);
    or  (d, w_d1, w_d2, w_d3, w_d4, A);

    // Segment 'e'
    wire w_e1, w_e2;
    and (w_e1, nB, nD);
    and (w_e2, C, nD);
    or  (e, w_e1, w_e2);

    // Segment 'f'
    wire w_f1, w_f2, w_f3;
    and (w_f1, nC, nD);
    and (w_f2, B, nC);
    and (w_f3, B, nD);
    or  (f, A, w_f1, w_f2, w_f3);

    // Segment 'g'
    wire w_g1, w_g2, w_g3;
    and (w_g1, B, nC);
    and (w_g2, nB, C);
    and (w_g3, C, nD);
    or  (g, A, w_g1, w_g2, w_g3);
endmodule
