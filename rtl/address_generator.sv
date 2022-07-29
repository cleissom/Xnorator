/* verilator lint_off UNUSED */
/* verilator lint_off UNDRIVEN */

module address_generator #(
    parameter int unsigned KS = 3
  ) (
    input        [31:0] iw_i,
    input        [31:0] ih_i,
    input        [31:0] ic_i,
    // input        [31:0] oc_i,
  
    input        [31:0] oci_i,
    input        [31:0] ico_i,
    input        [31:0] wi_i,
    input        [31:0] wj_i,
    input        [31:0] i_i,
    input        [31:0] j_i,
    // input        [31:0] oco_i,

    output logic [31:0] index_input_o,
    output logic [31:0] index_weight_o,
    output logic [31:0] index_output_o
  );
  
    logic [31:0] i_width_position;
    logic [31:0] i_height_position;
    logic [31:0] i_width_size;
    logic [31:0] i_channel_position;
    logic [31:0] i_channel_size;

    assign i_width_position = (i_i + wi_i);
    assign i_height_position = (j_i + wj_i);
    assign i_width_size = iw_i;
    assign i_channel_position = ico_i;
    assign i_channel_size = (iw_i*ih_i);
    assign index_input_o = i_width_position + (i_height_position * i_width_size) + (i_channel_position * i_channel_size);

    logic [31:0] w_width_position;
    logic [31:0] w_height_position;
    logic [31:0] w_width_size;
    logic [31:0] w_channel_position;
    logic [31:0] w_channel_size;
    logic [31:0] w_filter_position;
    logic [31:0] w_filter_size;

    assign w_width_position = wi_i;
    assign w_height_position = wj_i;
    assign w_width_size = KS;
    assign w_channel_position = ico_i;
    assign w_channel_size = KS*KS;
    assign w_filter_position = oci_i;
    assign w_filter_size = KS*KS * (ic_i >> 5);
    assign index_weight_o = w_width_position + (w_height_position * w_width_size) + (w_channel_position * w_channel_size) + (w_filter_position * w_filter_size);

    assign index_output_o = oci_i;
  
  
  endmodule
  /* verilator lint_on UNUSED */
  /* verilator lint_on UNDRIVEN */
