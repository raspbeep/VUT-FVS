// This class represents the main parts of the verification environment.
class timer_t_env extends uvm_env;

    // registration of component tools
    `uvm_component_utils( timer_t_env )

    // main sub-components
    timer_t_agent m_timer_t_agent_h;
    timer_t_scoreboard m_scoreboard_h;
    // golden (reference) model
    timer_t_gm m_gold_h;

    timer_reg_block m_reg_block_h;
    reg_adapter m_reg_adapter_h;

    // Constructor - creates new instance of this class
    function new( string name = "m_env_h", uvm_component parent = null );
        super.new( name, parent );
    endfunction: new

    // Build - instantiates child components
    function void build_phase( uvm_phase phase );
        super.build_phase( phase );
        m_timer_t_agent_h = timer_t_agent::type_id::create( "m_timer_t_agent_h", this );
        m_scoreboard_h = timer_t_scoreboard::type_id::create( "m_scoreboard_h", this );
        m_gold_h = timer_t_gm::type_id::create( "m_gold_h", this );

        m_reg_block_h = timer_reg_block::type_id::create( "m_reg_block_h", this );
        m_reg_block_h.configure();
        m_reg_block_h.build();
        m_reg_block_h.lock_model();

        m_reg_adapter_h = reg_adapter::type_id::create( "m_reg_adapter_h", this );
    endfunction: build_phase

    // Connect - create interconnection between child components
    function void connect_phase( uvm_phase phase );
        super.connect_phase( phase );
        // agent monitor => scoreboard (DUT outputs)
        m_timer_t_agent_h.analysis_port_monitor.connect( m_scoreboard_h.dut_analysis_export );
        // agent driver => golden reference model (DUT inputs)
        m_timer_t_agent_h.analysis_port_driver.connect( m_gold_h.analysis_export );
        // golden reference model => scoreboard (GM outputs)
        m_gold_h.timer_t_analysis_port.connect( m_scoreboard_h.gold_analysis_export );
        // now initialize scoreboard attributes
        m_scoreboard_h.m_gold_h = m_gold_h;

        m_reg_block_h.default_map.set_sequencer(m_timer_t_agent_h.m_sequencer_h, m_reg_adapter_h);
        m_reg_block_h.default_map.set_auto_predict(0);
        m_reg_block_h.default_map.set_check_on_read(1);

    endfunction: connect_phase

endclass: timer_t_env
