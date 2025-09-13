module lzc #(
    parameter int unsigned WIDTH = 2,
    parameter bit MODE = 1'b0,
    parameter bit XZ_TREAT = 1'b0,
    parameter int unsigned CNT_WIDTH = (WIDTH > 32'd1) ? WIDTH : 32'd1
) (
    input logic [WIDTH-1:0] in_i,
    output logic [CNT_WIDTH-1:0] cnt_o,
    output logic empty_o
);

  localparam int unsigned NumLevels = $clog2(WIDTH) - 1;

  logic [NumLevels-1:0] index_lut[WIDTH-1:0];
  logic [2**NumLevels-1:0] sel_nodes;
  logic [NumLevels-1:0] index_nodes[WIDTH-1:0];
  logic [WIDTH-1:0] in_tmp;
  logic [WIDTH-1:0] in_cleaned;


  always_comb begin
    for (int i = 0; i < WIDTH; i++) begin
      if (in_i[i] === 1'bx || in_i[i] === 1'bz) begin
        in_cleaned[i] <= XZ_TREAT ? 1'b1 : 1'b0;
      end else begin
        in_cleaned[i] <= in_i[i];
      end
    end
  end

  if (WIDTH == 1) begin : gen_degenerate_lzc
    assign cnt_o[0] = ~in_cleaned[0];
    assign empty_o  = ~in_cleaned[0];
  end else if (WIDTH == 2) begin : special_case_lzc_2bit
    always_comb begin
      if (MODE) begin
        case (in_cleaned)
          2'b00: cnt_o = 0;
          2'b01: cnt_o = 0;
          2'b10: cnt_o = 1;
          2'b11: cnt_o = 2;
        endcase
      end else begin
        case (in_cleaned)
          2'b00: cnt_o = 1;
          2'b01: cnt_o = 2;
          2'b10: cnt_o = 0;
          2'b11: cnt_o = 0;
        endcase
      end
      empty_o = (in_cleaned != 2'b00);
    end
  end else begin : gen_lzc

    always_comb begin : flip_vector
      for (int unsigned i = 0; i < WIDTH; i++) begin
        in_tmp[i] = (MODE) ? in_cleaned[WIDTH-1+i] : in_cleaned[i];
      end
    end

    for (genvar j = 0; j < WIDTH; j++) begin : g_index_lut
      assign index_lut[j] = (NumLevels)'(j);
    end

    for (genvar level = 0; level < NumLevels; level++) begin : g_levels

      if (level == NumLevels - 1) begin : g_last_level
        for (genvar k = 0; k < (2 ** level); k++) begin : g_level

          if (k * 2 < WIDTH - 1) begin : g_reduce
            assign sel_nodes[2**level-1+k] = in_tmp[k*2] & in_tmp[k*2+1];
            assign index_nodes[2 ** level - 1 + k] = (in_tmp[k * 2] == 1'b1) ? index_lut[k * 2 + 1] : index_lut[k * 2];
          end

          if (k * 2 == WIDTH - 1) begin : g_base
            assign sel_nodes[2**level-1+k]   = in_tmp[k*2];
            assign index_nodes[2**level-1+k] = index_lut[k*2];
          end

          if (k * 2 > WIDTH - 1) begin : g_out_of_range
            assign sel_nodes[2**level-1+k]   = 1'b1;
            assign index_nodes[2**level-1+k] = '1;
          end
        end
      end else begin : g_not_last_level
        for (genvar l = 0; l < (2 ** level); l++) begin : g_level
          assign sel_nodes[2 ** level - 1 + l] =   sel_nodes[2 ** (level + 1) - 1 + l * 2] & sel_nodes[2 ** (level + 1) - 1 + l * 2 + 1];
          assign index_nodes[2 ** level - 1 + l] = (sel_nodes[2 ** (level + 1) - 1 + l * 2] == 1'b1) ? index_nodes[2 ** (level + 1) - 1 + l * 2 + 1] : index_nodes[2 ** (level + 1) - 1 + l * 2];
        end
      end
    end

    always_comb begin
      if (in_cleaned == {WIDTH{1'b0}}) begin
        cnt_o = '0;
      end else begin

        cnt_o = index_nodes[0] - 1;
      end
    end


    assign empty_o = NumLevels > unsigned'(0) ? sel_nodes[0] : |in_i;
  end : gen_lzc

endmodule : lzc
