`include "uvm_macros.svh"

// import agent package for transaction and wrapper base classes
import uvm_pkg::*;
import sv_param_pkg::*;
import sv_timer_t_agent_pkg::*;

// DUT interface pins
interface itimer_itf( input logic CLK );

    // signals of the virtual interface 1:1
    // member signals
    logic                  RST;
    logic                  P_IRQ;
    logic [ADDR_WIDTH-1:0] ADDRESS;
    logic [1:0]            REQUEST;
    logic [2:0]            RESPONSE;
    logic [DATA_WIDTH-1:0] DATA_OUT;
    logic [DATA_WIDTH-1:0] DATA_IN;

    // clocking blocks

    // testbench point of view
    clocking cb @( posedge CLK );
        output RST, ADDRESS, REQUEST, DATA_IN;
        input  P_IRQ, RESPONSE, DATA_OUT;
    endclocking: cb

    // monitor point of view
    clocking cbm @( posedge CLK );
        input  RST, P_IRQ, ADDRESS, REQUEST, RESPONSE, DATA_OUT, DATA_IN;
    endclocking: cbm

    // drive - drive input and inout pins
    task automatic drive( timer_t_transaction t );
        cb.RST     <= t.RST;
        cb.ADDRESS <= t.ADDRESS;
        cb.REQUEST <= t.REQUEST;
        cb.DATA_IN <= t.DATA_IN;
    endtask: drive

    // monitor - read values on all interface pins using monitor clocking blocks
    task automatic monitor( timer_t_transaction t );
        t.RST      = cbm.RST;
        t.P_IRQ    = cbm.P_IRQ;
        t.ADDRESS  = cbm.ADDRESS;
        t.REQUEST  = cbm.REQUEST;
        t.RESPONSE = cbm.RESPONSE;
        t.DATA_OUT = cbm.DATA_OUT;
        t.DATA_IN  = cbm.DATA_IN;
    endtask: monitor

    // monitor - read values on all interface pins asynchronously (no clocking blocks)
    // after analysis_port.write( dut ) in monitor.run_phase
    task automatic async_monitor( timer_t_transaction t );
        t.RST      = RST;
        t.P_IRQ    = P_IRQ;
        t.ADDRESS  = ADDRESS;
        t.REQUEST  = REQUEST;
        t.RESPONSE = RESPONSE;
        t.DATA_OUT = DATA_OUT;
        t.DATA_IN  = DATA_IN;
    endtask: async_monitor

    // wait for n clock cycles
    task automatic wait_for_clock( int n = 1 );
        repeat ( n ) begin
            @( cbm );
        end
    endtask: wait_for_clock

    // wait for reset to finish
    task automatic wait_for_reset_inactive();
        @( posedge RST );
    endtask: wait_for_reset_inactive

endinterface: itimer_itf

// Interface usable to get to internal signals of the DUT
interface dut_internal_if(logic [1:0]ctrl_reg_d);
endinterface: dut_internal_if
