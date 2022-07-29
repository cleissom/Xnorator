/* verilator lint_off UNUSED */
/* verilator lint_off UNDRIVEN */

module xnorator (
    input               clk_i,
    input               rst_ni,

    input  logic        m_rvalid_i,
    input  logic        m_err_i,
    input  logic        m_gnt_i,
    input  logic [31:0] m_rdata_i,
    output logic        m_req_o,
    output logic        m_we_o,
    output logic [ 3:0] m_be_o,
    output logic [31:0] m_addr_o,
    output logic [31:0] m_wdata_o,

    input               s_req_i,
    input               s_we_i,
    input        [ 3:0] s_be_i,
    input        [31:0] s_addr_i,
    input        [31:0] s_wdata_i,
    output logic        s_rvalid_o,
    output logic [31:0] s_rdata_o,
    output logic        s_err_o,

    output logic        irq_done_o
  );

  // DESIGN TIME CONSTANTS
  parameter int unsigned TPO = 64;
  parameter int unsigned MAX_DEPTH = 512;
  parameter int unsigned MAX_INPUT_SIZE = 58*58*64;

  
  // CONSTANTS
  parameter int unsigned TPI = 32;
  parameter int unsigned KS = 3;

  localparam int unsigned OutputDataWidth = 16;
  localparam int unsigned OutputAddrWidth = $clog2(TPO);

  localparam int unsigned PopcountWidth = $clog2(TPI)+1;
  logic [(PopcountWidth-1):0] popcount_result;

  logic [31:0]  result_q, result_d;
  logic         error_q;
  logic         rvalid_q;


  localparam int unsigned CONTROL_ADDR_OFSET = 32;
  localparam logic [7:0] INPUT_ADDR_MMIO_ADDR    = 8'h0;
  localparam logic [7:0] WEIGHT_ADDR_MMIO_ADDR   = 8'h1;
  localparam logic [7:0] OUTPUT_ADDR_MMIO_ADDR   = 8'h2;
  localparam logic [7:0] INPUT_WIDTH_MMIO_ADDR   = 8'h3;
  localparam logic [7:0] INPUT_HEIGHT_MMIO_ADDR  = 8'h4;
  localparam logic [7:0] INPUT_CHANNEL_MMIO_ADDR = 8'h5;
  localparam logic [7:0] OUPUT_CHANNEL_MMIO_ADDR = 8'h6;
  localparam logic [7:0] PADDING_MMIO_ADDR       = 8'h7;
  localparam logic [7:0] START_MMIO_ADDR         = 8'h8;
  localparam logic [7:0] DONE_MMIO_ADDR          = 8'h9;

  logic         input_ram_valid;
  logic [31:0]  input_ram_data;
  logic [31:0]  input_ram_data_checked;

  logic         weight_ram_valid;
  logic [31:0]  weight_ram_data;

  logic [7:0] ctrl_addr;
  assign ctrl_addr = s_addr_i[9:2];

  logic [31:0] cfg_input_base_addr;
  logic [31:0] cfg_weight_base_addr;
  logic [31:0] cfg_output_base_addr;
  logic [31:0] cfg_padding;
  logic [31:0] cfg_input_width, cfg_input_height, cfg_input_channel, cfg_output_channel;

  logic        start_i;
  logic        flush_ack;

  logic        load_input_req, load_input_ack;
  logic        load_weight_req, load_weight_ack;
  logic        end_o;

  assign irq_done_o = end_o;

  logic load_input_req_q,       load_input_req_q2,      load_input_req_q3,      load_input_req_q4,      load_input_req_q5;
  logic load_weight_req_q,      load_weight_req_q2,     load_weight_req_q3,     load_weight_req_q4,     load_weight_req_q5;
  logic transfer_output_req_q,  transfer_output_req_q2, transfer_output_req_q3, transfer_output_req_q4, transfer_output_req_q5;
  
  logic        flush_req_d, flush_req_q;
  logic        exec_d, exec_q;
  
  logic [31:0] loop_oci, loop_ico, loop_wi, loop_wj, loop_i, loop_j, loop_oco;
  logic [31:0] index_input, index_weight;
  logic [31:0] index_output_d, index_output_q;

  

  loop_control_fsm  #(
    .TPO(TPO),
    .KS(KS)
  ) u_loop_control_fsm (
    .clk_i,
    .rst_ni,

    .start_i,
    .iw_i(cfg_input_width),
    .ih_i(cfg_input_height),
    .ic_i(cfg_input_channel),
    .oc_i(cfg_output_channel),
    .padding_i(cfg_padding[0]),
    .flush_ack_i(flush_ack),
    .load_input_ack_i(load_input_ack),
    .load_weight_ack_i(load_weight_ack),

    .oci_o(loop_oci),
    .ico_o(loop_ico),
    .wi_o (loop_wi),
    .wj_o (loop_wj),
    .i_o  (loop_i),
    .j_o  (loop_j),
    .oco_o(loop_oco),
    .flush_req_o(flush_req_d),
    .load_input_req_o(load_input_req),
    .load_weight_req_o(load_weight_req),
    .exec_o(exec_d),
    .end_o
  );

  address_generator #(
    .KS(KS)
  ) u_address_generator (
    .iw_i(cfg_input_width),
    .ih_i(cfg_input_height),
    .ic_i(cfg_input_channel),
  
    .oci_i(loop_oci),
    .ico_i(loop_ico),
    .wi_i (loop_wi),
    .wj_i (loop_wj),
    .i_i  (loop_i),
    .j_i  (loop_j),

    .index_input_o (index_input),
    .index_weight_o(index_weight),
    .index_output_o(index_output_d)
  );

  // PE Pipeline
  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      exec_q         <= '0;
      index_output_q <= '0;
      flush_req_q    <= '0;
    end else begin
      exec_q         <= exec_d;
      index_output_q <= index_output_d;
      flush_req_q    <= flush_req_d;
    end
  end

  padding_check u_padding_check (
    .loop_i_i(loop_i),
    .loop_j_i(loop_j),
    .loop_wi_i(loop_wi),
    .loop_wj_i(loop_wj),
    .iw_i(cfg_input_width),
    .ih_i(cfg_input_height),
    .rdata_i(input_ram_data),

    .data_o(input_ram_data_checked)
  );



  processing_engine #(
    .TP(TPI)
  ) u_processing_engine (
    .data1_i(input_ram_data_checked),
    .data2_i(weight_ram_data),
    .mask_i('1),
    .result_o(popcount_result)
  );

  logic [(OutputDataWidth-1):0] last_acc_value;
  logic [(OutputDataWidth-1):0] accumulation;
  assign accumulation = last_acc_value + { {(OutputDataWidth-PopcountWidth){popcount_result[(PopcountWidth-1)]}}, popcount_result};

  logic [(OutputAddrWidth-1):0] rf_waddr;
  logic [(OutputDataWidth-1):0] rf_wdata;
  logic rf_we;

  assign rf_waddr = clean_we ? flush_reg_addr : index_output_q[(OutputAddrWidth-1):0];
  assign rf_wdata = clean_we ? '0 : accumulation;
  assign rf_we    = clean_we ? clean_we : exec_q;

  register_file #(
    .DataSize         (TPO),
    .DataWidth        (OutputDataWidth)
  ) u_accumulation_rf (
    .clk_i,
    .rst_ni,

    .test_en_i       ('0),
    .dummy_instr_id_i('0),

    .raddr_a_i(index_output_q[(OutputAddrWidth-1):0]),
    .rdata_a_o(last_acc_value),

    .raddr_b_i(flush_reg_addr),
    .rdata_b_o(flush_data),

    .waddr_a_i(rf_waddr),
    .wdata_a_i(rf_wdata),
    .we_a_i   (rf_we),

    .err_o    ()
  );

  logic [15:0] dmac_output_rdata_low, dmac_output_rdata_high;
  logic [31:0] dmac_output_rdata_d;
  assign dmac_output_rdata_d = {{dmac_output_rdata_high}, {dmac_output_rdata_low}};

  // DMAC expects read data after 1 clock
  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      dmac_output_rdata <= '0;
    end else begin
      dmac_output_rdata <= dmac_output_rdata_d;
    end
  end

  register_file #(
    .DataSize         (TPO),
    .DataWidth        (OutputDataWidth)
  ) u_output_rf (
    .clk_i,
    .rst_ni,

    .test_en_i       ('0),
    .dummy_instr_id_i('0),

    .raddr_a_i({(dmac_output_addr >> 1)}[($clog2(TPO)-1):0]), // index = addr/2
    .rdata_a_o(dmac_output_rdata_low),

    .raddr_b_i(({dmac_output_addr >> 1}[($clog2(TPO)-1):0]) + 1),
    .rdata_b_o(dmac_output_rdata_high),

    .waddr_a_i(flush_reg_addr),
    .wdata_a_i(flush_data),
    .we_a_i   (flush_we),

    .err_o    ()
  );
  
  logic transfer_output_req;
  logic transfer_output_ack;
  logic flush_we, clean_we;
  logic [(OutputAddrWidth-1):0] flush_reg_addr;
  logic [(OutputDataWidth-1):0] flush_data;

  flush_output_fsm #(
    .TPO(TPO)
  ) u_flush_output_fsm (
    .clk_i,
    .rst_ni,
    
    .flush_req_i(flush_req_q),
    .transfer_output_ack_i(transfer_output_ack),

    .reg_addr_o(flush_reg_addr),
    .flush_we_o(flush_we),
    .clean_we_o(clean_we),
    .flush_ack_o(flush_ack),
    .transfer_output_req_o(transfer_output_req)
  );

  logic        dmac_input_rvalid,  dmac_weight_rvalid,  dmac_output_rvalid;
  logic [31:0] dmac_input_rdata,   dmac_weight_rdata,   dmac_output_rdata;
  logic        dmac_input_req,     dmac_weight_req,     dmac_output_req;
  logic        dmac_input_we,      dmac_weight_we,      dmac_output_we;
  logic [ 3:0] dmac_input_be,      dmac_weight_be,      dmac_output_be;
  logic [31:0] dmac_input_addr,    dmac_weight_addr,    dmac_output_addr;
  logic [31:0] dmac_input_wdata,   dmac_weight_wdata,   dmac_output_wdata;
  
  logic [31:0] output_fmap_size_q2, output_width_size_q, input_fmap_size_q, kernel_size_q;
  logic [31:0] output_width_q,   output_height_q,   loop_oco_q, loop_oco_q2, loop_oco_q3;
  logic [31:0] output_data_len_q3;
  logic [31:0] output_height_location_q4, output_channel_location_q4;
  logic [31:0] kernel_load_size, input_total_size;
  logic [31:0] output_fmap_size, weight_base_addr, output_base_addr;



  // Computation Pipeline
  always_ff @(posedge clk_i or negedge rst_ni)
  begin
    if (!rst_ni)
    begin
    end
    else
    begin
      output_width_q              <= cfg_padding == '1 ? cfg_input_width  : (cfg_input_width-2);
      output_height_q             <= cfg_padding == '1 ? cfg_input_height : (cfg_input_height-2);
      output_width_size_q         <= cfg_padding == '1 ? cfg_input_width : (cfg_input_width-2);
      input_fmap_size_q           <= cfg_input_width * cfg_input_height;
      kernel_size_q               <= (KS*KS) * (cfg_input_channel >> $clog2(32));
      loop_oco_q                  <= loop_oco;
      load_input_req_q            <= load_input_req;
      load_weight_req_q           <= load_weight_req;
      transfer_output_req_q       <= transfer_output_req;
      // computation_valid_q   <= start_computation ? '0 : '1;
      
      output_fmap_size_q2         <= output_width_q * output_height_q;
      loop_oco_q2                 <= loop_oco_q * TPO;
      load_input_req_q2           <= load_input_req_q;
      load_weight_req_q2          <= load_weight_req_q;
      transfer_output_req_q2      <= transfer_output_req_q;
      // computation_valid_q2  <= start_computation ? '0 : computation_valid_q;
      
      output_data_len_q3          <= output_fmap_size_q2 * (TPO/2);
      loop_oco_q3                 <= loop_oco_q2 * kernel_size_q;
      load_input_req_q3           <= load_input_req_q2;
      load_weight_req_q3          <= load_weight_req_q2;
      transfer_output_req_q3      <= transfer_output_req_q2;
      // computation_valid_q3  <= start_computation ? '0 : computation_valid_q2;
      
      output_height_location_q4   <= output_width_size_q * loop_j_output;
      output_channel_location_q4  <= output_data_len_q3  * loop_oco_output;
      load_input_req_q4           <= load_input_req_q3;
      load_weight_req_q4          <= load_weight_req_q3;
      transfer_output_req_q4      <= transfer_output_req_q3;
      // computation_valid_q4  <= start_computation ? '0 : computation_valid_q3;
      

      kernel_load_size            <= kernel_size_q * TPO;
      input_total_size            <= input_fmap_size_q * (cfg_input_channel >> $clog2(32));
      output_fmap_size            <= output_fmap_size_q2;
      weight_base_addr            <= cfg_weight_base_addr + (loop_oco_q3 << 2);
      output_base_addr            <= cfg_output_base_addr + ((loop_i_output + output_height_location_q4 + output_channel_location_q4) << 2);
      load_input_req_q5           <= load_input_req_q4;
      load_weight_req_q5          <= load_weight_req_q4;
      transfer_output_req_q5      <= transfer_output_req_q4;
      // computation_valid   <= start_computation ? '0 : computation_valid_q4;
    end
  end


  dmac #(
    .TPO(TPO),
    .KS(KS)
  ) u_dmac (
    .clk_i,
    .rst_ni,
    
    .m_rvalid_i (m_rvalid_i),
    .m_err_i    (m_err_i),
    .m_gnt_i    (m_gnt_i),
    .m_rdata_i  (m_rdata_i),
    .m_req_o    (m_req_o),
    .m_we_o     (m_we_o),
    .m_be_o     (m_be_o),
    .m_addr_o   (m_addr_o),
    .m_wdata_o  (m_wdata_o),

    .s_input_rvalid_i   (dmac_input_rvalid),
    .s_input_rdata_i    (dmac_input_rdata),
    .s_input_req_o      (dmac_input_req),
    .s_input_we_o       (dmac_input_we),
    .s_input_be_o       (dmac_input_be),
    .s_input_addr_o     (dmac_input_addr),
    .s_input_wdata_o    (dmac_input_wdata),

    .s_weight_rvalid_i  (dmac_weight_rvalid),
    .s_weight_rdata_i   (dmac_weight_rdata),
    .s_weight_req_o     (dmac_weight_req),
    .s_weight_we_o      (dmac_weight_we),
    .s_weight_be_o      (dmac_weight_be),
    .s_weight_addr_o    (dmac_weight_addr),
    .s_weight_wdata_o   (dmac_weight_wdata),

    .s_output_rvalid_i  ('1),
    .s_output_rdata_i   (dmac_output_rdata),
    .s_output_req_o     (dmac_output_req),
    .s_output_we_o      (dmac_output_we),
    .s_output_be_o      (dmac_output_be),
    .s_output_addr_o    (dmac_output_addr),
    .s_output_wdata_o   (dmac_output_wdata),

    .input_base_addr_i  (cfg_input_base_addr),
    .weight_base_addr_i (weight_base_addr),
    .output_base_addr_i (output_base_addr),

    .input_len_i        (input_total_size),
    .weight_len_i       (kernel_load_size),
    .output_inc_m_i     (output_fmap_size),

    .input_req_i        (load_input_req_q5),
    .weight_req_i       (load_weight_req_q5),
    .output_req_i       (transfer_output_req_q5),

    .input_ack_o        (load_input_ack),
    .weight_ack_o       (load_weight_ack),
    .output_ack_o       (transfer_output_ack)
  );


  // save and adjust loop variables for output on request (before update)
  logic [31:0] loop_i_output, loop_j_output, loop_oco_output;
  always_ff @(posedge clk_i or negedge rst_ni)
  begin
    if (!rst_ni)
      begin
        loop_i_output   <= '0;
        loop_j_output   <= '0;
        loop_oco_output <= '0;
      end
    else
      if(flush_req_d)
      begin
        loop_i_output   <= cfg_padding[0] ? loop_i + 1 : loop_i;
        loop_j_output   <= cfg_padding[0] ? loop_j + 1 : loop_j;
        loop_oco_output <= loop_oco;
      end
  end

  

  always_ff @(posedge clk_i)
  begin
    start_i <= '0;
    if (s_we_i) begin
      case (ctrl_addr)
        INPUT_ADDR_MMIO_ADDR:     cfg_input_base_addr <= s_wdata_i;
        WEIGHT_ADDR_MMIO_ADDR:    cfg_weight_base_addr <= s_wdata_i;
        OUTPUT_ADDR_MMIO_ADDR:    cfg_output_base_addr <= s_wdata_i;
        INPUT_WIDTH_MMIO_ADDR:    cfg_input_width <= s_wdata_i;
        INPUT_HEIGHT_MMIO_ADDR:   cfg_input_height <= s_wdata_i;
        INPUT_CHANNEL_MMIO_ADDR:  cfg_input_channel <= s_wdata_i;
        OUPUT_CHANNEL_MMIO_ADDR:  cfg_output_channel <= s_wdata_i;
        PADDING_MMIO_ADDR:        cfg_padding <= s_wdata_i;
        START_MMIO_ADDR:          start_i <= s_wdata_i[0];
      default: ;
      endcase
    
    end
    if (s_req_i) begin
      case (ctrl_addr)
        DONE_MMIO_ADDR: begin
            result_q <= { {31{'0}}, end_o};
            error_q <= 0;
        end
        default: ;
      endcase
    end
  end

  assign s_rdata_o = result_q;

  // Read data is always valid one cycle after a request
  always_ff @(posedge clk_i or negedge rst_ni)
  begin
    if (!rst_ni)
    begin
      rvalid_q <= 1'b0;
    end
    else
    begin
      rvalid_q <= s_req_i;
    end
  end

  assign s_rvalid_o = rvalid_q;
  assign s_err_o    = error_q;


  ram_2p #(
    .Depth((MAX_INPUT_SIZE/8)/4),
    .MemInitFile("")
  ) u_ram_input (
    .clk_i       (clk_i),
    .rst_ni      (rst_ni),

    .a_req_i     (dmac_input_req),
    .a_we_i      (dmac_input_we),
    .a_be_i      (dmac_input_be),
    .a_addr_i    (dmac_input_addr),
    .a_wdata_i   (dmac_input_wdata),
    .a_rvalid_o  (dmac_input_rvalid),
    .a_rdata_o   (dmac_input_rdata),

    .b_req_i     (exec_d),
    .b_we_i      (1'b0),
    .b_be_i      (4'b0),
    .b_addr_i    (index_input << 2),
    .b_wdata_i   (32'b0),
    .b_rvalid_o  (input_ram_valid),
    .b_rdata_o   (input_ram_data)
  );

  ram_2p #(
    .Depth((TPO*KS*KS*MAX_DEPTH/8)/4),
    .MemInitFile("")
  ) u_ram_weight (
    .clk_i,
    .rst_ni,

    .a_req_i     (dmac_weight_req),
    .a_we_i      (dmac_weight_we),
    .a_be_i      (dmac_weight_be),
    .a_addr_i    (dmac_weight_addr),
    .a_wdata_i   (dmac_weight_wdata),
    .a_rvalid_o  (dmac_weight_rvalid),
    .a_rdata_o   (dmac_weight_rdata),

    .b_req_i     (exec_d),
    .b_we_i      (1'b0),
    .b_be_i      (4'b0),
    .b_addr_i    (index_weight << 2),
    .b_wdata_i   (32'b0),
    .b_rvalid_o  (weight_ram_valid),
    .b_rdata_o   (weight_ram_data)
  );

endmodule
/* verilator lint_on UNUSED */
/* verilator lint_on UNDRIVEN */
