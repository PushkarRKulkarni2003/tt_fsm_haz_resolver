`default_nettype none
`timescale 1ns / 1ps

module tb ();

  reg clk;
  reg rst_n;
  reg data, str, ctrl, branch, fwrd, crct;

  // Wires to DUT
  wire [7:0] ui_in;
  wire [7:0] uo_out;
  wire [7:0] uio_out;
  wire [7:0] uio_oe;

  reg [7:0] uio_in;
  reg ena;
  wire VPWR = 1'b1;
  wire VGND = 1'b0;

  // Pack individual signals into ui_in (matching your RTL)
  assign ui_in = {data, str, ctrl, branch, fwrd, crct, 1'b0, 1'b0};

  // DUT instantiation
  tt_um_fsm_haz user_project (
`ifdef GL_TEST
    .VPWR(VPWR),
    .VGND(VGND),
`endif
    .ui_in  (ui_in),
    .uo_out (uo_out),
    .uio_in (uio_in),
    .uio_out(uio_out),
    .uio_oe (uio_oe),
    .ena    (ena),
    .clk    (clk),
    .rst_n  (rst_n)   // active-low reset
  );

  // Clock
  initial begin
    clk = 0;
    forever #5 clk = ~clk;  // 10ns period
  end

  // VCD dump
  initial begin
    $dumpfile("tb.vcd");
    $dumpvars(0, tb);
  end
  
  // Stimulus sequence
  initial begin
    ena = 1;
    uio_in = 8'h00;

    $display("========Reset========");
    data=0; str=0; ctrl=0; branch=0; fwrd=0; crct=0;
    rst = 1; #20;
    rst = 0;

    $display("========Control hazard resolved CORRECTLY============");
    #10; ctrl=1; branch=1; crct=1;
    #10; ctrl=0; branch=0; crct=1;
    #30;

    $display("========Control hazard MIS-PREDICT (flush)===========");
    #10; ctrl=1; branch=1; crct=0;
    #20;

    $display("========Control hazard delayed, mispredict later=======");
    #10; ctrl=1; branch=0; crct=1;
    #15; branch=1; crct=0;
    #10; ctrl=0; branch=0; crct=1;
    #30;

    $display("========Control hazard delayed, correct predict later======");
    #10; ctrl=1; branch=0; crct=1;
    #15; branch=1; crct=1;
    #10; ctrl=0; branch=0; crct=1;
    #30;

    $display("========Data hazard resolved by forwarding==========");
    #10; data=1; fwrd=1;
    #10; data=0; fwrd=0;
    #30;

    $display("========Data hazard multi-cycle stall then cleared=======");
    #10; data=1; fwrd=0;
    #40; data=0;
    #30;

    $display("======== Structural hazard (single/multi-cycle)==========");
    #10; str=1;
    #20; str=0;
    #30;

    $display("========Priority tests==========");
    $display("======== a) ctrl + data =========");
    #10; ctrl=1; data=1; fwrd=0; str=0; branch=0; crct=1;
    #30; branch=1; crct=1;
    #10; branch=0; crct=1; ctrl=0; data=1;
    #20; data=0;

    $display("======== b) ctrl + str ===========");
    #20; ctrl=1; str=1; data=0; fwrd=0; branch=0; crct=1;
    #25; branch=1; crct=0;
    #10; branch=0; crct=1; ctrl=0; str=1;
    #20; str=0;

    $display("======== c) data + str ==========");
    #20; data=1; str=1; fwrd=0; ctrl=0;
    #30; data=0; str=0;
    #30;

    $display("======== 9) Preemption test: StaN interrupted by mispredict ===========");
    #10; data=1; fwrd=0;
    #15; ctrl=1; branch=1; crct=0;
    #20;
    #40;

    $display("---- TEST COMPLETE ----");
    $finish;
  end

endmodule
odule
