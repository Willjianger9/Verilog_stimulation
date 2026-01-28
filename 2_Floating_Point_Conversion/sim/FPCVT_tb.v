`timescale 1ns / 1ps

module FPCVT_tb();

    // Inputs to the Unit Under Test (UUT)
    reg [11:0] D;

    // Outputs from the UUT
    wire S;
    wire [2:0] E;
    wire [3:0] F;

    // Instantiate the Unit Under Test (UUT)
    // Ensure the port names match your module definition
    FPCVT uut (
        .D(D),
        .S(S),
        .E(E),
        .F(F)
    );

    initial begin
        // Initialize Inputs
        D = 0;

        // Wait 100 ns for global reset to finish
        #100;
       
        // Display header for console output
        $display("Input D    | S | E   | F    | Notes");
        $display("-----------|---|-----|------|-------");

        // Test Case 1: Zero
        D = 12'h000; #10;
        $display("%h (%d) | %b | %b | %b | Zero check", D, $signed(D), S, E, F);

        // Test Case 2: Small positive value
        D = 12'h007; #10;
        $display("%h (%d) | %b | %b | %b | Small positive", D, $signed(D), S, E, F);

        // Test Case 3: Large positive value (Requires normalization)
        D = 12'h3FF; #10;
        $display("%h (%d) | %b | %b | %b | Large positive", D, $signed(D), S, E, F);

        // Test Case 4: Small negative value
        D = 12'hFFF; #10; // -1 in 2's complement
        $display("%h (%d) | %b | %b | %b | Small negative", D, $signed(D), S, E, F);

        // Test Case 5: Large negative value
        D = 12'h800; #10; // -2048 (min value)
        $display("%h (%d) | %b | %b | %b | Max negative", D, $signed(D), S, E, F);

        // Test Case 6: Random value
        D = 12'h0A5; #10;
        $display("%h (%d) | %b | %b | %b | Random middle", D, $signed(D), S, E, F);

        #50;
        $display("Simulation Finished.");
        $finish;
    end
     
endmodule