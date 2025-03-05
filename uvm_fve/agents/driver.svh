// Definition of the driver class 'timer_t_driver' used for communication with agents input interface.
class timer_t_driver extends uvm_driver #(timer_t_transaction);

    // registration of component tools
    `uvm_component_utils( timer_t_driver )

    // reference to the virtual interface, initialized during the connect phase by parent agent
    virtual itimer_itf vif;

    uvm_analysis_port #(timer_t_transaction) analysis_port;

    // Constructor - creates new instance of this class
    function new( string name = "m_driver_h", uvm_component parent = null );
        super.new( name, parent );
    endfunction: new

    // Build - instantiates child components
    function void build_phase( uvm_phase phase );
        super.build_phase( phase );
        analysis_port = new( "analysis_port", this );
    endfunction: build_phase

    // Run - starts the processing in driver (bidirectional)
    task run_phase( uvm_phase phase );
        // synchronize with DUT
        vif.wait_for_clock();
        forever begin
            // get next available sequence item
            seq_item_port.get_next_item( req );
            // drive ports
            vif.drive( req );
            // send transaction to GM
            analysis_port.write( req );
            // synchronize with DUT
            vif.wait_for_clock();
            // received sequence has been consumed
            seq_item_port.item_done();
        end
    endtask: run_phase

endclass: timer_t_driver
