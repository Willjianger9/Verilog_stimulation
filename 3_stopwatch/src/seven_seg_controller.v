`timescale 1ns / 1ps

module seven_seg_controller(
    input  wire       clk_mux,    // ~500 Hz multiplexing clock
    input  wire       rst,
    input  wire [3:0] digit3,     // leftmost digit (minutes tens)
    input  wire [3:0] digit2,     // minutes ones
    input  wire [3:0] digit1,     // seconds tens
    input  wire [3:0] digit0,     // rightmost digit (seconds ones)
    input  wire       blank_min,  // blank minutes digits (for blink)
    input  wire       blank_sec,  // blank seconds digits (for blink)
    output reg  [6:0] seg,        // segment outputs (active low)
    output reg  [3:0] an          // anode outputs (active low)
);

    reg [1:0] sel;  // which digit is currently active
    reg [3:0] current_digit;
    reg       blank_current;

    initial sel = 0;

    // Cycle through 4 digits
    always @(posedge clk_mux or posedge rst) begin
        if (rst)
            sel <= 0;
        else
            sel <= sel + 1;
    end

    // Select current digit and blank signal
    always @(*) begin
        case (sel)
            2'b00: begin
                current_digit = digit0;
                an = 4'b1110;
                blank_current = blank_sec;
            end
            2'b01: begin
                current_digit = digit1;
                an = 4'b1101;
                blank_current = blank_sec;
            end
            2'b10: begin
                current_digit = digit2;
                an = 4'b1011;
                blank_current = blank_min;
            end
            2'b11: begin
                current_digit = digit3;
                an = 4'b0111;
                blank_current = blank_min;
            end
        endcase
    end

    // BCD to seven-segment decoder (active low: 0 = segment ON)
    // Segment mapping: seg[6:0] = {g, f, e, d, c, b, a}
    always @(*) begin
        if (blank_current) begin
            seg = 7'b1111111; // all segments off when blanked
        end else begin
            case (current_digit)
                4'd0: seg = 7'b1000000;
                4'd1: seg = 7'b1111001;
                4'd2: seg = 7'b0100100;
                4'd3: seg = 7'b0110000;
                4'd4: seg = 7'b0011001;
                4'd5: seg = 7'b0010010;
                4'd6: seg = 7'b0000010;
                4'd7: seg = 7'b1111000;
                4'd8: seg = 7'b0000000;
                4'd9: seg = 7'b0010000;
                default: seg = 7'b1111111;
            endcase
        end
    end

endmodule