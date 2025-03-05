// Represents the golden model of the processor used to predict results of the DUT.
class timer_t_gm extends uvm_subscriber #(timer_t_transaction);//uvm_component;

    // registration of component tools
    `uvm_component_utils( timer_t_gm )

    // analysis port for outside components to access transactions from the monitor
    uvm_analysis_port #(timer_t_transaction) timer_t_analysis_port;

    // static local variables accesible by waveform
    static logic                  P_IRQ;
    static logic [2:0]            RESPONSE;
    static logic [DATA_WIDTH-1:0] DATA_OUT;

    // local variables

    /* INSERT YOUR CODE HERE */

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

        /* INSERT YOUR CODE HERE */
        set_default_outputs(t);

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
