// =====================================================================
// [진짜 최종 TOP 모듈] 입력 핀을 A, B로 분리하여 곱셈기 및 세그먼트 제어
// =====================================================================
module top_bin_to_7Seg_out (
    input  [2:0] A,          // 첫 번째 3비트 입력 (핀 매핑: SW2, SW1, SW0)
    input  [2:0] B,          // 두 번째 3비트 입력 (핀 매핑: SW5, SW4, SW3)
    output [6:0] seg_tens,   // 10의 자리 7세그먼트 HEX1 핀 (Active Low)
    output [6:0] seg_ones    // 1의 자리 7세그먼트 HEX0 핀 (Active Low)
);

    // 부품들 사이에서 신호를 주고받을 내부 전선(Wire) 정의
    wire [5:0] w_mul_result;         // 곱셈기 결과 (최대 49)
    wire [3:0] w_r1, w_r2, w_r3;     // Shift-and-Add-3 중간 와이어
    wire [3:0] bcd_tens, bcd_ones;   // 쪼개진 10의 자리, 1의 자리 BCD 숫자

    // -----------------------------------------------------------------
    // 1. [곱셈기 부품 연결] 쪼개진 3비트 입력 A와 B를 곱셈기에 직접 연결
    // -----------------------------------------------------------------
    // A[2]가 켜지면 값 4, B[2]가 켜지면 값 4가 되도록 설계되었습니다.
    bit3_multiplier u_multiplier (
        .X(A),             // 최상위 입력 A[2:0]를 곱셈기의 X[2:0]에 매핑
        .Y(B),             // 최상위 입력 B[2:0]를 곱셈기의 Y[2:0]에 매핑
        .W(w_mul_result)   // 곱셈 결과(6비트)를 w_mul_result 전선으로 출력
    );

    // -----------------------------------------------------------------
    // 2. [상수 0 생성] 제약조건 준수 (A & /A = 0)
    // -----------------------------------------------------------------
    wire n_bin0, w_GND;
    not (n_bin0, w_mul_result[0]);
    and (w_GND, w_mul_result[0], n_bin0);

    // -----------------------------------------------------------------
    // 3. [이진수 -> BCD 변환] Shift-and-Add-3 알고리즘 작동
    // -----------------------------------------------------------------
    Bin_to_BCD u_add1 (.in({w_GND, w_mul_result[5], w_mul_result[4], w_mul_result[3]}), .out(w_r1));
    Bin_to_BCD u_add2 (.in({w_r1[2], w_r1[1], w_r1[0], w_mul_result[2]}), .out(w_r2));
    Bin_to_BCD u_add3 (.in({w_r2[2], w_r2[1], w_r2[0], w_mul_result[1]}), .out(w_r3));

    // 10의 자리 BCD 추출 (or 게이트 활용 구조적 모델링)
    or (bcd_tens[3], w_GND, w_GND);
    or (bcd_tens[2], w_r1[3], w_r1[3]);
    or (bcd_tens[1], w_r2[3], w_r2[3]);
    or (bcd_tens[0], w_r3[3], w_r3[3]);

    // 1의 자리 BCD 추출 (or 게이트 활용 구조적 모델링)
    or (bcd_ones[3], w_r3[2], w_r3[2]);
    or (bcd_ones[2], w_r3[1], w_r3[1]);
    or (bcd_ones[1], w_r3[0], w_r3[0]);
    or (bcd_ones[0], w_mul_result[0], w_mul_result[0]);

    // -----------------------------------------------------------------
    // 4. [7세그먼트 디코더 연결] BCD 숫자를 전구 신호(Active High)로 변환
    // -----------------------------------------------------------------
    wire [6:0] w_seg_tens_high, w_seg_ones_high;

    BCD_to_7seg dec_tens (
        .A(bcd_tens[3]), .B(bcd_tens[2]), .C(bcd_tens[1]), .D(bcd_tens[0]),
        .a(w_seg_tens_high[6]), .b(w_seg_tens_high[5]), .c(w_seg_tens_high[4]), .d(w_seg_tens_high[3]),
        .e(w_seg_tens_high[2]), .f(w_seg_tens_high[1]), .g(w_seg_tens_high[0])
    );

    BCD_to_7seg dec_ones (
        .A(bcd_ones[3]), .B(bcd_ones[2]), .C(bcd_ones[1]), .D(bcd_ones[0]),
        .a(w_seg_ones_high[6]), .b(w_seg_ones_high[5]), .c(w_seg_ones_high[4]), .d(w_seg_ones_high[3]),
        .e(w_seg_ones_high[2]), .f(w_seg_ones_high[1]), .g(w_seg_ones_high[0])
    );

    // -----------------------------------------------------------------
    // 5. [Active Low 변환] DE10 보드 특성에 맞춰 NOT 게이트로 일제히 반전
    // -----------------------------------------------------------------
    not (seg_tens[6], w_seg_tens_high[6]); not (seg_tens[5], w_seg_tens_high[5]);
    not (seg_tens[4], w_seg_tens_high[4]); not (seg_tens[3], w_seg_tens_high[3]);
    not (seg_tens[2], w_seg_tens_high[2]); not (seg_tens[1], w_seg_tens_high[1]);
    not (seg_tens[0], w_seg_tens_high[0]);

    not (seg_ones[6], w_seg_ones_high[6]); not (seg_ones[5], w_seg_ones_high[5]);
    not (seg_ones[4], w_seg_ones_high[4]); not (seg_ones[3], w_seg_ones_high[3]);
    not (seg_ones[2], w_seg_ones_high[2]); not (seg_ones[1], w_seg_ones_high[1]);
    not (seg_ones[0], w_seg_ones_high[0]);

endmodule