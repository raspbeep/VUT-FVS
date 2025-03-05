// This class measures exercised combinations of DUTs interface ports.
class timer_t_coverage extends uvm_subscriber #(timer_t_transaction);

    // registration of component tools
    `uvm_component_utils( timer_t_coverage )

    // member attributes
    local T m_transaction_h;
    virtual dut_internal_if ivif;

    // Covergroup definition
    covergroup FunctionalCoverage( string inst );
        /* INSERT YOUR CODE HERE */
    endgroup

    // Constructor - creates new instance of this class
    function new( string name = "m_coverage_h", uvm_component parent = null );
        super.new( name, parent );
        FunctionalCoverage = new( "timer" );
    endfunction: new

    // Build - instantiates child components
    function void build_phase( uvm_phase phase );
        super.build_phase( phase );
        if ( !uvm_config_db #(virtual dut_internal_if)::get(this,
            "*", "dut_internal_if", ivif) ) begin
            `uvm_fatal( "configuration:", "Cannot find 'dut_internal_if' inside uvm_config_db, probably not set!" )
        end
    endfunction: build_phase

    // Write - obligatory function, samples value on the interface.
    function void write( T t );
        // skip invalid transactions
        m_transaction_h = t;
        FunctionalCoverage.sample();
    endfunction: write

endclass: timer_t_coverage
