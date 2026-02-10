`timescale 1ns / 1ps

module stopwatch_tb;

    // =========================================================
    // Signals
    // =========================================================
    reg        clk;
    reg        btnR;    // RESET
    reg        btnL;    // PAUSE
    reg        sw_adj;  // ADJ switch
    reg        sw_sel;  // SEL switch
    wire [6:0] seg;
    wire [3:0] an;

    // =========================================================
    // DUT Instantiation
    // =========================================================
    stopwatch uut (
        .clk    (clk),
        .btnR   (btnR),
        .btnL   (btnL),
        .sw_adj (sw_adj),
        .sw_sel (sw_sel),
        .seg    (seg),
        .an     (an)
    );

    // =========================================================
    // Clock Generation (100 MHz -> 10ns period)
    // =========================================================
    initial clk = 0;
    always #5 clk = ~clk;

    // =========================================================
    // Internal signal access
    // =========================================================
    wire [5:0] sec_val = uut.sec_count;
    wire [5:0] min_val = uut.min_count;
    wire       paused_val = uut.paused;

    // =========================================================
    // Timing helpers
    // With SIMULATION dividers (CNT_1HZ=49, CNT_500HZ=4):
    //   clk_500hz period = 2 * 5 * 10ns = 100ns
    //   clk_1hz period   = 2 * 50 * 100ns = 10,000ns = 10us
    //   clk_2hz period   = 2 * 25 * 100ns = 5,000ns  = 5us
    //   debounce settle  = 16 * 100ns = 1,600ns ~ 2us
    // =========================================================
    // With SIMULATION dividers:
    //   en_1hz fires every 100 master clocks = 1000ns (1 per sim second)
    //   en_2hz fires every 50  master clocks = 500ns  (2 per sim second)
    //   clk_500hz period = 2 * 5 * 10ns = 100ns
    //   debounce = 18 cycles of clk_500hz = 1800ns
    //
    // NOTE: debounce_settle itself costs ~2 simulated seconds,
    //       so timing-sensitive checks must account for that.

    task wait_seconds;
        input integer n;
        begin
            #(n * 1_000);  // 1 sim "second" = 1000ns = 1us
        end
    endtask

    task debounce_settle;
        begin
            #2_000;  // 2us > 1.6us debounce time (~2 sim seconds)
        end
    endtask

    // =========================================================
    // Pass/fail tracking
    // =========================================================
    integer pass_count = 0;
    integer fail_count = 0;

    task check_exact;
        input [255:0] name;
        input integer exp_min, exp_sec, exp_paused;
        begin
            if (min_val === exp_min[5:0] &&
                sec_val === exp_sec[5:0] &&
                paused_val === exp_paused[0]) begin
                $display("  PASS: %0s | min=%0d sec=%0d paused=%0b",
                         name, min_val, sec_val, paused_val);
                pass_count = pass_count + 1;
            end else begin
                $display("  FAIL: %0s | expected min=%0d sec=%0d paused=%0b | got min=%0d sec=%0d paused=%0b",
                         name, exp_min, exp_sec, exp_paused,
                         min_val, sec_val, paused_val);
                fail_count = fail_count + 1;
            end
        end
    endtask

    task check_range;
        input [255:0] name;
        input integer min_lo, min_hi, sec_lo, sec_hi;
        begin
            if (min_val >= min_lo[5:0] && min_val <= min_hi[5:0] &&
                sec_val >= sec_lo[5:0] && sec_val <= sec_hi[5:0]) begin
                $display("  PASS: %0s | min=%0d sec=%0d (in range)",
                         name, min_val, sec_val);
                pass_count = pass_count + 1;
            end else begin
                $display("  FAIL: %0s | min=%0d sec=%0d not in min=[%0d,%0d] sec=[%0d,%0d]",
                         name, min_val, sec_val,
                         min_lo, min_hi, sec_lo, sec_hi);
                fail_count = fail_count + 1;
            end
        end
    endtask

    task check_true;
        input [255:0] name;
        input condition;
        begin
            if (condition) begin
                $display("  PASS: %0s | min=%0d sec=%0d paused=%0b",
                         name, min_val, sec_val, paused_val);
                pass_count = pass_count + 1;
            end else begin
                $display("  FAIL: %0s | min=%0d sec=%0d paused=%0b",
                         name, min_val, sec_val, paused_val);
                fail_count = fail_count + 1;
            end
        end
    endtask

    // =========================================================
    // Test Stimulus
    // =========================================================
    reg [5:0] saved_min, saved_sec;

    initial begin
        $dumpfile("stopwatch_tb.vcd");
        $dumpvars(0, stopwatch_tb);

        btnR = 0; btnL = 0; sw_adj = 0; sw_sel = 0;

        $display("");
        $display("========================================");
        $display("  Stopwatch Testbench");
        $display("========================================");

        // ---- Test 1: Reset ----
        $display("");
        $display("[Test 1] Reset");
        btnR = 1;
        debounce_settle;
        check_exact("Counters zeroed while reset held", 0, 0, 0);
        btnR = 0;
        debounce_settle;

        // ---- Test 2: Normal counting ----
        $display("");
        $display("[Test 2] Normal Counting");
        wait_seconds(5);
        check_range("~5 seconds elapsed", 0, 0, 3, 7);
        wait_seconds(5);
        check_range("~10 seconds elapsed", 0, 0, 8, 12);

        // ---- Test 3: Pause ----
        $display("");
        $display("[Test 3] Pause");
        btnL = 1;
        debounce_settle;
        btnL = 0;
        debounce_settle;
        // Now paused - save position AFTER pause takes effect
        saved_min = min_val;
        saved_sec = sec_val;
        wait_seconds(10);
        check_true("Counter frozen while paused",
                   (sec_val == saved_sec) && (min_val == saved_min));

        // ---- Test 4: Unpause ----
        $display("");
        $display("[Test 4] Unpause");
        saved_sec = sec_val;
        saved_min = min_val;
        btnL = 1;
        debounce_settle;
        btnL = 0;
        debounce_settle;
        wait_seconds(5);
        check_true("Counter resumed after unpause",
                   (sec_val > saved_sec) || (min_val > saved_min));

        // ---- Test 5: Reset to prepare for adjust ----
        $display("");
        $display("[Test 5] Reset before adjust tests");
        btnR = 1;
        debounce_settle;
        check_exact("Reset to 00:00", 0, 0, 0);
        btnR = 0;
        debounce_settle;

        // ---- Test 6: Adjust seconds (SEL=1) ----
        $display("");
        $display("[Test 6] Adjust Seconds (ADJ=1, SEL=1)");
        sw_adj = 1;
        sw_sel = 1;
        debounce_settle;
        wait_seconds(10);
        // 2Hz tick = every ~500ns sim time
        check_true("Seconds incrementing via 2Hz", sec_val > 0);
        check_true("Minutes still zero", min_val == 0);

        // ---- Test 7: Adjust minutes (SEL=0) ----
        $display("");
        $display("[Test 7] Adjust Minutes (ADJ=1, SEL=0)");
        sw_sel = 0;
        debounce_settle;
        // Save sec AFTER sel debounce settles so ticks go to minutes
        saved_sec = sec_val;
        wait_seconds(20);
        check_true("Minutes incrementing via 2Hz", min_val > 0);
        check_true("Seconds frozen during min adjust", sec_val == saved_sec);

        // ---- Test 8: Exit adjust -> normal ----
        $display("");
        $display("[Test 8] Exit Adjust -> Normal Mode");
        saved_min = min_val;
        saved_sec = sec_val;
        sw_adj = 0;
        debounce_settle;
        wait_seconds(5);
        check_true("Normal counting resumed",
                   (sec_val != saved_sec) || (min_val != saved_min));

        // ---- Test 9: Rollover (59->0 seconds, minute increment) ----
        $display("");
        $display("[Test 9] Second Rollover 59->0");
        btnR = 1;
        debounce_settle;
        btnR = 0;
        debounce_settle;
        // Run in normal mode long enough to guarantee rollover (>60 sim seconds)
        wait_seconds(62);
        check_true("Seconds rolled over, minutes incremented", min_val >= 1);

        // ---- Test 10: Final reset ----
        $display("");
        $display("[Test 10] Final Reset");
        btnR = 1;
        debounce_settle;
        check_exact("All counters zeroed", 0, 0, 0);
        btnR = 0;
        debounce_settle;

        // ---- Summary ----
        $display("");
        $display("========================================");
        $display("  %0d PASSED, %0d FAILED", pass_count, fail_count);
        if (fail_count == 0)
            $display("  ALL TESTS PASSED");
        else
            $display("  SOME TESTS FAILED");
        $display("========================================");
        $display("");

        $finish;
    end

endmodule