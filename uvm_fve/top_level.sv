// The topmost encapsulation level of the verification
module top;

    import uvm_pkg::*;
    import sv_param_pkg::*;
    import sv_timer_t_agent_pkg::*;
    import sv_timer_t_env_pkg::*;
    import sv_timer_t_test_pkg::*;

    // Global clock signal definition
    logic CLK;

    // clock generation
    initial begin
        CLK <= 'b0;
        #(CLK_PERIOD/2) forever #(CLK_PERIOD/2) CLK = ~CLK;
    end

    // customize the default printer
    initial begin
        automatic uvm_table_printer printer = new;
        printer.knobs.begin_elements = -1;
        printer.knobs.value_width = -1;
        uvm_default_printer = printer;
        $timeformat(-9, 0, " ns", 8);
    end

    // Virtual interface
    itimer_itf timer_t_if( CLK );

    // DUT instance
    timer #(
        .TIMER_ADDR_SPACE_BITS(TIMER_ADDR_SPACE_BITS),
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH),
        .RST_ACT_LEVEL(RST_ACT_LEVEL)
    )
    HDL_DUT_U(
        .CLK(timer_t_if.CLK),
        .RST(timer_t_if.RST),
        .P_IRQ(timer_t_if.P_IRQ),
        .ADDRESS(timer_t_if.ADDRESS),
        .REQUEST(timer_t_if.REQUEST),
        .RESPONSE(timer_t_if.RESPONSE),
        .DATA_OUT(timer_t_if.DATA_OUT),
        .DATA_IN(timer_t_if.DATA_IN)
    );

    bind top.HDL_DUT_U dut_internal_if ctrl(
        .ctrl_reg_d(ctrl_reg_d)
    );
    // assertions checker instance
    bind HDL_DUT_U abv_timer abv_timer_module(
        .CLK(CLK),
        .RST(RST),
        .P_IRQ(P_IRQ),
        .ADDRESS(ADDRESS),
        .REQUEST(REQUEST),
        .DATA_IN(DATA_IN),
        .RESPONSE(RESPONSE),
        .DATA_OUT(DATA_OUT),
        .ctrl_reg_d(ctrl_reg_d),
        .cnt_reg_d(cnt_reg_d),
        .cmp_reg_d(cmp_reg_d),
        .cycle_cnt(cycle_cnt)
    );

    // run default test
    initial begin
        // register virtual interface to database
        uvm_config_db #(virtual itimer_itf )::set( null,
            "uvm_test_top",
            "timer_t_if",
            timer_t_if );

        uvm_config_db #(virtual dut_internal_if )::set( null,"","dut_internal_if",top.HDL_DUT_U.ctrl ) ;
        // start of the simulation
        run_test( "timer_t_test" );
    end
endmodule: top
