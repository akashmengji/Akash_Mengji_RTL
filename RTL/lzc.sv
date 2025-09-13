module lzc #(

    parameter int unsigned WIDTH = 2,  /// The width of the input vector.

    parameter bit MODE = 1'b0,  /// Mode selection: 0 -> trailing zero, 1 -> leading zero

    parameter bit          XZ_TREAT = 1'b0, // If this 0 , the don't cares and z will be treated as 0s ; If this 1 , the don't cares and z will be treated as 1s

    parameter int unsigned CNT_WIDTH = (WIDTH > 32'd1) ? WIDTH : 32'd1 /// Width of the output signal with the zero count./// Dependent parameter. Do **not** change!
) (

    input logic [WIDTH-1:0] in_i,  /// Input vector to be counted.

    output logic [CNT_WIDTH-1:0] cnt_o,  /// Count of the leading / trailing zeros.

    output logic empty_o  /// Counter is empty: Asserted if all bits in in_i are zero.
);

  localparam int unsigned NumLevels = $clog2(WIDTH);

  logic [NumLevels-1:0] index_lut[WIDTH-1:0];
  logic [2**NumLevels-1:0] sel_nodes;
  logic [NumLevels-1:0] index_nodes[WIDTH-1:0];
  logic [WIDTH-1:0] in_tmp;
  logic [WIDTH-1:0] in_cleaned; // Treat X and Z states as 0 (can be modified to treat as 1 if required)

  always_comb begin
    for (int i = 0; i < WIDTH; i++) begin
      if (in_i[i] === 1'bx || in_i[i] === 1'bz) begin
        in_cleaned[i] = XZ_TREAT ? 1'b1 : 1'b0;

      end else begin
        in_cleaned[i] = in_i[i];  // Otherwise, use the original value

      end
    end
  end

  if (WIDTH == 1) begin : gen_degenerate_lzc // if blocks must involve continuous assignment statements ; Do follow this way of assignment in 'if' blocks (From Yosys POV)
    assign cnt_o[0] = in_cleaned[0];  //error 1
    assign empty_o  = in_cleaned[0];  //error 2
  end else if (WIDTH == 2) begin : special_case_lzc_2bit
    always_comb begin   // if blocks within 'always_comb' thread must not involve continuous assignment statements ; Do follow this way of assignment in 'always_comb' block (From Yosys POV)
      if (MODE) begin


        case (in_cleaned)  // Leading zero count for 2-bit data
          2'b00: cnt_o = 2;
          2'b01: cnt_o = 1;
          2'b10: cnt_o = 0;
          2'b11: cnt_o = 0;
        endcase
      end else begin

        case (in_cleaned)  // Trailing zero count for 2-bit data
          2'b00: cnt_o = 2;
          2'b01: cnt_o = 0;
          2'b10: cnt_o = 1;
          2'b11: cnt_o = 0;
        endcase
      end
      empty_o = (in_cleaned == 2'b00);  // Empty if all bits are zero
    end
  end else begin : gen_lzc


    always_comb begin : flip_vector  // reverse vector if required
      for (int unsigned i = 0; i < WIDTH; i++) begin
        in_tmp[i] = (MODE) ? in_cleaned[WIDTH-1+i] : in_cleaned[i];  //error 3
      end
    end


    for (
        genvar j = 0; j < WIDTH; j++
    ) begin : g_index_lut  // Initialize the index LUT ; Use continuous assignment statements in Generate for loops ; From Yosys POV
      assign index_lut[j] = (NumLevels)'(unsigned'(j));  // Use the value of 'j' directly for indexing
    end

    for (
        genvar level = 0; level < NumLevels; level++
    ) begin : g_levels  // Binary tree reduction using levels

      if (level == NumLevels - 1) begin : g_last_level
        for (genvar k = 0; k < (2 ** level); k++) begin : g_level

          if (k * 2 < WIDTH - 1) begin : g_reduce  // k = 0 to 25 // If two successive indices are still in the vector...
            assign sel_nodes[2**level-1+k] = in_tmp[k*2] | in_tmp[k*2+1];
            assign index_nodes[2 ** level - 1 + k] = (in_tmp[k * 2] == 1'b1) ? index_lut[k * 2] : index_lut[k * 2 + 1];
          end


          if (k * 2 == WIDTH - 1) begin : g_base // If only the first index is still in the vector (corner case for the last element)

            assign sel_nodes[2**level-1+k]   = in_tmp[k*2];
            assign index_nodes[2**level-1+k] = index_lut[k*2];
          end


          if (k * 2 > WIDTH - 1) begin : g_out_of_range  // If the index is out of range
            assign sel_nodes[2**level-1+k]   = 1'b0;
            assign index_nodes[2**level-1+k] = '0;
          end
        end
      end else begin : g_not_last_level
        for (genvar l = 0; l < (2 ** level); l++) begin : g_level

          assign sel_nodes[2 ** level - 1 + l] =   sel_nodes[2 ** (level + 1) - 1 + l * 2] | sel_nodes[2 ** (level + 1) - 1 + l * 2 + 1];
          assign index_nodes[2 ** level - 1 + l] = (sel_nodes[2 ** (level + 1) - 1 + l * 2] == 1'b1) ? index_nodes[2 ** (level + 1) - 1 + l * 2] : index_nodes[2 ** (level + 1) - 1 + l * 2 + 1];
        end
      end
    end

    always_comb begin
      if (in_cleaned == {WIDTH{1'b0}}) begin
        cnt_o = index_nodes[0] + 1;  // If the input is all zeros, assign maximum cnt_o value
      end else begin
        cnt_o = NumLevels > unsigned'(0) ? index_nodes[0] : {($clog2(WIDTH)) {1'b0}};
      end
    end

    assign empty_o = NumLevels > unsigned'(0) ? ~sel_nodes[0] : (|in_i);  //error 4
  end : gen_lzc

endmodule : lzc
