// Represents agent class handling the interface pins of the DUT/DUV.
class timer_t_agent extends uvm_agent;

    // registration of component tools
    `uvm_component_utils( timer_t_agent )

    // analysis ports for outside components to access transactions from the monitor and driver
    uvm_analysis_port #(timer_t_transaction) analysis_port_driver;
    uvm_analysis_port #(timer_t_transaction) analysis_port_monitor;

    // component members for passive mode
    timer_t_monitor m_monitor_h;
    timer_t_coverage m_coverage_h;
    // component members for active mode
    timer_t_driver m_driver_h;
    timer_t_sequencer m_sequencer_h;

    // Constructor - creates new instance of this class
    function new( string name = "m_agent_h", uvm_component parent = null );
        super.new( name, parent );
    endfunction: new

    // Build - instantiates child components
    function void build_phase( uvm_phase phase );
        super.build_phase( phase );
        m_monitor_h = timer_t_monitor::type_id::create( "m_monitor_h", this );
        m_coverage_h = timer_t_coverage::type_id::create( "m_coverage_h", this );
        m_driver_h = timer_t_driver::type_id::create( "m_driver_h", this );
        m_sequencer_h = timer_t_sequencer::type_id::create( "m_sequencer_h", this );
    endfunction: build_phase

    // Connect - create interconnection between child components
    function void connect_phase( uvm_phase phase );
        virtual itimer_itf vif;
        super.connect_phase( phase );

        if ( !uvm_config_db #(virtual itimer_itf)::get(null,
            "uvm_test_top",
            "timer_t_if",
            vif) ) begin
            `uvm_fatal( "configuration:", "Cannot find 'timer_t_if' inside uvm_config_db, probably not set!" )
        end

        // connect monitor and assign interface
        analysis_port_monitor= m_monitor_h.analysis_port;
        m_monitor_h.vif = vif;

        // connect monitor with coverage subscriber
        m_monitor_h.analysis_port.connect( m_coverage_h.analysis_export );

        // connect the driver and sequencer + driver to analytical port
        m_driver_h.seq_item_port.connect( m_sequencer_h.seq_item_export );
        analysis_port_driver = m_driver_h.analysis_port;
        m_driver_h.vif = vif;
    endfunction: connect_phase

endclass: timer_t_agent
