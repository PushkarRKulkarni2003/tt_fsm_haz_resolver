`default_nettype none
`timescale 1ns / 1ps

/* This testbench just instantiates the module and makes some convenient wires
   that can be driven / tested by the cocotb test.py.
*/
module tb ();

  // Dump the signals to a VCD file. You can view it with gtkwave.
  initial begin
    $dumpfile("tb.vcd");
    $dumpvars(0, tb);
    #1;
  end

  // Wire up the inputs and outputs:
  reg clk;
  reg rst_n;
  reg ena;
  reg [7:0] ui_in;
  reg [7:0] uio_in;
  wire [7:0] uo_out;
  wire [7:0] uio_out;
  wire [7:0] uio_oe;

  // Replace tt_um_example with your module name:
  tt_um_fsm_haz user_project (

      // Include power ports for the Gate Level test:
`ifdef GL_TEST
      .VPWR(1'b1),
      .VGND(1'b0),
`endif

      .ui_in  (ui_in),    // Dedicated inputs
      .uo_out (uo_out),   // Dedicated outputs
      .uio_in (uio_in),   // IOs: Input path
      .uio_out(uio_out),  // IOs: Output path
      .uio_oe (uio_oe),   // IOs: Enable path (active high: 0=input, 1=output)
      .ena    (ena),      // enable - goes high when design is selected
      .clk    (clk),      // clock
      .rst_n  (rst_n)     // not reset
  );

  // Assign values to the wire type inout signals
  initial begin
    clk = 0;
    forever #5 clk = ~clk;  
  end

  // helper task to apply an input vector and wait n clocks
    task apply_vec;
        input [7:0] vec;
        input integer clocks;
        integer i;
        begin
            ui_in = vec;
            for (i = 0; i < clocks; i = i + 1) begin
                @(posedge clk);
            end
        end
    endtask

    // monitor outputs: prints resolved, pc_freeze, do_flush each clock
    always @(posedge clk) begin
        $display("time=%0t ui_in=%b uo_out=%b (resolved=%b pc_freeze=%b do_flush=%b)",
                 $time, ui_in, uo_out, uo_out[7], uo_out[6], uo_out[5]);
    end

    // main stimulus
    initial begin
        // initial values
        ena   = 1'b1;
        uio_in = 8'b0;
        ui_in = 8'b0;
        rst_n = 1'b0;

        // hold reset for a few cycles
        repeat (3) @(posedge clk);
        rst_n = 1'b1;
        @(posedge clk);

        // 1) Idle: all zeros (Nor)
        $display("--- Idle (Nor) ---");
        apply_vec(8'b0000_0000, 3);

        // 2) ctrl asserted -> go to Con
        $display("--- Assert ctrl (bit4) -> Con ---");
        // ctrl is ui_in[4]
        apply_vec(8'b0001_0000, 3);

        // 3) deassert ctrl -> back to Nor
        $display("--- Deassert ctrl -> Nor ---");
        apply_vec(8'b0000_0000, 3);

        // 4) data asserted (bit7) and not forwarded -> go to Dat
        $display("--- Assert data (bit7) -> Dat ---");
        apply_vec(8'b1000_0000, 4);

        // 5) while data asserted, set fwrd (bit3) -> should return Nor
        $display("--- Assert data + fwrd (bit3) -> should go Nor ---");
        apply_vec(8'b1000_1000, 3);

        // 6) test store (str bit6)
        $display("--- Assert str (bit6) -> StaSin behavior ---");
        apply_vec(8'b0100_0000, 5);

        // 7) test branch + incorrect (branch uses bit4; crct uses bit2)
        $display("--- branch & crct=0 -> Flush path ---");
        apply_vec(8'b0001_0100, 4); // branch=1 (bit4), crct=0 (bit2=0)

        // 8) assert ctrl during flush
        $display("--- Assert ctrl during flush ---");
        apply_vec(8'b0001_0000, 3);

        // 9) random-ish sequences to exercise transitions
        $display("--- random-ish sequences ---");
        apply_vec(8'b1101_1100, 4);
        apply_vec(8'b0010_0000, 3);
        apply_vec(8'b1000_0100, 3);

        // finish
        $display("---- TEST COMPLETE ----");
        #10;
        $finish;
    end
endmodule

endmodule
