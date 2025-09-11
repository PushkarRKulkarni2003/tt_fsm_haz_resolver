`default_nettype none
`timescale 1ns / 1ps

module tb ();

  // VCD dump
  initial begin
    $dumpfile("tb.vcd");
    $dumpvars(0, tb);
    #1;
  end

  // Signals driven by TB
  reg        clk;
  reg        rst_n;
  reg        ena;
  reg  [7:0] ui_in;
  reg  [7:0] uio_in;
  wire [7:0] uo_out;
  wire [7:0] uio_out;
  wire [7:0] uio_oe;

  // Clock generator: 10 ns period
  initial begin
    clk = 0;
    forever #5 clk = ~clk;
  end

  // Instantiate DUT with instance name 'user_project'
  tt_um_fsm_haz user_project (
`ifdef GL_TEST
    .VPWR(1'b1),
    .VGND(1'b0),
`endif
    .ui_in  (ui_in),
    .uo_out (uo_out),
    .uio_in (uio_in),
    .uio_out(uio_out),
    .uio_oe (uio_oe),
    .ena    (ena),
    .clk    (clk),
    .rst_n  (rst_n)
  );

  // Print outputs each clock for quick console check
  always @(posedge clk) begin
    $display("time=%0t ui_in=%b uo_out=%b (resolved=%b pc_freeze=%b do_flush=%b)",
             $time, ui_in, uo_out, uo_out[7], uo_out[6], uo_out[5]);
  end

  // Simple linear stimulus (no tasks)
  initial begin
    // init
    ena    = 1'b1;
    uio_in = 8'b0;
    ui_in  = 8'b0;
    rst_n  = 1'b0;

    // hold reset for a few clocks
    repeat (3) @(posedge clk);
    rst_n = 1'b1;
    @(posedge clk);

    // 1) Idle (Nor)
    $display("--- Idle (Nor) ---");
    ui_in = 8'b0000_0000;
    repeat (3) @(posedge clk);

    // 2) ctrl asserted -> Con (bit4)
    $display("--- Assert ctrl (bit4) -> Con ---");
    ui_in = 8'b0001_0000;
    repeat (3) @(posedge clk);

    // 3) deassert ctrl -> Nor
    $display("--- Deassert ctrl -> Nor ---");
    ui_in = 8'b0000_0000;
    repeat (3) @(posedge clk);

    // 4) data asserted -> Dat (bit7)
    $display("--- Assert data (bit7) -> Dat ---");
    ui_in = 8'b1000_0000;
    repeat (4) @(posedge clk);

    // 5) data + fwrd -> back to Nor (bit7 + bit3)
    $display("--- Assert data + fwrd (bit3) -> should go Nor ---");
    ui_in = 8'b1000_1000;
    repeat (3) @(posedge clk);

    // 6) store (str bit6)
    $display("--- Assert str (bit6) -> StaSin ---");
    ui_in = 8'b0100_0000;
    repeat (5) @(posedge clk);

    // 7) branch & crct=0 -> Flush (branch bit4; crct bit2)
    $display("--- branch & crct=0 -> Flush ---");
    ui_in = 8'b0001_0100;
    repeat (4) @(posedge clk);

    // 8) assert ctrl during flush
    $display("--- Assert ctrl during flush ---");
    ui_in = 8'b0001_0000;
    repeat (3) @(posedge clk);

    // 9) a few random-ish vectors
    $display("--- random-ish sequences ---");
    ui_in = 8'b1101_1100; @(posedge clk);
    ui_in = 8'b1101_1100; @(posedge clk);
    ui_in = 8'b0010_0000; @(posedge clk);
    ui_in = 8'b1000_0100; repeat (2) @(posedge clk);

    // Finish
    $display("---- TEST COMPLETE ----");
    #10;
    $finish;
  end

endmodule
