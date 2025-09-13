Debugging & Fix Log – Leading Zero Counter (LZC)


1. Observations

During RTL simulation with the provided SystemVerilog testbench, the following issues were observed:

Incorrect count for all-zero inputs

When the input word is entirely zeros, the module does not return the expected count (equal to the input width).

Off-by-one errors near MSB

If the first 1 appears at the most significant bit, the reported count is one less than correct.

Output exceeds valid range

For certain wide inputs, the output count exceeds the maximum value allowed by the input width.

2. Investigation
Step 1 – Zero input behavior

The all-zero case was not explicitly handled in the RTL.

As a result, the priority logic produced a default invalid count.

Step 2 – MSB handling

The logic responsible for scanning from the most significant end skipped checking the MSB properly.

This created off-by-one errors whenever the MSB was set.

Step 3 – Parameterization issues

The design allowed the count value to extend beyond the valid range for the selected input width.

Missing boundary checks caused unpredictable behavior in these edge cases.

3. Fix Implementation

Added explicit detection for the all-zero input case, forcing the output count to equal the full input width.

Corrected the MSB handling so that the highest-order bit is included in the priority search.

Adjusted the design to constrain the output count within the legal range [0 : WIDTH] using proper parameterization.

4. Verification

The updated RTL was tested with:

All-zero inputs

Inputs with only the MSB set

Random single-bit and multi-bit patterns

Full-width all-ones inputs

All test cases produced correct counts, confirming that the fixes resolved the earlier inconsistencies.

5. Notes & Recommendations

The module is now synthesizable, parameterized by input width, and robust against corner cases.

This version is suitable for integration into datapaths requiring normalization or priority detection.

Future improvements may include extending the design to support a Leading One Detector (LOD) using similar logic.