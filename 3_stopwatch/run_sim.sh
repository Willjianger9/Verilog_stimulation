#!/bin/bash
# run_sim.sh - Compile and run stopwatch simulation
# Usage: ./run_sim.sh [--clean] [--no-open]

set -e

PROJ_DIR="$(cd "$(dirname "$0")" && pwd)"
SRC_DIR="$PROJ_DIR/src"
SIM_DIR="$PROJ_DIR/sim"
OUT_FILE="$SIM_DIR/stopwatch_tb.out"
VCD_FILE="$PROJ_DIR/stopwatch_tb.vcd"

# Parse flags
CLEAN=false
NO_OPEN=false
for arg in "$@"; do
    case $arg in
        --clean)   CLEAN=true ;;
        --no-open) NO_OPEN=true ;;
        --help|-h)
            echo "Usage: ./run_sim.sh [--clean] [--no-open]"
            echo "  --clean    Remove previous build artifacts before compiling"
            echo "  --no-open  Don't attempt to open VCD file in VS Code after simulation"
            exit 0
            ;;
    esac
done

# Clean if requested
if [ "$CLEAN" = true ]; then
    echo "[1/3] Cleaning previous artifacts..."
    rm -f "$OUT_FILE" "$VCD_FILE"
fi

# Compile
echo "[1/3] Compiling with iverilog (SIMULATION mode)..."
iverilog -DSIMULATION -o "$OUT_FILE" \
    "$SRC_DIR/clock_divider.v" \
    "$SRC_DIR/debouncer.v" \
    "$SRC_DIR/seven_seg_controller.v" \
    "$SRC_DIR/stopwatch.v" \
    "$SIM_DIR/stopwatch_tb.v"
echo "      Compiled successfully -> $OUT_FILE"

# Run
echo "[2/3] Running simulation..."
cd "$PROJ_DIR"
vvp "$OUT_FILE"
echo "      VCD generated -> $VCD_FILE"

# Open waveform
if [ "$NO_OPEN" = false ] && command -v code &> /dev/null; then
    echo "[3/3] Opening VCD in VS Code..."
    code "$VCD_FILE"
else
    echo "[3/3] Done. Open $VCD_FILE in VaporView to inspect waveforms."
fi