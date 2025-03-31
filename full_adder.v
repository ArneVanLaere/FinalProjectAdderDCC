`timescale 1ns / 1ps

module full_adder (
    input   wire    iA, iB, iCarry,
    output  wire    oSum, oCarry
);
wire w1, w2, w3;

assign w1 = iA ^ iB;
assign oSum = w1 ^ iCarry;
assign w2 = iCarry & w1;
assign w3 = iA & iB;
assign oCarry = w2 | w3;

endmodule
