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
	
	reg [ADDER_WIDTH-1:0]  rSum;
	wire [BLOCK_WIDTH-1:0]  w1Sum [0:NUMBER_OF_BLOCKS-1];
	wire [BLOCK_WIDTH-1:0]  w0Sum [0:NUMBER_OF_BLOCKS-1];
	

    // variable to control for loop
    genvar i;
    reg [2:0] rSumFirst;


//first ripple carry adder accepts remainder ADDER_WIDTH/(NUMBER_OF_BLOCKS-1) bits of input
    ripple_carry_adder_Nb #( .ADDER_WIDTH(2) ) 
    ripple_carry_init   (
        .iA( iA[2:0] ), 
        .iB( operandB ),
        .iCarry( carry_in ),
        .oSum(rSumFirst),
        .oCarry(rCarry[0]),
        .oFinished(rFinished[0])
      );

//adders for both carry cases
generate
    for (i=1; i<NUMBER_OF_BLOCKS; i=i+1)  begin
        ripple_carry_adder_Nb #( .ADDER_WIDTH(BLOCK_WIDTH) ) ripple_carry_0_inst (.iA(iA[(BLOCK_WIDTH-1)*i:(BLOCK_WIDTH)*(i-1)]), .iB(iB[(BLOCK_WIDTH-1)*i:(BLOCK_WIDTH)*(i-1)]), .iCarry(0), .oSum(w0Sum[i]), .oCarry(r0Carry[i]), .oFinished(r0Finished[i]));
        ripple_carry_adder_Nb #( .ADDER_WIDTH(BLOCK_WIDTH) ) ripple_carry_1_inst (.iA(iA[(BLOCK_WIDTH-1)*i:(BLOCK_WIDTH)*(i-1)]), .iB(iB[(BLOCK_WIDTH-1)*i:(BLOCK_WIDTH)*(i-1)]), .iCarry(1), .oSum(w1Sum[i]), .oCarry(r1Carry[i]), .oFinished(r1Finished[i]));
    end 
endgenerate

integer j; //previous block that finished

always @(*)
    begin
        for (j=0; j<NUMBER_OF_BLOCKS; j=j+1) begin
            if (j==0) begin
                rSum = {rSumFirst, rSum[ADDER_WIDTH-1:ADDER_WIDTH-3]};
            end
            else begin
                if (rFinished[j-1]==1 && r0Finished[j]==1 && r1Finished[j]==1) begin
                    if (rCarry[j-1]==1) begin
                        rCarry[j] = r1Carry[j];
                        rSum = {w1Sum[j], rSum[ADDER_WIDTH-1:ADDER_WIDTH-BLOCK_WIDTH]}; //shift register
                    end
                    else begin
                        rCarry[j] = r0Carry[j];
                        rSum = {w0Sum[j], rSum[ADDER_WIDTH-1:ADDER_WIDTH-BLOCK_WIDTH]}; //shift register
                    end
                end
            end
        end
    end

    assign oCarry = rCarry[ADDER_WIDTH-1];
    assign oSum = rSum;

endmodule
