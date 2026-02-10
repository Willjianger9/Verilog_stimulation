`timescale 1ns / 1ps

module clock_divider(
    input  wire clk_100mhz,  // 100 MHz master clock
    input  wire rst,          // active-high reset
    output reg  en_1hz,       // 1-cycle pulse at 1 Hz rate
    output reg  en_2hz,       // 1-cycle pulse at 2 Hz rate
    output reg  clk_500hz,    // ~500 Hz toggle for display mux & debounce
    output reg  clk_blink     // ~4 Hz toggle for blinking in adjust mode
);

    // Full-period counts (pulse once per full period, not half)
    // 100MHz / 1Hz = 100,000,000
    // 100MHz / 2Hz = 50,000,000
    // 100MHz / 500Hz = 200,000 -> toggle at 100,000
    // 100MHz / 4Hz = 25,000,000 -> toggle at 12,500,000

    `ifdef SIMULATION
        localparam CNT_1HZ_MAX   = 100 - 1;   // full period
        localparam CNT_2HZ_MAX   = 50 - 1;    // full period
        localparam CNT_500HZ     = 5 - 1;     // half period (toggle)
        localparam CNT_BLINK     = 12 - 1;    // half period (toggle)
    `else
        localparam CNT_1HZ_MAX   = 100_000_000 - 1;
        localparam CNT_2HZ_MAX   = 50_000_000 - 1;
        localparam CNT_500HZ     = 100_000 - 1;
        localparam CNT_BLINK     = 12_500_000 - 1;
    `endif

    reg [26:0] counter_1hz;
    reg [25:0] counter_2hz;
    reg [16:0] counter_500hz;
    reg [23:0] counter_blink;

    initial begin
        counter_1hz   = 0;
        counter_2hz   = 0;
        counter_500hz = 0;
        counter_blink = 0;
        en_1hz    = 0;
        en_2hz    = 0;
        clk_500hz = 0;
        clk_blink = 0;
    end

    // 1 Hz enable pulse (one master clock cycle wide)
    always @(posedge clk_100mhz or posedge rst) begin
        if (rst) begin
            counter_1hz <= 0;
            en_1hz <= 0;
        end else if (counter_1hz == CNT_1HZ_MAX) begin
            counter_1hz <= 0;
            en_1hz <= 1;
        end else begin
            counter_1hz <= counter_1hz + 1;
            en_1hz <= 0;
        end
    end

    // 2 Hz enable pulse (one master clock cycle wide)
    always @(posedge clk_100mhz or posedge rst) begin
        if (rst) begin
            counter_2hz <= 0;
            en_2hz <= 0;
        end else if (counter_2hz == CNT_2HZ_MAX) begin
            counter_2hz <= 0;
            en_2hz <= 1;
        end else begin
            counter_2hz <= counter_2hz + 1;
            en_2hz <= 0;
        end
    end

    // ~500 Hz toggle (for seven-segment display mux & debounce sampling)
    always @(posedge clk_100mhz or posedge rst) begin
        if (rst) begin
            counter_500hz <= 0;
            clk_500hz <= 0;
        end else if (counter_500hz == CNT_500HZ) begin
            counter_500hz <= 0;
            clk_500hz <= ~clk_500hz;
        end else begin
            counter_500hz <= counter_500hz + 1;
        end
    end

    // ~4 Hz blink toggle
    always @(posedge clk_100mhz or posedge rst) begin
        if (rst) begin
            counter_blink <= 0;
            clk_blink <= 0;
        end else if (counter_blink == CNT_BLINK) begin
            counter_blink <= 0;
            clk_blink <= ~clk_blink;
        end else begin
            counter_blink <= counter_blink + 1;
        end
    end

endmodule