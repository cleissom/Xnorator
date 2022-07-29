/* verilator lint_off UNUSED */
/* verilator lint_off UNDRIVEN */

module flush_output_fsm #(
  parameter  int unsigned TPO       = 8,
  localparam int unsigned AddrWidth = $clog2(TPO)
) (
  input  logic        clk_i,
  input  logic        rst_ni,
  
  input  logic        flush_req_i,
  input  logic        transfer_output_ack_i,

  output logic [AddrWidth-1:0] reg_addr_o,
  output logic                 flush_we_o,
  output logic                 clean_we_o,
  output logic                 flush_ack_o,
  output logic                 transfer_output_req_o
);

  logic [31:0] counter;
  assign reg_addr_o = counter[AddrWidth-1:0];
  
  typedef enum {
    StIdle, StInitFlush, StFlush, StInitClean, StClean, StDone, StWait
  } state_e;

  state_e state_d, state_q;

  // Register the state
  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
    state_q <= StIdle;
    end else begin
    state_q <= state_d;
    end
  end

  // Next state logic
  always_comb begin
    state_d = state_q;
    unique case (state_q)
    StIdle:  if (flush_req_i) state_d = StInitFlush;
    StInitFlush:  state_d = StFlush;
    StFlush: if (counter >= TPO) state_d = StInitClean;
    StInitClean:  state_d = StClean;
    StClean: if (counter >= TPO) state_d = StDone;
    StDone:  state_d = StWait;
    StWait:  if (transfer_output_ack_i) state_d = StIdle;
    default: state_d = StIdle;
    endcase
  end

  // Output logic
  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      flush_we_o            <= '0;
      clean_we_o            <= '0;
      flush_ack_o           <= '0;
      transfer_output_req_o <= '0;
      end else begin
      flush_we_o            <= '0;
      clean_we_o            <= '0;
      flush_ack_o           <= '0;
      transfer_output_req_o <= '0;
      case (state_d)
        StInitFlush: begin
          counter     <= '0;
          flush_we_o  <= '1;
        end
        StFlush: begin
          counter     <= counter + 1;
          flush_we_o  <= '1;
        end
        StInitClean: begin
          counter     <= '0;
          clean_we_o  <= '1;
        end
        StClean: begin
          counter     <= counter + 1;
          clean_we_o  <= '1;
        end
        StDone: begin
          flush_ack_o <= '1;
        end
        StWait: begin
          transfer_output_req_o <= '1;
        end
      endcase
    end
  end

endmodule
/* verilator lint_on UNUSED */
/* verilator lint_on UNDRIVEN */
