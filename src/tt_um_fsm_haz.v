
`timescale 1ns / 1ps
`default_nettype none
`timescale 1ns / 1ps
module tt_um_fsm_haz(
     input  wire [7:0] ui_in,    // Dedicated inputs
    output wire [7:0] uo_out,   // Dedicated outputs
    input  wire [7:0] uio_in,   // IOs: Input path
    output wire [7:0] uio_out,  // IOs: Output path
    output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // always 1 when the design is powered, so you can ignore it
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
);
  wire clk, rst_n, data, str, ctrl, branch, fwrd, crct;
    reg pc_freeze, resolved, do_flush;
parameter Nor=3'b000, Con=3'b001, StaSin=3'b010, Flush=3'b011, Dat=3'b100, StaN=3'b101;
reg [2:0] ps, ns;
    
always @(posedge clk) begin
    if (~rst_n)
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
