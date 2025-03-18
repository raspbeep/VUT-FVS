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

    // local variables for predict
    static logic cycle_cnt_reset_next_clock;
    static logic [(DATA_WIDTH*2)-1:0] cycle_cnt = 0;
    static logic irq_signal;

    static logic ctrl_reg_next_clock;
    static logic [1:0] ctrl_reg_next_clock_value;
    static logic [1:0] ctrl_reg = TIMER_CR_DISABLED;

    static logic [1:0] reset_signal = 0;
    static logic [1:0] disabled_signal = 0;
    static logic irq_signal_next_clock = 0;
    static logic [DATA_WIDTH-1:0] address;
    static logic [DATA_WIDTH-1:0] data_out;
    static logic [DATA_WIDTH-1:0] data_in;

    static logic timer_cnt_next_clock;
    static logic [DATA_WIDTH-1:0] timer_cnt_next_clock_value;
    static logic [DATA_WIDTH-1:0] timer_cnt;

    static logic timer_cmp_next_clock;
    static logic [DATA_WIDTH-1:0] timer_cmp_next_clock_value;    
    static logic [DATA_WIDTH-1:0] timer_cmp;

    static logic timer_cr_next_clock;
    static logic [DATA_WIDTH-1:0] timer_cr_next_clock_value;
    static logic [DATA_WIDTH-1:0] timer_cr;


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

        if (t.RST == RST_ACT_LEVEL) begin
            reset_signal = 1;
            irq_signal_next_clock = 0;
            timer_cnt_next_clock_value = 0;
            timer_cmp_next_clock_value = 0;
            timer_cr_next_clock_value = 0;
            timer_cnt = 0;
            timer_cmp = 0;
            timer_cr = 0;
            t.P_IRQ = 0;
            RESPONSE = CP_RSP_IDLE;
            DATA_OUT = 0;
            // ask
            // cycle_cnt_reset_next_clock = 1;
            return;
        end else begin
            reset_signal = 0;
            t.P_IRQ = 0;
            // ask
            // if (cycle_cnt_reset_next_clock) begin
            //     cycle_cnt = 0;
            //     cycle_cnt_reset_next_clock = 0;
            // end
        end

        if (timer_cmp_next_clock == 1) begin
            timer_cmp_next_clock = 0;
            timer_cmp = timer_cmp_next_clock_value;
        end

        if (timer_cnt_next_clock == 1) begin
            timer_cnt_next_clock = 0;
            timer_cnt = timer_cnt_next_clock_value;
        end

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
                        timer_cr_next_clock_value = t.DATA_IN;
                        timer_cr_next_clock = 1;
                    end
                    TIMER_CYCLE_L: begin
                        // timer_cycle_l = t.DATA_IN;
                    end
                    TIMER_CYCLE_H: begin
                        // timer_cycle_h = t.DATA_IN;
                    end
                endcase;
            end
        endcase;

        if (irq_signal_next_clock == 1) begin
            irq_signal_next_clock = 0;
            timer_cnt = 0;
            t.P_IRQ = 1;
            irq_signal = 1;
        end

        case (ctrl_reg)
            TIMER_CR_AUTO_RESTART: begin
                if (!irq_signal) begin
                    timer_cnt = timer_cnt + 1;
                end

                if (timer_cnt == timer_cmp) begin
                    // debug print
                    $display("IRQ signal set at cycle %0d", cycle_cnt);
                    irq_signal_next_clock = 1;
                end
            end
        endcase;

        if (ctrl_reg_next_clock == 1) begin
            ctrl_reg_next_clock = 0;
            ctrl_reg = ctrl_reg_next_clock_value;
        end

        if (timer_cr_next_clock == 1) begin
            timer_cr_next_clock = 0;
            timer_cr = timer_cr_next_clock_value;
            // maybe only sometimes
            ctrl_reg_next_clock_value = timer_cr;
            ctrl_reg_next_clock = 1;
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
