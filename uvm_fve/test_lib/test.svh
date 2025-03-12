// This is the default UVM test class for timer
class timer_t_test extends timer_t_test_base;

    // registration of component tools
    // registration of the given class to factory
    // factory then create instance of the object
    `uvm_component_utils( timer_t_test )

    uvm_sequence_base seq;
    // Constructor - creates new instance of this class
    function new( string name = "timer_t_test", uvm_component parent = null );
        super.new( name, parent );
    endfunction: new

    // Build - instantiates child components
    function void build_phase( uvm_phase phase );
        super.build_phase( phase );
    endfunction: build_phase

    // Run - start processing sequences
    task run_phase( uvm_phase phase );
        // creation of sequences
        uvm_sequence_base rst_seq = timer_t_sequence_reset::type_id::create( "reset" );
        uvm_sequence_base basic_seq = timer_t_sequence_basic::type_id::create( "basic" );

        // prevent the phase from immediate termination
        phase.raise_objection( this );

        // starting reset sequence
        rst_seq.start( m_env_h.m_timer_t_agent_h.m_sequencer_h );

        // starting basic sequence
        basic_seq.start( m_env_h.m_timer_t_agent_h.m_sequencer_h );

        phase.drop_objection( this );
    endtask: run_phase

endclass: timer_t_test
