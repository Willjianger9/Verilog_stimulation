# CS M152A Lab 2 - Floating Point Conversion

## Project Structure

```
lab2_fpcvt/
├── README.md           # This file
├── src/
│   └── FPCVT.v         # Main floating point converter module
└── sim/
    └── FPCVT_tb.v      # Testbench (tests all 4096 inputs)
```

## Module Specification

### FPCVT (Floating Point Converter)

**Inputs:**
- `D[11:0]` - 12-bit signed integer (two's complement)

**Outputs:**
- `S` - Sign bit (1 bit)
- `E[2:0]` - Exponent (3 bits)
- `F[3:0]` - Significand/Mantissa (4 bits)

**Value Formula:** `V = (-1)^S × F × 2^E`

## Setting Up in Vivado

1. Open Xilinx Vivado
2. Create a new RTL project
3. Add `src/FPCVT.v` as a design source
4. Add `sim/FPCVT_tb.v` as a simulation source
5. Run behavioral simulation

## Implementation Checklist

- [ ] Stage 1: Two's complement to sign-magnitude conversion
  - [ ] Extract sign bit
  - [ ] Calculate absolute value
  - [ ] Handle -2048 special case

- [ ] Stage 2: Leading zero count & significand extraction
  - [ ] Implement priority encoder for leading zeros
  - [ ] Map leading zeros to exponent (1→7, 2→6, ..., ≥8→0)
  - [ ] Extract 4-bit significand based on exponent
  - [ ] Extract 5th bit for rounding

- [ ] Stage 3: Rounding
  - [ ] Round up if 5th bit is 1
  - [ ] Handle significand overflow (1111 + 1 = 10000)
  - [ ] Handle exponent overflow (clamp to max)

## Key Test Cases

| Input (Dec) | Input (Binary)   | Expected Output |
|-------------|------------------|-----------------|
| 0           | 000000000000     | S=0, E=000, F=0000 |
| 422         | 000110100110     | S=0, E=101, F=1101 |
| -422        | 111001011010     | S=1, E=101, F=1101 |
| 125         | 000001111101     | S=0, E=100, F=1000 |
| 2047        | 011111111111     | S=0, E=111, F=1111 |
| -2048       | 100000000000     | S=1, E=111, F=1000 |

## Submission

1. Zip the entire Vivado project folder
2. Upload to course website
3. Submit lab report separately
