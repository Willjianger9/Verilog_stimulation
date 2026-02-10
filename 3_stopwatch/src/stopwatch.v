`timescale 1ns / 1ps

module stopwatch(
    input  wire       clk,    // 100 MHz master clock
    input  wire       btnR,   // RESET button (active high)
    input  wire       btnL,   // PAUSE button (active high)
    input  wire       sw_adj, // ADJ switch
    input  wire       sw_sel, // SEL switch (0=minutes, 1=seconds)
    output wire [6:0] seg,    // seven-segment cathode signals
    output wire [3:0] an      // seven-segment anode signals
);

    // =========================================================
    // Internal wires
    // =========================================================
    wire en_1hz, en_2hz, clk_500hz, clk_blink;
    wire rst_db, pause_db, adj_db, sel_db;

    // =========================================================
    // Clock Divider (enable pulses + toggle clocks)
    // =========================================================
    clock_divider u_clk_div (
        .clk_100mhz (clk),
        .rst         (1'b0),        // free-running
        .en_1hz      (en_1hz),      // 1-cycle pulse at 1Hz
        .en_2hz      (en_2hz),      // 1-cycle pulse at 2Hz
        .clk_500hz   (clk_500hz),   // toggle for display mux & debounce
        .clk_blink   (clk_blink)    // toggle for blink display
    );

    // =========================================================
    // Debouncers (still clocked by 500Hz toggle - fine for sampling)
    // =========================================================
    debouncer u_db_rst (
        .clk       (clk_500hz),
        .rst       (1'b0),
        .noisy_in  (btnR),
        .clean_out (rst_db)
    );

    debouncer u_db_pause (
        .clk       (clk_500hz),
        .rst       (1'b0),
        .noisy_in  (btnL),
        .clean_out (pause_db)
    );

    debouncer u_db_adj (
        .clk       (clk_500hz),
        .rst       (1'b0),
        .noisy_in  (sw_adj),
        .clean_out (adj_db)
    );

    debouncer u_db_sel (
        .clk       (clk_500hz),
        .rst       (1'b0),
        .noisy_in  (sw_sel),
        .clean_out (sel_db)
    );

    // =========================================================
    // Pause Toggle Logic (master clock domain)
    // =========================================================
    reg paused;
    reg pause_prev;

    initial begin
        paused     = 0;
        pause_prev = 0;
    end

    always @(posedge clk) begin
        if (rst_db) begin
            paused     <= 0;
            pause_prev <= 0;
        end else begin
            pause_prev <= pause_db;
            // Rising edge detection on debounced pause button
            if (pause_db && !pause_prev)
                paused <= ~paused;
        end
    end

    // =========================================================
    // Time Counters (master clock domain, using enable pulses)
    // =========================================================
    reg [5:0] sec_count;  // 0-59 seconds
    reg [5:0] min_count;  // 0-59 minutes

    initial begin
        sec_count = 0;
        min_count = 0;
    end

    always @(posedge clk) begin
        if (rst_db) begin
            sec_count <= 0;
            min_count <= 0;
        end else if (adj_db) begin
            // ---- Adjustment Mode ----
            if (en_2hz) begin
                if (sel_db) begin
                    // SEL=1: increment seconds
                    if (sec_count == 59)
                        sec_count <= 0;
                    else
                        sec_count <= sec_count + 1;
                end else begin
                    // SEL=0: increment minutes
                    if (min_count == 59)
                        min_count <= 0;
                    else
                        min_count <= min_count + 1;
                end
            end
        end else if (!paused) begin
            // ---- Normal Mode ----
            if (en_1hz) begin
                if (sec_count == 59) begin
                    sec_count <= 0;
                    if (min_count == 59)
                        min_count <= 0;
                    else
                        min_count <= min_count + 1;
                end else begin
                    sec_count <= sec_count + 1;
                end
            end
        end
    end

    // =========================================================
    // BCD Digit Extraction
    // =========================================================
    wire [3:0] sec_ones = sec_count % 10;
    wire [3:0] sec_tens = sec_count / 10;
    wire [3:0] min_ones = min_count % 10;
    wire [3:0] min_tens = min_count / 10;

    // =========================================================
    // Blink Logic for Adjustment Mode
    // =========================================================
    wire blank_min = adj_db && !sel_db && clk_blink;
    wire blank_sec = adj_db &&  sel_db && clk_blink;

    // =========================================================
    // Seven-Segment Display Controller
    // =========================================================
    seven_seg_controller u_display (
        .clk_mux   (clk_500hz),
        .rst       (rst_db),
        .digit3    (min_tens),
        .digit2    (min_ones),
        .digit1    (sec_tens),
        .digit0    (sec_ones),
        .blank_min (blank_min),
        .blank_sec (blank_sec),
        .seg       (seg),
        .an        (an)
    );

endmodule