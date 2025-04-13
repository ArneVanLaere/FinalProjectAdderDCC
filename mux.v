`timescale 1ns / 1ps

module mux#(
        parameter   INPUT_WIDTH = 5
    )
    (
        input [INPUT_WIDTH-1:0] iA, iB, 
        input iCondition,
        output [INPUT_WIDTH-1:0] oY
    );
    reg [INPUT_WIDTH-1:0] r;
    always @ (*)
    begin
        case(iCondition)
            1: r = iA;
            default: r = iB;
        endcase
//        $display("iA: %d, iB: %d, iCarry: %d", iA, iB, iCondition);
    end
    assign oY = r;
endmodule
