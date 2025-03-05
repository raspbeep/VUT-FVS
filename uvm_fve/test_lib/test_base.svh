// This is the base UVM test class for timer
class timer_t_test_base extends uvm_test;

    // registration of component tools
    `uvm_component_utils( timer_t_test_base )

    // member attribute with the verification environment
    timer_t_env m_timer_t_env_h;
    // same handler as the one above, just different name
    timer_t_env m_env_h;

    // Constructor - creates new instance of this class
    function new( string name = "timer_t_test_base", uvm_component parent = null );
        super.new( name, parent );
    endfunction: new

    // Build - instantiates child components
    function void build_phase( uvm_phase phase );
        super.build_phase( phase );
        m_timer_t_env_h = timer_t_env::type_id::create( "m_timer_t_env_h", this );
        m_env_h = m_timer_t_env_h;
    endfunction: build_phase

endclass: timer_t_test_base
