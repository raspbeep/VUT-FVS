// This class measures exercised combinations of DUTs interface ports.
class timer_t_coverage extends uvm_subscriber #(timer_t_transaction);

    // registration of component tools
    `uvm_component_utils( timer_t_coverage )

    // member attributes
    local T m_transaction_h;
    virtual dut_internal_if ivif;

    // Covergroup definition
    covergroup FunctionalCoverage( string inst );
    
        // 1 Coverpoint a biny pro módy timeru, abychom měli jistotu, že se každý mód aktivoval alespoň jednou. Váha 0 (pomocný coverpoint pro cross).
        modes: coverpoint ivif.ctrl_reg_d {
            bins disabled = { TIMER_CR_DISABLED };
            bins auto_restart = { TIMER_CR_AUTO_RESTART };
            bins oneshot = { TIMER_CR_ONESHOT };
            bins continuous = { TIMER_CR_CONTINUOUS };
            option.weight = 0;
        }

        // 2 Coverpoint a biny pro povolené operace (REQUEST = write, read, none, hodnota RESERVED by měla být ignorována). Váha 0 (pomocný coverpoint pro cross).
        request: coverpoint m_transaction_h.REQUEST {
            bins req_none = { CP_REQ_NONE };
            bins req_read = { CP_REQ_READ };
            bins req_write = { CP_REQ_WRITE };
            option.weight = 0;
        }

        // 3 Coverpoint a biny pro hodnoty 0 a 1 signálu reset.
        reset_inactive: coverpoint m_transaction_h.RST {
            bins inactive = { ~RST_ACT_LEVEL };
        }

        // 4 Transition coverpoint pro přechody na signálu reset: 0->1, 1->0. Každý přechod musí nastat alespoň 5x.
        cv4: coverpoint m_transaction_h.RST {
            bins transitions[] = (0=>1), (1=>0);
            option.at_least = 5;
        }

        // 5 Coverpoint a biny pro adresy 8'h0, 8'h4, 8'h8, 8'h10, 8'h14. Váha 0 (pomocný coverpoint pro cross). 
        addresses: coverpoint m_transaction_h.ADDRESS {
            bins addr_cnt   = { TIMER_CNT };
            bins addr_cmp   = { TIMER_CMP };
            bins addr_cr    = { TIMER_CR };
            bins addr_cl_l  = { TIMER_CYCLE_L };
            bins addr_cl_h  = { TIMER_CYCLE_H };
            option.weight = 0;
        }

        // 6 Cross coverpoint všech adres (můžete použít coverpoint z 5.), operace write, a neaktivního resetu (můžete použít coverpoint z 3. a omezit se na neaktivní reset).
        cv6: cross request, reset_inactive, addresses {
            bins all_addr_write_no_rst = binsof(addresses) && binsof(reset_inactive) && binsof(request.req_write);
        }

        // 7 Cross coverpoint všech adres (můžete použít coverpoint z 5.), operace read, a neaktivního resetu (můžete použít coverpoint z 3. a omezit se na neaktivní reset).
        cv7: cross request, reset_inactive, addresses {
            bins all_addr_write_no_rst = binsof(addresses) && binsof(reset_inactive) && binsof(request.req_read);
        }

        // 8 Coverpoint a biny pro hodnoty 0 a 1 signálu přerušení.
        irq: coverpoint m_transaction_h.P_IRQ {
            bins irq_active   = { 1 };
            bins irq_inactive = { 0 };
        }
        
        // 9 Transition coverpoint pro přechody na signálu přerušení: 0->1, 1->0. Každý přechod musí nastat alespoň 10x.
        cv9: coverpoint m_transaction_h.P_IRQ {
            bins transitions[] = (0=>1), (1=>0);
            option.at_least = 10;
        }

        // 10 Cross coverpoint pro aktivní přerušení ve všech módech (kromě DISABLED).
        cv10: cross modes, irq {
            bins auto_restart = binsof(modes.auto_restart) && binsof(irq.irq_active);
            bins oneshot = binsof(modes.oneshot) && binsof(irq.irq_active);
            bins continuous = binsof(modes.continuous) && binsof(irq.irq_active);
        }

        // 11 Transition coverpoint pro přechody mezi módy, tzn. např. z módu ONE_SHOT do DISABLED, z DISABLED do AUTO_RESTART atd.
        all_modes_transitions: coverpoint ivif.ctrl_reg_d {
            bins transitions[] = ([TIMER_CR_DISABLED:TIMER_CR_CONTINUOUS] => [TIMER_CR_DISABLED:TIMER_CR_CONTINUOUS]), 
                                ([TIMER_CR_CONTINUOUS:TIMER_CR_DISABLED] => [TIMER_CR_CONTINUOUS:TIMER_CR_DISABLED]);
            option.at_least = 10;
        }

        // 12 Cross coverpoint všech adres, všech operací kromě RESERVED (můžete použít coverpoint z 2.),
        // neaktivního resetu (můžete použít coverpoint z 3. a omezit se na neaktivní reset), a všech módů
        // (můžete použít coverpoint z 1).
        cv12: cross addresses, request, reset_inactive, modes {
            bins all = binsof(addresses) && binsof(request) && binsof(reset_inactive) && binsof(modes);
        }

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
