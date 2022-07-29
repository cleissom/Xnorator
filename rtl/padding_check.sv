/* verilator lint_off UNUSED */
/* verilator lint_off UNDRIVEN */

module padding_check (
    input  logic [31:0] loop_i_i,
    input  logic [31:0] loop_j_i,
    input  logic [31:0] loop_wi_i,
    input  logic [31:0] loop_wj_i,
    input  logic [31:0] iw_i,
    input  logic [31:0] ih_i,
    input  logic [31:0] rdata_i,
    
    output logic [31:0] data_o
  );
  
    logic negative_index, higher_size, condition;
    assign negative_index = ($signed(loop_i_i) + $signed(loop_wi_i) == -1) | ($signed(loop_j_i) + $signed(loop_wj_i) == -1);
    assign higher_size = ($signed($signed(loop_i_i) + $signed(loop_wi_i)) >= $signed(iw_i)) | ($signed($signed(loop_j_i) + $signed(loop_wj_i)) >= $signed(ih_i));
    assign condition = negative_index | higher_size;

    assign data_o = condition ? '0 : rdata_i;

endmodule
/* verilator lint_on UNUSED */
/* verilator lint_on UNDRIVEN */
