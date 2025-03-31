`timescale 1ns / 1ps

module carry_select #(
    parameter   ADDER_WIDTH = 32,
    parameter   NUMBER_OF_BLOCKS = 6,
    parameter   BLOCK_WIDTH = 6
    )
    (
    input   wire [ADDER_WIDTH-1:0]  iA, iB, 
    input   wire                    iCarry,
    output  wire [ADDER_WIDTH-1:0]  oSum, 
    output  wire                    oCarry
);

	reg[NUMBER_OF_BLOCKS-1:0] rCarry, r0Carry, r1Carry, rFinished, r0Finished, r1Finished;
	
	reg [ADDER_WIDTH-1:0]  rSum, r0Sum, r1Sum;

    // variable to control for loop
    genvar i;


//first ripple carry adder accepts remainder ADDER_WIDTH/(NUMBER_OF_BLOCKS-1) bits of input
    ripple_carry_adder_Nb #( .ADDER_WIDTH(2) ) 
    ripple_carry_init   (
        .iA( iA[2:0] ), 
        .iB( operandB ),
        .iCarry( carry_in ),
        .oSum(rSum[2:0]),
        .oCarry(rCarry[0]),
        .oFinished(rFinished[0])
      );

//adders for both carry cases
generate
    for (i=1; i<NUMBER_OF_BLOCKS; i=i+1)  begin
        ripple_carry_adder_Nb #( .ADDER_WIDTH(BLOCK_WIDTH) ) ripple_carry_0_inst (.iA(iA[(BLOCK_WIDTH-1)*i:(BLOCK_WIDTH)*(i-1)]), .iB(iB[(BLOCK_WIDTH-1)*i:(BLOCK_WIDTH)*(i-1)]), .iCarry(0), .oSum(r0Sum[(BLOCK_WIDTH-1)*i:(BLOCK_WIDTH)*(i-1)]), .oCarry(r0Carry[i]), .oFinished(r0Finished[i]));
        ripple_carry_adder_Nb #( .ADDER_WIDTH(BLOCK_WIDTH) ) ripple_carry_1_inst (.iA(iA[(BLOCK_WIDTH-1)*i:(BLOCK_WIDTH)*(i-1)]), .iB(iB[(BLOCK_WIDTH-1)*i:(BLOCK_WIDTH)*(i-1)]), .iCarry(1), .oSum(r1Sum[(BLOCK_WIDTH-1)*i:(BLOCK_WIDTH)*(i-1)]), .oCarry(r1Carry[i]), .oFinished(r1Finished[i]));
    end 
endgenerate

integer j;

always @(*)
    begin
        for (j=0; j<NUMBER_OF_BLOCKS; j=j+1) begin
            if (rFinished[j]==1 && r0Finished[j+1]==1 && r1Finished[j+1]==1) begin
                if (rCarry[j]==1) begin
                    rCarry[j+1] <= r1Carry[j+1];
                    rSum[(BLOCK_WIDTH-1):0] <= r1Sum[BLOCK_WIDTH-1:0];
                end
                else begin
                    rCarry[j+1] <= r0Carry[j+1];
                    rSum[BLOCK_WIDTH-1:0] <= r0Sum[BLOCK_WIDTH-1:0];
                end
            end
        end
    end

    assign oCarry = rCarry[ADDER_WIDTH-1];
    assign oSum = rSum;

endmodule
