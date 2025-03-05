// This class manages random inputs for DUT and sends them to driver.
class timer_t_sequencer extends uvm_sequencer #(timer_t_transaction);

    // registration of component tools
    `uvm_component_utils( timer_t_sequencer )

    // Constructor - creates new instance of this class
    function new( string name = "m_sequencer_h", uvm_component parent = null );
        super.new( name, parent );
    endfunction: new

endclass: timer_t_sequencer
