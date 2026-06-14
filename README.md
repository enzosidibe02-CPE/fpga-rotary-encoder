# CPE 3020 — FPGA Rotary Encoder (Basys-3 / VHDL)

A quadrature rotary-encoder interface for the **Digilent Basys-3** (Artix-7).
Turning the PmodENC moves a single lit LED along the 16-LED bar (one step per
detent); the 7-segment display shows **shaft angle** or **RPM**, toggled by the
encoder shaft button.

> Course: CPE 3020 — VHDL Design with FPGAs
> Author: Enzo Sidibe · Kennesaw State University · Prof. Scott Tippens · Fall 2025

## Behavior
- **Position** — one-hot LED tracks encoder position (0–15), wrapping.
- **Angle mode** — 7-seg shows `pos * 23` degrees; LED bar shows all-but-one;
  decimal point on a distinct anode.
- **RPM mode** — detents counted over a 0.5 s window, scaled (`*8`) to RPM.
- **Mode toggle** — rising edge on the shaft button flips angle ↔ rpm.

## Design
| File | Role |
|------|------|
| `src/basys3_top.vhd` | Top wrapper: reset + debounce of A/B/button, instantiates core |
| `src/rotary_encoder_core.vhd` | Synchronizers, quadrature decode, position/RPM/angle, BCD, 7-seg + LED drive |
| `src/basys3_rotary_top_TB.vhd` | Testbench: CW/CCW step procedures + button press |

The core expects a `SevenSegmentDriver` component and the top expects a
`debounce` component (course-provided) — add those sources to the Vivado project.

## Build
Vivado: add the `src/` files, supply the `SevenSegmentDriver` and `debounce`
modules plus the Basys-3 XDC constraints (clk = 100 MHz, btnC, JA Pmod pins),
then synthesize / implement / generate bitstream.
