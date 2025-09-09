/*
 * Copyright (c) 2024 Your Name
 * SPDX-License-Identifier: Apache-2.0
 */

// `default_nettype none

// module tt_um_example (
//     input  wire [7:0] ui_in,    // Dedicated inputs
//     output wire [7:0] uo_out,   // Dedicated outputs
//     input  wire [7:0] uio_in,   // IOs: Input path
//     output wire [7:0] uio_out,  // IOs: Output path
//     output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
//     input  wire       ena,      // always 1 when the design is powered, so you can ignore it
//     input  wire       clk,      // clock
//     input  wire       rst_n     // reset_n - low to reset
// );

//   // All output pins must be assigned. If not used, assign to 0.
//   assign uo_out  = ui_in + uio_in;  // Example: ou_out is the sum of ui_in and uio_in
//   assign uio_out = 0;
//   assign uio_oe  = 0;

//   // List all unused inputs to prevent warnings
//   wire _unused = &{ena, clk, rst_n, 1'b0};

//endmodule




`timescale 1ns / 1ps

module tt_um_fsm_haz(
    input  wire clk, rst, data, str, ctrl, branch, fwrd, crct,
    output reg pc_freeze, resolved, do_flush,
    output reg [2:0] state_out
);
parameter Nor=3'b000, Con=3'b001, StaSin=3'b010, Flush=3'b011, Dat=3'b100, StaN=3'b101;
reg [2:0] ps, ns;
    
always @(posedge clk) begin
    if (rst)
        ps <= Nor;
    else
        ps <= ns;
end

always @(*) begin
ns = ps;
case (ps)
    Nor: begin
        if (ctrl)
            ns = Con;
        else if (data&&!fwrd)
            ns = Dat;
        else if (str)
            ns = StaSin;
        else
            ns = Nor;
    end
    
    Con: begin
        if (!ctrl) 
            ns = Nor;
        else if (branch) 
        begin
            if (!crct) 
                ns = Flush; 
            else begin
                if (data && !fwrd)
                    ns = Dat;
                else if (str)
                    ns = StaSin;
                else
                    ns = Nor;
            end
        end
        // else ns=Stasin
    end

    StaSin: begin
        if (branch && !crct)
            ns = Flush;
        else if(str^(!branch))
            ns=StaSin;
        else
            ns = Nor; 
    end

    Flush: begin
        if (ctrl)
            ns = Con;
        else
            ns = Nor;
    end

    Dat: begin
        if (!data) 
            ns = Nor;
        else if (fwrd)
            ns = Nor;
        else if (!fwrd && data)
            ns = StaN;
        else
            ns = Nor;
            end

    StaN: begin
        if (ctrl)
            ns=Con;
        else if (data)
            ns = StaN;
        else
            ns = Nor;
    end

    default: ns = ps;
    endcase
end

always @(*) begin
    pc_freeze = 1'b0;
    do_flush  = 1'b0;
    resolved  = 1'b0;
    state_out = ps;
    
        case (ps)
            Nor: begin
                pc_freeze = 1'b0;
                do_flush  = 1'b0;
                resolved  = 1'b1;
            end

            Con, Dat, StaSin, StaN: begin
                pc_freeze = 1'b1;
                do_flush  = 1'b0;
                resolved  = 1'b0;
                
            end

            Flush: begin
                pc_freeze = 1'b1;
                do_flush  = 1'b1;
                resolved  = 1'b0;
                
            end

            default: begin
                
            end
        endcase
    end

endmodule
