`timescale 1ns / 1ps

module var_carry_select #(
    parameter   ADDER_WIDTH = 32,
    parameter   NUMBER_OF_BLOCKS = 5,
    parameter   INCREMENT_SIZE = 2,  
    parameter   FIRST_BLOCK_WIDTH = 2
    )
    (
    input   wire [ADDER_WIDTH-1:0]  iA, iB, 
    input   wire                    iCarry,
    output  wire [ADDER_WIDTH-1:0]  oSum, 
    output  wire                    oCarry
);

	wire [NUMBER_OF_BLOCKS-1:0] wCarry, w0Carry, w1Carry, w0Finished, w1Finished;
	reg [NUMBER_OF_BLOCKS-1:0] rCarry, rFinished;
	
	reg [ADDER_WIDTH-1:0]  rSum;
	
    wire [FIRST_BLOCK_WIDTH-1:0] wSumFirst;
    wire  wCarryFirst, wFinishedFirst;



//first ripple carry adder accepts remainder ADDER_WIDTH/(NUMBER_OF_BLOCKS-1) bits of input
    ripple_carry_adder_Nb #( .ADDER_WIDTH(FIRST_BLOCK_WIDTH) ) 
    ripple_carry_init   (
        .iA( iA[FIRST_BLOCK_WIDTH-1:0] ), 
        .iB( iB[FIRST_BLOCK_WIDTH-1:0] ),
        .iCarry( iCarry ),
        .oSum(oSum[FIRST_BLOCK_WIDTH-1:0]),//wSumFirst),
        .oCarry(wCarry[0])
      );
    
    genvar i; // variable to control for loop

    generate //adders for both carry cases
        for (i=1; i<NUMBER_OF_BLOCKS; i=i+1)  begin : gen_block
            localparam current_block_width = (i==NUMBER_OF_BLOCKS-1) ? ADDER_WIDTH-(FIRST_BLOCK_WIDTH+INCREMENT_SIZE*(NUMBER_OF_BLOCKS-1)): FIRST_BLOCK_WIDTH+(i*INCREMENT_SIZE);
            localparam upper_limit = (i==NUMBER_OF_BLOCKS-1) ? ADDER_WIDTH-1: (i+1)*FIRST_BLOCK_WIDTH+INCREMENT_SIZE*(i*(i+1)/2);
            initial $display("current block width: %d, upper: %d", current_block_width, upper_limit);
            wire [current_block_width-1:0]  w1Sum;
            wire [current_block_width-1:0]  w0Sum;
	
            ripple_carry_adder_Nb #( .ADDER_WIDTH(current_block_width) ) 
                ripple_carry_0_inst (
                        .iA(iA[upper_limit-1:upper_limit-current_block_width]), 
                        .iB(iB[upper_limit-1:upper_limit-current_block_width]), 
                        .iCarry(0), 
                        .oSum(w0Sum),
                        .oCarry(w0Carry[i])
                    );
            ripple_carry_adder_Nb #( .ADDER_WIDTH(current_block_width) ) 
                ripple_carry_1_inst (
                        .iA(iA[upper_limit-1:upper_limit-current_block_width]), 
                        .iB(iB[upper_limit-1:upper_limit-current_block_width]), 
                        .iCarry(1), 
                        .oSum(w1Sum), 
                        .oCarry(w1Carry[i])
                    );
            mux #(.INPUT_WIDTH(1))
                carry_mux_inst (.iA(w1Carry[i]), .iB(w0Carry[i]), .iCondition(wCarry[i-1]), .oY(wCarry[i]));
            mux #(.INPUT_WIDTH(current_block_width))
                sum_mux_inst (.iA(w1Sum), .iB(w0Sum), .iCondition(wCarry[i-1]), .oY(oSum[upper_limit-1:upper_limit-current_block_width]));
        end 
    endgenerate

    assign oCarry = wCarry[NUMBER_OF_BLOCKS-1];

endmodule
