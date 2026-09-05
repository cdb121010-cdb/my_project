// =====================================================================
// [최종 최상위 모듈] BCD 입력을 받아 7-Segment 출력으로 변환 (포트 매핑 수정완료)
// =====================================================================
module seg_out (
    input [3:0] bcd_tens,  // 10의 자리 BCD (4비트)
    input [3:0] bcd_ones,  // 1의 자리 BCD (4비트)
    output [6:0] seg_tens, // 10의 자리 7세그먼트 출력 (7비트)
    output [6:0] seg_ones  // 1의 자리 7세그먼트 출력 (7비트)
);

    // 10의 자리 디코더 연결 (Structural Instantiation)
    // 4비트 배열을 각각 쪼개서 A, B, C, D 포트에 매핑하고,
    // a~g 출력을 7비트 배열의 각 자리에 매핑합니다. (seg[6]이 a, seg[0]이 g)
    BCD_to_7Seg dec_tens (
        .A(bcd_tens[3]), .B(bcd_tens[2]), .C(bcd_tens[1]), .D(bcd_tens[0]),
        .a(seg_tens[6]), .b(seg_tens[5]), .c(seg_tens[4]), .d(seg_tens[3]),
        .e(seg_tens[2]), .f(seg_tens[1]), .g(seg_tens[0])
    );

    // 1의 자리 디코더 연결 (Structural Instantiation)
    BCD_to_7Seg dec_ones (
        .A(bcd_ones[3]), .B(bcd_ones[2]), .C(bcd_ones[1]), .D(bcd_ones[0]),
        .a(seg_ones[6]), .b(seg_ones[5]), .c(seg_ones[4]), .d(seg_ones[3]),
        .e(seg_ones[2]), .f(seg_ones[1]), .g(seg_ones[0])
    );

endmodule