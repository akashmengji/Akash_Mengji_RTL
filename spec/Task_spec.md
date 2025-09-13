# Debug Reasoning – LZC (Leading/Trailing Zero Counter)

## Objective

The Leading/Trailing Zero Counter (LZC) module determines how many consecutive zeros appear in an input vector, depending on the selected mode. It must also correctly handle don’t-care (`x`) and high-impedance (`z`) inputs, as well as special cases when the input width is very small.  
The goal was to resolve functional mispredictions and synthesis incompatibilities observed during testing.

* * *

## File to Work On

*   **RTL Source**: `rtl/lzc.sv`
    

* * *

## Test Harness

*   **Cocotb testbench**: `test_lzc.py`
    
*   **SystemVerilog testbench**: `verif/tb_lzc.sv`
    

The testbenches stress both leading and trailing zero modes across different widths, including edge cases such as all-zero input, all-one input, single-bit set, and inputs containing unknown or high-impedance values.

* * *

## Observed Symptoms / Issues

1.  **Degenerate single-bit case**
    
    *   When the module was reduced to a single-bit input, the reported count did not always reflect the actual number of zeros.
        
    *   In this configuration, the “empty” signal was also not behaving consistently with the intended meaning of “all bits zero.”
        
2.  **Two-bit case and procedural style**
    
    *   In the special-case logic for a two-bit input, continuous assignment style was mixed with procedural logic.
        
    *   This caused synthesis tools to raise warnings and did not align with recommended coding practices.
        
3.  **Vector reversal for leading zero mode**
    
    *   When operating in leading-zero mode, the reversal of the input vector accessed positions beyond the valid range.
        
    *   This led to inconsistent counts, especially when the input width increased.
        
4.  **Empty detection for larger widths**
    
    *   For general cases, the expression used to detect whether the input was entirely zero was inverted or incorrectly tied to intermediate nodes of the reduction tree.
        
    *   As a result, some patterns were marked as “non-empty” when in fact they contained only zeros, and vice versa.
        

* * *

## Requirements

1.  **Accurate zero counting**
    
    *   The counter must return correct values for both leading and trailing modes across all input widths.
        
    *   Special cases such as width one and width two must be consistent with the general design.
        
2.  **Consistent empty signal**
    
    *   The signal that flags when the entire vector is zero should always match the actual state of the cleaned input vector.
        
3.  **Coding style compliance**
    
    *   The design should avoid mixing continuous assignments within procedural blocks.
        
    *   Indexing should never go out of range.
        

* * *

## Debug Reasoning

*   **For the single-bit case**, the logic was initially tied too closely to the input bit itself rather than expressing the intended “zero count.” By reframing the behavior in terms of what the output should represent, the condition was corrected to reflect whether the single bit was zero or one.
    
*   **For the two-bit case**, the style of assignment conflicted with synthesis expectations. Converting the assignments to purely procedural form within a combinational block aligned the implementation with best practice while preserving the same functionality.
    
*   **For vector reversal**, closer inspection of the indexing formula revealed that it attempted to read elements beyond the array boundary. Adjusting the expression to properly flip the vector eliminated the out-of-bounds access and produced correct counts for leading zeros.
    
*   **For empty detection**, the earlier implementation tried to reuse signals from the reduction tree, which caused inverted behavior in some scenarios. Simplifying the check to directly compare the cleaned input vector against all-zeros resolved the issue and made the design easier to reason about.
    

* * *

## Deliverables

1.  **Corrected RTL**
    
    *   `rtl/lzc.sv` with revised logic and consistent style.
        
2.  **Debug Reasoning**
    
    *   This document: `docs/REASONING.md`.
        
3.  **Verification Evidence**
    
    *   Cocotb test results showing correct zero counts across modes and widths.
        
    *   SystemVerilog testbench passing for corner cases.