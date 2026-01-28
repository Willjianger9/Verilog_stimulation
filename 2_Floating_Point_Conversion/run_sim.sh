#!/bin/bash
# Simple script to run the FPCVT simulation

cd "$(dirname "$0")/sim"
echo "Compiling Verilog..."
iverilog -o FPCVT_sim ../src/FPCVT.v FPCVT_tb.v

if [ $? -eq 0 ]; then
    echo ""
    echo "Running simulation..."
    echo "================================"
    vvp FPCVT_sim
    echo "================================"
else
    echo "Compilation failed!"
    exit 1
fi
