module Digital_watch(nRst, clk, key_sec, key_min, key_hr, sel_sw,
                     fnd_sec_ten, fnd_sec_one, fnd_min_ten, fnd_min_one, fnd_hr_ten, fnd_hr_one);

input nRst, clk, sel_sw;
input key_sec, key_min, key_hr;
output [6:0] fnd_sec_ten, fnd_sec_one;
output [6:0] fnd_min_ten, fnd_min_one;
output [6:0] fnd_hr_ten, fnd_hr_one;

wire sec_sig;
wire sec_clk;
wire min_clk;
wire hr_clk;
wire sec_carry;
wire min_carry;
wire [3:0] sec_cnt_ten;
wire [3:0] sec_cnt_one;
wire [3:0] min_cnt_ten;
wire [3:0] min_cnt_one;
wire [3:0] hr_cnt_ten;
wire [3:0] hr_cnt_one;

sec_gen U_sec_gen(
    .nRst(nRst),
    .clk(clk),
    .sec_sig(sec_sig)
);

mux2_1 U_sec_mux(
    .a(sec_sig),
    .b(key_sec),
    .sel(sel_sw),
    .y(sec_clk)
);

mux2_1 U_min_mux(
    .a(sec_carry),
    .b(key_min),
    .sel(sel_sw),
    .y(min_clk)
);

mux2_1 U_hr_mux(
    .a(min_carry),
    .b(key_hr),
    .sel(sel_sw),
    .y(hr_clk)
);

cnt_60 U_cnt_sec(
    .nRst(nRst),
    .clk(sec_clk),
    .digit_ten(sec_cnt_ten),
    .digit_one(sec_cnt_one),
    .carry(sec_carry)
);

cnt_60 U_cnt_min(
    .nRst(nRst),
    .clk(min_clk),
    .digit_ten(min_cnt_ten),
    .digit_one(min_cnt_one),
    .carry(min_carry)
);

cnt_24 U_cnt_hr(
    .nRst(nRst),
    .clk(hr_clk),
    .digit_ten(hr_cnt_ten),
    .digit_one(hr_cnt_one)
);

fnd_dec U_fnd_sec_one(
    .data(sec_cnt_one),
    .fnd_data(fnd_sec_one)
);

fnd_dec U_fnd_sec_ten(
    .data(sec_cnt_ten),
    .fnd_data(fnd_sec_ten)
);

fnd_dec U_fnd_min_one(
    .data(min_cnt_one),
    .fnd_data(fnd_min_one)
);

fnd_dec U_fnd_min_ten(
    .data(min_cnt_ten),
    .fnd_data(fnd_min_ten)
);

fnd_dec U_fnd_hr_one(
    .data(hr_cnt_one),
    .fnd_data(fnd_hr_one)
);

fnd_dec U_fnd_hr_ten(
    .data(hr_cnt_ten),
    .fnd_data(fnd_hr_ten)
);

endmodule
