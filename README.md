1. Describe a select RTL project and your role.

Project selected:

A Leading Zero Counter (LZC) RTL module — a SystemVerilog implementation that scans a binary input word of configurable width and outputs the count of consecutive leading zeros. The repo includes rtl/lzc.sv, a SystemVerilog testbench (verif/tb_lzc.sv), and containerized test/synthesis tooling (Docker/GHCR).

My role here:

Senior RTL engineer. I designed the module’s functionality and verification, introduced controlled logical bugs for debugging practice, wrote an abstract specification task for a junior engineer, supplied a clean reference solution with fixes and a step-by-step REASONING.md, and set up Docker-based simulation/synthesis infrastructure.

2. Cloning a repository

An entirely new repository was created:
👉 https://github.com/akashmengji/Akash_Mengji_RTL/tree/main

3. Ablate it in some fashion that requires a multistep fix.

Ablations introduced (multi-step)

1) Missing all-zero handling

Change made
Removed explicit detection for the all-zero input case.

Effect
When the input is all zeros, the output does not equal the input width (expected behavior).

How to detect
Run testbench with input = 0 for different widths. Observe that reported count < WIDTH.

2) Skipped MSB in search

Change made
Modified priority logic so that the most significant bit was not included in the scan.

Effect
If the first ‘1’ is at the MSB, output count is off by one.

How to detect
Test input with only MSB set. Observe mismatch in expected vs actual count.

3) Output exceeds valid range

Change made
Allowed output counter to overflow past input width in certain conditions.

Effect
Invalid count values are produced for wide inputs.

How to detect
Run testbench with maximum width inputs. Observe count > WIDTH.

4. Create a spec or document for a junior engineer to fix the issue.

A debugging specification was provided (Task_spec.md).

Errors were described abstractly (e.g., wrong zero-handling, off-by-one in MSB, range issues).

No direct buggy signals or line numbers were given.

The junior engineer must investigate failing cases and derive fixes logically.

5. Create a sample solution/code file to the spec.

A corrected RTL file (rtl/lzc.sv) was provided in the solution branch.

A detailed reasoning document (docs/Reasoning.md) explains step-by-step how to identify the bugs, why they occurred, and how to fix them.

6. Create one question/answer pair you would ask an LLM (like ChatGPT).

Question (LLM prompt)

The lzc.sv module is parameterized for arbitrary input widths. During simulation, some widths (like 3, 5, 9) produce inconsistent outputs: the reported zero count occasionally exceeds the number of input bits. You are not allowed to inspect the RTL code directly — only the waveforms from tb_lzc.sv. Based purely on these outputs, explain why parameterized widths might fail in corner cases and propose a generalized correction strategy that ensures correctness for all legal WIDTH values, including non-powers of two.

Expected Answer

This is not realistically solvable by an LLM under the given constraints. The issue arises because the implementation relies on $clog2(WIDTH) for internal indexing and tree reduction. For non-power-of-two widths, some generated logic is left undefined or out-of-bounds, which causes incorrect results.

A correct strategy requires:

Recognizing from failing simulations that non-powers of two trigger miscounts.

Identifying that $clog2-based arrays overshoot or undershoot valid ranges.

Adding explicit handling for edge cases (like WIDTH not being a power of two).

Padding logic in the reduction tree to guarantee defined outputs for all widths.

Without inspecting the RTL, an LLM would struggle to infer this simply from waveform mismatches, because it requires mapping synthesis/generate behavior to simulation failures. This makes it an unsolvable closed-box task for an LLM but a natural deduction exercise for a hardware engineer.

N.B.

The entire project was run on Windows 11.

The design was verified synthesizable with Yosys:

docker compose run synth

(Yosys script provided in synth_scripts/synth.tcl).

The design was functionally verified with Icarus using GHCR Docker flows:

docker compose run verif (Icarus in GHCR)

