`timescale 1ns / 1ps

module debouncer(
    input  wire clk,      // sampling clock (~500 Hz)
    input  wire rst,      // active-high reset
    input  wire noisy_in, // raw button/switch input
    output reg  clean_out // debounced output
);

    // Two flip-flop synchronizer to handle metastability
    reg sync_0, sync_1;

    initial begin
        sync_0 = 0;
        sync_1 = 0;
    end

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            sync_0 <= 0;
            sync_1 <= 0;
        end else begin
            sync_0 <= noisy_in;
            sync_1 <= sync_0;
        end
    end

    // Debounce counter - require stable input for multiple cycles
    reg [3:0] count;
    reg       state;

    initial begin
        count     = 0;
        state     = 0;
        clean_out = 0;
    end

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            count     <= 0;
            state     <= 0;
            clean_out <= 0;
        end else begin
            if (sync_1 == state) begin
                count <= 0;
            end else begin
                count <= count + 1;
                if (count == 4'hF) begin
                    state     <= sync_1;
                    clean_out <= sync_1;
                end
            end
        end
    end

endmodule