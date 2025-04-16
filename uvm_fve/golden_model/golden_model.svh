// Represents the golden model of the processor used to predict results of the DUT.
class timer_t_gm extends uvm_subscriber #(timer_t_transaction);//uvm_component;

    // registration of component tools
    `uvm_component_utils( timer_t_gm )

    // analysis port for outside components to access transactions from the monitor
    uvm_analysis_port #(timer_t_transaction) timer_t_analysis_port;

    // static local variables accesible by waveform
    static logic                  P_IRQ = 0;
    static logic [2:0]            RESPONSE;
    static logic [DATA_WIDTH-1:0] DATA_OUT;

    static logic data_out_next_clock = 0;
    static logic [DATA_WIDTH-1:0] data_out_prev = 0;
    // indicates reading from cycle count, the value is immediate
    // otherwise the value of cmp_reg, cnt_reg, ctrl_reg is from the previous clock
    static logic reading_cycle_cnt_l = 0;
    static logic reading_cycle_cnt_h = 0;
    static logic [DATA_WIDTH-1:0] data_out_next_clock_value;

    static logic start_counting_next_clock = 0;
    // local variables for predict
    static logic cycle_cnt_reset_next_clock = 0;
    static logic [(DATA_WIDTH*2)-1:0] cycle_cnt = 0;
    static logic irq_signal = 0;

    static logic ctrl_reg_next_clock = 0;
    static logic [1:0] ctrl_reg_next_clock_value;
    static logic [1:0] ctrl_reg = TIMER_CR_DISABLED;

    static logic reset_signal = 0;
    static logic disabled_signal = 0;
    static logic irq_signal_next_clock = 0;
    static logic [DATA_WIDTH-1:0] address;
    static logic [DATA_WIDTH-1:0] data_out;
    static logic [DATA_WIDTH-1:0] data_in;

    static logic disable_timer_next_clock = 0;
    static logic reset_cnt_next_clock = 0;
    static logic reset_cnt_this_clock = 0;

    static logic timer_cnt_next_clock = 0;
    static logic [DATA_WIDTH-1:0] timer_cnt_next_clock_value;
    static logic [DATA_WIDTH-1:0] timer_cnt;

    static logic timer_cmp_next_clock = 0;
    static logic [DATA_WIDTH-1:0] timer_cmp_next_clock_value;    
    static logic [DATA_WIDTH-1:0] timer_cmp;

    static logic response_next_clock = 0;
    static logic [2:0] response_next_clock_value;
    
    static logic resetting_this_clock = 0;
    static logic disabling_this_clock = 0;

    // base name prefix for created transactions
    string m_name = "gold";

    // Constructor - creates new instance of this class
    function new( string name = "m_timer_t_gm_h", uvm_component parent = null );
        super.new( name, parent );
    endfunction: new

    // Build - instantiates child components
    function void build_phase( uvm_phase phase );
    	super.build_phase( phase );

      timer_t_analysis_port = new( "timer_t_analysis_port", this );

    endfunction: build_phase

    // Connect - create interconnection between child components
    function void connect_phase( uvm_phase phase );
        super.connect_phase( phase );
    endfunction: connect_phase

    // Write - get all transactions from driver for computing predictions
    // receive data from driver via analytical port
    function void write( T t );
  		timer_t_transaction out_t;

      out_t = timer_t_transaction::type_id::create(
          $sformatf("%0s: %0t", m_name, $time) );

      out_t.copy(t);

      // predict outputs
      predict( out_t );

      // support function for displaying data in wave
      wave_display_support_func(out_t);

      // send predicted outputs to scoreboard
      timer_t_analysis_port.write(out_t);
  	endfunction: write

    // implements behavior of the golden model
    local function automatic void predict( timer_t_transaction t );
        irq_signal = 0;
        cycle_cnt = cycle_cnt + 1;
        if (cycle_cnt_reset_next_clock == 1) begin
            cycle_cnt_reset_next_clock = 0;
            cycle_cnt = 0;
        end

        if (t.RST === RST_ACT_LEVEL) begin
            reset_signal = 1;
            irq_signal_next_clock = 0;
            timer_cnt_next_clock_value = 0;
            timer_cmp_next_clock_value = 0;
            response_next_clock = 0;
            response_next_clock_value = CP_RSP_IDLE;
            cycle_cnt_reset_next_clock = 1;
            timer_cnt = 0;
            timer_cmp = 0;

            t.P_IRQ = 0;
            ctrl_reg = TIMER_CR_DISABLED;
            t.RESPONSE = CP_RSP_IDLE;
            t.DATA_OUT = 0;
            return;
        end else begin
            reset_signal = 0;
            t.P_IRQ = 0;
        end

        if (response_next_clock == 1) begin
            response_next_clock = 0;
            t.RESPONSE = response_next_clock_value;
        end else begin
            t.RESPONSE = CP_RSP_IDLE;
        end

        if (data_out_next_clock == 1) begin
            data_out_next_clock = 0;
            if (reading_cycle_cnt_l) begin
                t.DATA_OUT = cycle_cnt[31:0];
                data_out_prev = cycle_cnt[31:0];
            end else if (reading_cycle_cnt_h) begin
                t.DATA_OUT = cycle_cnt[63:32];
                data_out_prev = cycle_cnt[63:32];
            end else begin
                t.DATA_OUT = data_out_next_clock_value;
                data_out_prev = data_out_next_clock_value;
            end
        end else begin
            t.DATA_OUT = data_out_prev;
        end

        if (disable_timer_next_clock == 1) begin
            ctrl_reg = TIMER_CR_DISABLED;
            disabling_this_clock = 1;
        end

        if (ctrl_reg_next_clock == 1) begin
            ctrl_reg_next_clock = 0;
            if (ctrl_reg == TIMER_CR_DISABLED && ctrl_reg_next_clock_value != TIMER_CR_DISABLED && !disabling_this_clock) begin
                start_counting_next_clock = 1;
            end

            ctrl_reg = ctrl_reg_next_clock_value;
        end
        disabling_this_clock = 0;

        // -------------------------------------------------
        // prikaz na nulovanie v aktualnom takte
        if (reset_cnt_next_clock == 1) begin
            timer_cnt = 0;
            reset_cnt_next_clock = 0;
            reset_cnt_this_clock = 1;
        end

        // -------------------------------------------------
        // inkrementacia cnt ak nie je disabled
        if (ctrl_reg != TIMER_CR_DISABLED && !start_counting_next_clock && !reset_cnt_this_clock) begin
            if (timer_cnt == 32'hffffffff) begin
                timer_cnt = 0;
            end else begin
                timer_cnt = timer_cnt + 1;
            end
        end
        start_counting_next_clock = 0;
        reset_cnt_this_clock = 0;

        // -------------------------------------------------
        // prikaz na zapis do cnt/cmp
        if (timer_cmp_next_clock == 1) begin
            timer_cmp_next_clock = 0;
            timer_cmp = timer_cmp_next_clock_value;
        end

        if (timer_cnt_next_clock == 1) begin
            timer_cnt_next_clock = 0;
            timer_cnt = timer_cnt_next_clock_value;
        end
        // -------------------------------------------------

        if (irq_signal_next_clock == 1) begin
            t.P_IRQ = 1;
            irq_signal_next_clock = 0;
        end

        case (ctrl_reg)
            TIMER_CR_DISABLED: begin
            end
            TIMER_CR_AUTO_RESTART: begin // 1
                if (timer_cnt == timer_cmp) begin
                    irq_signal_next_clock = 1;
                    reset_cnt_next_clock = 1;
                end
            end
            TIMER_CR_ONESHOT: begin // 2
                if (timer_cnt == timer_cmp) begin
                    irq_signal_next_clock = 1;
                    disable_timer_next_clock = 1;
                    reset_cnt_next_clock = 1;
                end
            end
            TIMER_CR_CONTINUOUS: begin // 3
                if (timer_cnt == timer_cmp) begin
                    irq_signal_next_clock = 1;
                    reset_cnt_next_clock = 0;
                end
            end
        endcase;

        if (t.REQUEST == CP_REQ_NONE) begin
            response_next_clock = 1;
            response_next_clock_value = CP_RSP_IDLE;
        end else if (t.REQUEST == CP_REQ_RESERVED) begin
            response_next_clock = 1;
            response_next_clock_value = CP_RSP_ERROR;
        end else if (t.REQUEST == CP_REQ_READ || t.REQUEST == CP_REQ_WRITE) begin
            if (t.ADDRESS > TIMER_CYCLE_H) begin
                // out of range access
                response_next_clock = 1;
                response_next_clock_value = CP_RSP_OOR;
            end else if (t.ADDRESS[1:0] != 2'b00) begin
                response_next_clock = 1;
                response_next_clock_value = CP_RSP_UNALIGNED;
            end else begin
                case (t.REQUEST)
                    CP_REQ_WRITE: begin
                        case (t.ADDRESS)
                            TIMER_CNT: begin
                                timer_cnt_next_clock_value = t.DATA_IN;
                                timer_cnt_next_clock = 1;
                            end
                            TIMER_CMP: begin
                                timer_cmp_next_clock_value = t.DATA_IN;
                                timer_cmp_next_clock = 1;

                            end
                            TIMER_CR: begin
                                ctrl_reg_next_clock_value = t.DATA_IN;
                                ctrl_reg_next_clock = 1;
                                disable_timer_next_clock = 0;
                                // ctrl_reg = t.DATA_IN;
                            end
                            TIMER_CYCLE_L: begin
                                // ignore the write request, just acknowledge it
                            end
                            TIMER_CYCLE_H: begin
                                // ignore the write request, just acknowledge it
                            end
                        endcase;
                        response_next_clock = 1;
                        response_next_clock_value = CP_RSP_ACK;
                    end
                    CP_REQ_READ: begin
                        reading_cycle_cnt_l = 0;
                        reading_cycle_cnt_h = 0;
                        case (t.ADDRESS)
                            TIMER_CNT: begin
                                data_out_next_clock_value = timer_cnt;
                            end
                            TIMER_CMP: begin
                                data_out_next_clock_value = timer_cmp;
                            end
                            TIMER_CR: begin
                                data_out_next_clock_value = ctrl_reg;
                            end
                            TIMER_CYCLE_L: begin
                                reading_cycle_cnt_l = 1;
                                // no data out value, we need the read it next clock
                            end
                            TIMER_CYCLE_H: begin
                                reading_cycle_cnt_h = 1;
                                // no data out value, we need the read it next clock
                            end
                        endcase;
                        data_out_next_clock = 1;
                        response_next_clock = 1;
                        response_next_clock_value = CP_RSP_ACK;
                    end
                endcase;
            end
        end

    endfunction: predict

    local function void set_default_outputs( timer_t_transaction t );
        t.P_IRQ    = 0;
        t.RESPONSE = 0;
        t.DATA_OUT = 0;
    endfunction: set_default_outputs

    local function automatic void wave_display_support_func( timer_t_transaction t );
        P_IRQ    = t.P_IRQ;
        RESPONSE = t.RESPONSE;
        DATA_OUT = t.DATA_OUT;
    endfunction: wave_display_support_func

endclass: timer_t_gm
