`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module Name:    FPCVT
// Description:    12-bit Two's Complement to 8-bit Floating Point Converter
//                 
// Input:          D[11:0]  - 12-bit signed integer (two's complement)
// Outputs:        S        - Sign bit
//                 E[2:0]   - 3-bit exponent
//                 F[3:0]   - 4-bit significand (mantissa)
//
// FP Value:       V = (-1)^S * F * 2^E
//////////////////////////////////////////////////////////////////////////////////

module FPCVT(
    input  [11:0] D,
    output        S,
    output [2:0]  E,
    output [3:0]  F
);

    //=========================================================================
    // Internal Signals
    //=========================================================================
    
    // Stage 1: Sign-Magnitude Conversion
    wire [11:0] magnitude;
    
    // Stage 2: Leading Zero Count & Significand Extraction
    wire [2:0]  exp_raw;
    wire [4:0]  sig_with_round_bit;  // 4-bit significand + 1 rounding bit
    
    // Stage 3: Rounding
    wire [4:0]  sig_rounded;
    wire [2:0]  exp_final;
    wire [3:0]  sig_final;

    //=========================================================================
    // Stage 1: Convert Two's Complement to Sign-Magnitude
    //=========================================================================
    
    // Sign bit is MSB of input
    assign S = D[11];
    
    // Get absolute value (handle negative numbers)
    // Special case: -2048 (100000000000) cannot be negated in 12 bits
    // TODO: Implement magnitude calculation
    
    // assign magnitude = 12'b0;  // PLACEHOLDER - replace with actual logic
    // If D[11] = 1, negate the value using two's complement: ~D + 1
    assign magnitude = D[11] ? (~D + 1) : D;
 
    //=========================================================================
    // Stage 2: Count Leading Zeros & Extract Significand
    //=========================================================================
    
    // Priority encoder to count leading zeros and determine exponent
    // Leading Zeros -> Exponent mapping:
    //   0 -> 7,  1 -> 7,  2 -> 6,  3 -> 5,  4 -> 4
    //   5 -> 3,  6 -> 2,  7 -> 1,  >=8 -> 0
    // Note: 0 leading zeros clamps to E=7 (max representable)
    
    assign exp_raw = 
        (magnitude[11]) ? 3'b111 :  // First 1 at bit 11 (0 leading zeros) -> exp=7
        (magnitude[10]) ? 3'b111 :  // First 1 at bit 10 (1 leading zero) -> exp=7
        (magnitude[9])  ? 3'b110 :  // First 1 at bit 9 (2 leading zeros) -> exp=6
        (magnitude[8])  ? 3'b101 :  // First 1 at bit 8 (3 leading zeros) -> exp=5
        (magnitude[7])  ? 3'b100 :  // First 1 at bit 7 (4 leading zeros) -> exp=4
        (magnitude[6])  ? 3'b011 :  // First 1 at bit 6 (5 leading zeros) -> exp=3
        (magnitude[5])  ? 3'b010 :  // First 1 at bit 5 (6 leading zeros) -> exp=2
        (magnitude[4])  ? 3'b001 :  // First 1 at bit 4 (7 leading zeros) -> exp=1
        3'b000;                      // No 1 at bits 11-4 (>=8 leading zeros) -> exp=0

    // Extract significand (4 bits) and rounding bit (5th bit)
    // Significand = 4 bits immediately after the leading 1
    // Rounding bit = 5th bit after the leading 1
    assign sig_with_round_bit = 
        (exp_raw == 3'b111) ? magnitude[10:6] :     // Leading 1 at [11]: sig at [10:7], round at [6]
        (exp_raw == 3'b110) ? magnitude[9:5] :      // Leading 1 at [10]: sig at [9:6], round at [5]
        (exp_raw == 3'b101) ? magnitude[8:4] :      // Leading 1 at [9]: sig at [8:5], round at [4]
        (exp_raw == 3'b100) ? magnitude[7:3] :      // Leading 1 at [8]: sig at [7:4], round at [3]
        (exp_raw == 3'b011) ? magnitude[6:2] :      // Leading 1 at [7]: sig at [6:3], round at [2]
        (exp_raw == 3'b010) ? magnitude[5:1] :      // Leading 1 at [6]: sig at [5:2], round at [1]
        (exp_raw == 3'b001) ? magnitude[4:0] :      // Leading 1 at [5]: sig at [4:1], round at [0]
        {1'b0, magnitude[3:0]};  // exp=0: sig at [3:0], no rounding bit

    //=========================================================================
    // Stage 3: Rounding
    //=========================================================================
    
    // If 5th bit (rounding bit) is 1, add 1 to significand
    // Handle overflow: if significand becomes 10000, shift right and increment exponent
    // Handle exponent overflow: clamp to maximum value if E would exceed 7
    
    // TODO: Implement rounding logic
    // assign sig_rounded = 5'b0;  // PLACEHOLDER
    // assign exp_final = 3'b0;    // PLACEHOLDER
    // assign sig_final = 4'b0;    // PLACEHOLDER
    // Check if rounding bit is set
    wire round_bit = sig_with_round_bit[0];
    wire [4:0] sig_before_round = sig_with_round_bit[4:1];
    
    // Add 1 to significand if rounding bit is set
    wire [4:0] sig_rounded_temp = sig_before_round + round_bit;
    
    // Check for overflow after rounding
    wire overflow = (sig_rounded_temp == 5'b10000);
    
    // If overflow, shift right and increment exponent
    assign sig_final = overflow ? 4'b1000 : sig_rounded_temp[3:0];
    assign exp_final = overflow ? (exp_raw + 1) : exp_raw;
    
    // Final outputs
    assign E = exp_final;
    assign F = sig_final;

endmodule