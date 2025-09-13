module tb_lzc;
  // Parameters
  //parameter int unsigned WIDTH = 8;
  parameter int unsigned WIDTH = 53;
  parameter bit MODE = 1'b0;  // 0 for trailing zeros, 1 for leading zeros
  parameter bit XZ_TREAT = 1'b1;  // 0: Treat X/Z as 0, 1: Treat X/Z as 1
  parameter int unsigned CNT_WIDTH = (WIDTH > 1) ? WIDTH : 1;
  // Inputs
  logic [WIDTH-1:0] in_i;
  // Outputs
  logic [CNT_WIDTH-1:0] cnt_o;
  logic empty_o;
  // Instantiate the DUT (Device Under Test)
  lzc #(
      .WIDTH(WIDTH),
      .MODE(MODE),
      .XZ_TREAT(XZ_TREAT),
      .CNT_WIDTH(CNT_WIDTH)
  ) dut (
      .in_i(in_i),
      .cnt_o(cnt_o),
      .empty_o(empty_o)
  );
  initial begin
    // Dump waves
    $dumpfile("test.vcd");
    $dumpvars(0, tb_lzc);
  end
  // Task to run a test case
  task run_test_case(input logic [WIDTH-1:0] test_in,  // Input vector for test case
                     input int expected_cnt_o,  // Expected count of zeros
                     input bit expected_empty_o,  // Expected empty flag
                     input string case_name            // Name of the test case (for display)
  );
    begin
      in_i = test_in;
      #10;  // Wait for the output signals to stabilize

      // Check cnt_o and display values
      if (cnt_o !== expected_cnt_o) begin
        $error("Test failed: %s (cnt_o mismatch: expected = %0d, actual = %0d)", case_name,
               expected_cnt_o, cnt_o);
      end else begin
        $display("Test passed: %s (cnt_o is correct, actual = %0d, expected = %0d)", case_name,
                 cnt_o, expected_cnt_o);
      end
      // Check empty_o and display values
      if (empty_o !== expected_empty_o) begin
        $error("Test failed: %s (empty_o mismatch: expected = %0b, actual = %0b)", case_name,
               expected_empty_o, empty_o);
      end else begin
        $display("Test passed: %s (empty_o is correct, actual = %0b, expected = %0b)", case_name,
                 empty_o, expected_empty_o);
      end
    end

  endtask
  // Enable waveform dump
  initial begin
    $dumpfile("dump.vcd");  // VCD file name
    $dumpvars(0, tb_lzc);  // Dump all variables in this module
  end
  // Testbench Procedure
  initial begin
    $display("Starting testbench for LZC...");

    // Case 1: All zeros input
    //run_test_case({WIDTH{1'bx}}, WIDTH, 1'b1, "All Zeros");
    //#50;
    // Case 2: All ones input
    //run_test_case({WIDTH{1'b1}}, 0, 1'b0, "All Ones");

    run_test_case(
        64'b1100_0101_0001_1111_0010_0011_1010_1011_1100_1011_1001_0111_1000_0010_0000_0000, 9,
        1'b0, "Valid 64-bit data");

    run_test_case(53'b1001_0100_0001_1100_1100_1101_0111_1010_1111_0101_0100_0011_0010_0, 2, 1'b0,
                  "Valid 53-bit data");

    /* Case 3: Mixed 0s and 1s
    if (MODE == 1'b0) begin
      //run_test_case(8'b0011_0000, 4, 1'b0, "Mixed 0s and 1s (Trailing Zeros)");
     // #10;
      run_test_case(8'b0x0z_x000, 3, 1'b0, "Mixed 0s and 1s (Trailing Zeros)");
    end else begin
      run_test_case(8'b0011_0000, 2, 1'b0, "Mixed 0s and 1s (Leading Zeros)");
    end */

    #100;  // Ensure simulation runs for enough time
    $finish;
  end
endmodule
