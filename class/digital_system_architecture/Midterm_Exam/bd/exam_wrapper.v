//Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
//Copyright 2022-2023 Advanced Micro Devices, Inc. All Rights Reserved.
//--------------------------------------------------------------------------------
//Tool Version: Vivado v.2023.1 (win64) Build 3865809 Sun May  7 15:05:29 MDT 2023
//Date        : Mon Apr 21 11:51:25 2025
//Host        : LAPTOP-NPRMJO2O running 64-bit major release  (build 9200)
//Command     : generate_target exam_wrapper.bd
//Design      : exam_wrapper
//Purpose     : IP block netlist
//--------------------------------------------------------------------------------
`timescale 1 ps / 1 ps

module exam_wrapper
   (Clk,
    gpio_rtl_0_tri_i,
    gpio_rtl_1_tri_o,
    reset_rtl_0,
    uart_rtl_0_rxd,
    uart_rtl_0_txd);
  input Clk;
  input [15:0]gpio_rtl_0_tri_i;
  output [15:0]gpio_rtl_1_tri_o;
  input reset_rtl_0;
  input uart_rtl_0_rxd;
  output uart_rtl_0_txd;

  wire Clk;
  wire [15:0]gpio_rtl_0_tri_i;
  wire [15:0]gpio_rtl_1_tri_o;
  wire reset_rtl_0;
  wire uart_rtl_0_rxd;
  wire uart_rtl_0_txd;

  exam exam_i
       (.Clk(Clk),
        .gpio_rtl_0_tri_i(gpio_rtl_0_tri_i),
        .gpio_rtl_1_tri_o(gpio_rtl_1_tri_o),
        .reset_rtl_0(reset_rtl_0),
        .uart_rtl_0_rxd(uart_rtl_0_rxd),
        .uart_rtl_0_txd(uart_rtl_0_txd));
endmodule
