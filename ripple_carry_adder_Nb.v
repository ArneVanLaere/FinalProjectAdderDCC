`timescale 1ns / 1ps

module ripple_carry_adder_Nb #(
    parameter   ADDER_WIDTH = 16
    )
    (
    input   wire [ADDER_WIDTH-1:0]  iA, iB, 
    input   wire                    iCarry,
    output  wire [ADDER_WIDTH-1:0]  oSum, 
    output  wire                    oCarry
);

	wire[ADDER_WIDTH-1:0] wCarry;

    // variable to control for loop
    genvar i;

    full_adder fa1( .iA(iA[0]), .iB(iB[0]), .iCarry(iCarry), .oSum(oSum[0]), .oCarry(wCarry[0]));
    // instantiate N 1-bit comparators
    generate
        for (i=1; i<ADDER_WIDTH; i=i+1)  begin
            full_adder full_adder_inst (.iA(iA[i]), .iB(iB[i]), .iCarry(wCarry[i-1]), .oSum(oSum[i]), .oCarry(wCarry[i]));
        end 
    endgenerate
    assign oCarry = wCarry[ADDER_WIDTH-1];

endmodule
