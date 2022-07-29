/* verilator lint_off UNUSED */
/* verilator lint_off UNDRIVEN */

module loop_control_fsm #(
  parameter int unsigned TPO = 8,
  parameter int unsigned KS = 3
) (
  input  logic        clk_i,
  input  logic        rst_ni,

  input  logic        start_i,
  input  logic [31:0] iw_i,
  input  logic [31:0] ih_i,
  input  logic [31:0] ic_i,
  input  logic [31:0] oc_i,
  input  logic        padding_i,
  input  logic        flush_ack_i,
  input  logic        load_input_ack_i,
  input  logic        load_weight_ack_i,

  output logic [31:0] oci_o,
  output logic [31:0] ico_o,
  output logic [31:0] wi_o,
  output logic [31:0] wj_o,
  output logic [31:0] i_o,
  output logic [31:0] j_o,
  output logic [31:0] oco_o,
  output logic        flush_req_o,
  output logic        load_input_req_o,
  output logic        load_weight_req_o,
  output logic        exec_o,
  output logic        end_o
);

  typedef enum {
    StIdle, StReset, StLoadInput, StLoadWeight, StStart, StOFMI, StIFMO, StKw, StKh, StTpoDone, StFMW, StFMH, StOFMO, StEnd
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

  // Condition signals
  logic OFMI_done, IFMO_done, Kw_done, Kh_done, FMW_done, FMH_done, OFMO_done;
  assign OFMI_done = oci_o >= TPO-1;
  assign IFMO_done = OFMI_done && (ico_o >= (ic_i >> 5)-1);
  assign Kw_done = IFMO_done && (wi_o >= KS-1);
  assign Kh_done = Kw_done && (wj_o >= KS-1);
  assign FMW_done = Kh_done && ($signed(i_o) >= $signed(padding_i ? iw_i-2 : iw_i-3));
  assign FMH_done = FMW_done && ($signed(j_o) >= $signed(padding_i ? ih_i-2 : ih_i-3));
  assign OFMO_done = FMH_done && (oco_o >= ((oc_i >> $clog2(TPO))-1));

  // Next state logic
  always_comb begin
    state_d = state_q;
    unique case (state_q)
      StIdle:
        if (start_i) begin
          state_d = StReset;
        end
      StReset:      state_d = StLoadInput;
      StLoadInput:  if (load_input_ack_i) state_d = StLoadWeight;
      StLoadWeight: if (load_weight_ack_i) state_d = StStart;
      StStart: state_d = StOFMI;
      StOFMI: 
        if (Kh_done) state_d = StTpoDone; 
        else if (Kw_done) state_d = StKh; 
        else if (IFMO_done) state_d = StKw; 
        else if (OFMI_done) state_d = StIFMO; 
        else state_d = StOFMI; 
      StIFMO:     state_d = StOFMI;
      StKw:       state_d = StOFMI;
      StKh:       state_d = StOFMI;
      StTpoDone:  
        if (flush_ack_i) begin
          if (OFMO_done) state_d = StEnd; 
          else if (FMH_done) state_d = StOFMO; 
          else if (FMW_done) state_d = StFMH; 
          else state_d = StFMW; 
        end
      StFMW:       state_d = StOFMI;
      StFMH:       state_d = StOFMI;
      StOFMO:      state_d = StLoadWeight;
      StEnd:       state_d = StIdle;
        
      default: state_d = StIdle;
    endcase
  end

  // Output logic
  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      end_o       <= '0;
      oci_o       <= '0;
      ico_o       <= '0;
      wi_o        <= '0;
      wj_o        <= '0;
      i_o         <= '0;
      j_o         <= '0;
      oco_o       <= '0;
      exec_o      <= '0;
      flush_req_o <= '0;
      load_input_req_o  <= '0;
      load_weight_req_o <= '0;
    end else begin
      flush_req_o       <= '0;
      load_input_req_o  <= '0;
      load_weight_req_o <= '0;
      exec_o <= '0;
      case (state_d)
        StReset: begin
          end_o   <= '0;
          oci_o   <= '0;
          ico_o   <= '0;
          oco_o   <= '0;
          wi_o    <= '0;
          wj_o    <= '0;
          if(padding_i) begin
            i_o     <= -1;
            j_o     <= -1;
          end
          else begin
            i_o     <= '0;
            j_o     <= '0;
          end

        end
        StLoadInput: begin
          load_input_req_o  <= 'b1;
        end
        StLoadWeight: begin
          load_weight_req_o <= 'b1;
        end
        StStart: begin
          exec_o  <= 'b1;
        end
        StOFMI: begin
          exec_o  <= 'b1;
          oci_o   <= oci_o + 1;
        end
        StIFMO: begin
          exec_o  <= 'b1;
          oci_o   <= '0;
          ico_o   <= ico_o + 1;
        end
        StKw: begin
          exec_o  <= 'b1;
          oci_o   <= '0;
          ico_o   <= '0;
          wi_o    <= wi_o + 1;
        end
        StKh: begin
          exec_o  <= 'b1;
          oci_o   <= '0;
          ico_o   <= '0;
          wi_o    <= '0;
          wj_o    <= wj_o + 1;
        end
        StTpoDone: begin
          flush_req_o <= 'b1;
        end
        StFMW: begin
          exec_o  <= 'b1;
          oci_o   <= '0;
          ico_o   <= '0;
          wi_o    <= '0;
          wj_o    <= '0;
          i_o     <= i_o + 1;
        end
        StFMH: begin
          exec_o  <= 'b1;
          oci_o   <= '0;
          ico_o   <= '0;
          wi_o    <= '0;
          wj_o    <= '0;
          i_o     <= padding_i ? -1 : '0;
          j_o     <= j_o + 1;
        end
        StOFMO: begin
          oci_o   <= '0;
          ico_o   <= '0;
          wi_o    <= '0;
          wj_o    <= '0;
          i_o     <= '0;
          j_o     <= padding_i ? -1 : '0;
          oco_o   <= oco_o + 1;
        end
        StEnd: begin
          end_o   <= 'b1;
        end
      endcase
    end
  end

endmodule
/* verilator lint_on UNUSED */
/* verilator lint_on UNDRIVEN */
