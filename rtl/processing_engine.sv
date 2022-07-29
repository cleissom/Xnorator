/* verilator lint_off UNUSED */

module processing_engine #(
  parameter int unsigned TP = 8,
  localparam int unsigned OutputWidth = $clog2(TP)+1
) (
  input   logic [TP-1:0] data1_i,
  input   logic [TP-1:0] data2_i,
  input   logic [TP-1:0] mask_i,
  output  logic signed [OutputWidth-1:0] result_o
);
  logic [OutputWidth-1:0] popcount_result_o;
  logic [OutputWidth:0] sub;

  logic [TP-1:0] xnor_result, masked_result;
  
  assign xnor_result = ~(data1_i ^ data2_i);
  assign masked_result = mask_i & xnor_result;
  
  popcount #(
  .INPUT_WIDTH(TP)
  ) u_popcount (
    .data_i(masked_result),
    .popcount_o(popcount_result_o)
  );

  
  assign sub = {popcount_result_o, 1'b0} - TP[OutputWidth:0];
  assign result_o = sub[OutputWidth-1:0];
      
  

endmodule
/* verilator lint_on UNUSED */
