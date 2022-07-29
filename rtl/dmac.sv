/* verilator lint_off UNUSED */
/* verilator lint_off UNDRIVEN */

module dmac #(
  parameter int unsigned TPO = 8,
  parameter int unsigned KS = 3
) (
  input  logic        clk_i,
  input  logic        rst_ni,
  
  input  logic        m_rvalid_i,
  input  logic        m_err_i,
  input  logic        m_gnt_i,
  input  logic [31:0] m_rdata_i,
  output logic        m_req_o,
  output logic        m_we_o,
  output logic [ 3:0] m_be_o,
  output logic [31:0] m_addr_o,
  output logic [31:0] m_wdata_o,
  
  input  logic        s_input_rvalid_i,
  input  logic [31:0] s_input_rdata_i,
  output logic        s_input_req_o,
  output logic        s_input_we_o,
  output logic [ 3:0] s_input_be_o,
  output logic [31:0] s_input_addr_o,
  output logic [31:0] s_input_wdata_o,

  input  logic        s_weight_rvalid_i,
  input  logic [31:0] s_weight_rdata_i,
  output logic        s_weight_req_o,
  output logic        s_weight_we_o,
  output logic [ 3:0] s_weight_be_o,
  output logic [31:0] s_weight_addr_o,
  output logic [31:0] s_weight_wdata_o,

  input  logic        s_output_rvalid_i,
  input  logic [31:0] s_output_rdata_i,
  output logic        s_output_req_o,
  output logic        s_output_we_o,
  output logic [ 3:0] s_output_be_o,
  output logic [31:0] s_output_addr_o,
  output logic [31:0] s_output_wdata_o,
  
  input  logic [31:0] input_base_addr_i,
  input  logic [31:0] weight_base_addr_i,
  input  logic [31:0] output_base_addr_i,

  input  logic [31:0] input_len_i,
  input  logic [31:0] weight_len_i,
  input  logic [31:0] output_inc_m_i,

  input  logic        input_req_i,
  input  logic        weight_req_i,
  input  logic        output_req_i,

  output logic        input_ack_o,
  output logic        weight_ack_o,
  output logic        output_ack_o

);

  logic        s_rvalid_i;
  logic [31:0] s_rdata_i;
  logic        s_req_o;
  logic        s_we_o;
  logic [ 3:0] s_be_o;
  logic [31:0] s_addr_o;
  logic [31:0] s_wdata_o;
  
  logic        input_req_d,   input_req_q;
  logic        weight_req_d,  weight_req_q;
  logic        output_req_d,  output_req_q;

  logic [31:0] addr_m;
  logic [31:0] addr_s;
  logic [31:0] len;
  logic [31:0] inc_m;
  logic [31:0] inc_s;

  logic [2:0]  s_cond;
  logic        done, mode;
  logic [31:0] counter, counter_last, counter_last2;


  assign s_cond = {input_req_i, weight_req_i, output_req_i};

  // priority assignment




  always_comb begin
    if(input_req_q) begin
        mode             = '0;
        addr_m           = input_base_addr_i;
        len              = input_len_i;
        inc_m            = 1;
        inc_s            = 1;
        s_rvalid_i       = s_input_rvalid_i;
        s_rdata_i        = s_input_rdata_i;

        s_input_req_o    = s_req_o;
        s_input_we_o     = s_we_o;
        s_input_be_o     = s_be_o;
        s_input_addr_o   = s_addr_o;
        s_input_wdata_o  = s_wdata_o;
        s_weight_req_o   = '0;
        s_weight_we_o    = '0;
        s_weight_be_o    = '0;
        s_weight_addr_o  = '0;
        s_weight_wdata_o = '0;
        s_output_req_o   = '0;
        s_output_we_o    = '0;
        s_output_be_o    = '0;
        s_output_addr_o  = '0;
        s_output_wdata_o = '0;
      end 
      else if (weight_req_q) begin
        mode             = '0;
        addr_m           = weight_base_addr_i;
        len              = weight_len_i;
        inc_m            = 1;
        inc_s            = 1;
        s_rvalid_i       = s_weight_rvalid_i;
        s_rdata_i        = s_weight_rdata_i;

        s_input_req_o    = '0;
        s_input_we_o     = '0;
        s_input_be_o     = '0;
        s_input_addr_o   = '0;
        s_input_wdata_o  = '0;
        s_weight_req_o   = s_req_o;
        s_weight_we_o    = s_we_o;
        s_weight_be_o    = s_be_o;
        s_weight_addr_o  = s_addr_o;
        s_weight_wdata_o = s_wdata_o;
        s_output_req_o   = '0;
        s_output_we_o    = '0;
        s_output_be_o    = '0;
        s_output_addr_o  = '0;
        s_output_wdata_o = '0;
      end 
      else if (output_req_q) begin
        mode             = '1;
        addr_m           = output_base_addr_i;
        len              = TPO/2;
        inc_m            = output_inc_m_i;
        inc_s            = 1;
        s_rvalid_i       = s_output_rvalid_i;
        s_rdata_i        = s_output_rdata_i;

        s_input_req_o    = '0;
        s_input_we_o     = '0;
        s_input_be_o     = '0;
        s_input_addr_o   = '0;
        s_input_wdata_o  = '0;
        s_weight_req_o   = '0;
        s_weight_we_o    = '0;
        s_weight_be_o    = '0;
        s_weight_addr_o  = '0;
        s_weight_wdata_o = '0;
        s_output_req_o   = s_req_o;
        s_output_we_o    = s_we_o;
        s_output_be_o    = s_be_o;
        s_output_addr_o  = s_addr_o;
        s_output_wdata_o = s_wdata_o;
      end 
      else begin
        mode             = '0;
        addr_m           = '0;
        len              = '0;
        inc_m            = '0;
        inc_s            = '0;
        s_rvalid_i       = '0;
        s_rdata_i        = '0;

        s_input_req_o    = '0;
        s_input_we_o     = '0;
        s_input_be_o     = '0;
        s_input_addr_o   = '0;
        s_input_wdata_o  = '0;
        s_weight_req_o   = '0;
        s_weight_we_o    = '0;
        s_weight_be_o    = '0;
        s_weight_addr_o  = '0;
        s_weight_wdata_o = '0;
        s_output_req_o   = '0;
        s_output_we_o    = '0;
        s_output_be_o    = '0;
        s_output_addr_o  = '0;
        s_output_wdata_o = '0;
      end
  end


  
  typedef enum {
    StIdle, StRequest, StTransfer, StTransferEnd, StDone
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

  // Register the state
  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      input_req_d  <= '0;
      weight_req_d <= '0;
      output_req_d <= '0;
    end else begin
      input_req_d  <= input_req_i;
      weight_req_d <= input_req_i ? '0 : weight_req_i;
      output_req_d <= (input_req_i | weight_req_i) ? '0 : output_req_i;
    end
  end

  // Next state logic
  always_comb begin
    state_d = state_q;
    unique case (state_q)
    StIdle:  if (input_req_d | weight_req_d | output_req_d) state_d = StRequest;
    StRequest: state_d = StTransfer;
    StTransfer: if (counter >= len) state_d = StTransferEnd;
    StTransferEnd: state_d = StDone;
    StDone:  begin
      if (input_req_q == ~input_req_i) state_d = StIdle;
      else if ((input_req_q == '0) && (weight_req_q == ~weight_req_i)) state_d = StIdle;
      else if ((input_req_q == '0) && (weight_req_q == '0) && (output_req_q == ~output_req_i)) state_d = StIdle;
    end
    default: state_d = StIdle;
    endcase
  end

  always_comb begin
    s_wdata_o = '0;
    m_wdata_o = '0;
    if (mode == '0) begin
      s_wdata_o = m_rdata_i;
    end else begin
      m_wdata_o = s_rdata_i;
    end
  end

  // Output logic
  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      m_req_o      <= '0;
      m_we_o       <= '0;
      m_be_o       <= '0;
      m_addr_o     <= '0;
      s_we_o       <= '0;
      s_be_o       <= '0;
      s_addr_o     <= '0;
      done         <= '0;
      input_req_q  <= '0;
      weight_req_q <= '0;
      output_req_q <= '0;
      end else begin
      m_req_o   <= '0;
      m_we_o    <= '0;
      m_be_o    <= '1;
      m_addr_o  <= '0;
      s_we_o    <= '0;
      s_be_o    <= '1;
      s_addr_o  <= '0;
      done      <= '0;
      input_ack_o  <= '0;
      weight_ack_o <= '0;
      output_ack_o <= '0;
      case (state_d)
        StIdle: begin
          counter      <= '0;
          counter_last <= '0;
          input_req_q  <= '0;
          weight_req_q <= '0;
          output_req_q <= '0;
        end
        StRequest: begin
          counter      <= '0;
          counter_last <= '0;
          m_addr_o     <= addr_m;
          s_addr_o     <= '0;
          input_req_q  <= input_req_d;
          weight_req_q <= weight_req_d;
          output_req_q <= output_req_d;
        end
        StTransfer: begin
          counter     <= counter + 1;
          counter_last <= counter;
          if (mode == '0) begin
            m_req_o   <= '1;
            m_addr_o  <= addr_m + ((counter * inc_m) << 2);
            s_req_o   <= '1;
            s_we_o    <= '1;
            s_addr_o  <= (counter_last * inc_s) << 2;
          end else begin
            m_req_o   <= '1;
            m_addr_o  <= addr_m + ((counter_last * inc_m) << 2);
            m_we_o    <= '1;
            s_req_o   <= '1;
            s_addr_o  <= (counter * inc_s) << 2;
          end
        end
        StTransferEnd: begin
          counter     <= '0;
          counter_last <= counter;
          if (mode == '0) begin
            m_req_o   <= '0;
            m_addr_o  <= '0;
            s_req_o   <= '1;
            s_we_o    <= '1;
            s_addr_o  <= (counter_last * inc_s) << 2;
          end else begin
            m_req_o   <= '1;
            m_addr_o  <= addr_m + ((counter_last * inc_m) << 2);
            m_we_o    <= '1;
            s_req_o   <= '0;
            s_addr_o  <= '0;
          end
        end
        StDone: begin
          counter <= '0;
          counter_last <= '0;
          done    <= '1;
          input_ack_o  <= input_req_q;
          weight_ack_o <= weight_req_q;
          output_ack_o <= output_req_q;
        end
      endcase
    end
  end

endmodule
/* verilator lint_on UNUSED */
/* verilator lint_on UNDRIVEN */
