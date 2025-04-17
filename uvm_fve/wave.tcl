# Signals of interfaces.
proc basic { PATH } {
    add wave -noupdate -divider "Basic signals"
    add wave -noupdate -color yellow -label CLK $PATH/CLK
    add wave -noupdate -color yellow -label RST $PATH/RST
}

proc itimer_itf { PATH } {
    set PROBE_PATH $PATH

    add wave -noupdate -divider "input"
    add wave -noupdate -hex -label ADDRESS $PROBE_PATH/ADDRESS
    add wave -noupdate -hex -label REQUEST $PROBE_PATH/REQUEST
    add wave -noupdate -hex -label DATA_IN $PROBE_PATH/DATA_IN

    add wave -noupdate -divider "TIMER DUT"
    add wave -noupdate -divider "output"
    add wave -noupdate -hex -label P_IRQ $PROBE_PATH/P_IRQ
    add wave -noupdate -hex -label RESPONSE $PROBE_PATH/RESPONSE
    add wave -noupdate -hex -label DATA_OUT $PROBE_PATH/DATA_OUT

    add wave -noupdate -divider "regs:"
    add wave -noupdate -hex -label cnt_reg_d sim:/top/HDL_DUT_U/cnt_reg_d
    add wave -noupdate -hex -label cmp_reg_d sim:/top/HDL_DUT_U/cmp_reg_d
    add wave -noupdate -hex -label ctrl_reg_d sim:/top/HDL_DUT_U/ctrl_reg_d
    add wave -noupdate -hex -label cycle_cnt sim:/top/HDL_DUT_U/cycle_cnt

    add wave -noupdate -divider "TIMER GM:"
    add wave -noupdate -divider "output"
    add wave -noupdate -hex -color orange -label P_IRQ sv_timer_t_gm_pkg::timer_t_gm::P_IRQ
    add wave -noupdate -hex -color orange -label RESPONSE sv_timer_t_gm_pkg::timer_t_gm::RESPONSE
    add wave -noupdate -hex -color orange -label DATA_OUT sv_timer_t_gm_pkg::timer_t_gm::DATA_OUT
    add wave -noupdate -hex -color orange -label ctrl_reg sv_timer_t_gm_pkg::timer_t_gm::ctrl_reg
    add wave -noupdate -hex -color orange -label timer_cnt sv_timer_t_gm_pkg::timer_t_gm::timer_cnt
    add wave -noupdate -hex -color orange -label timer_cmp sv_timer_t_gm_pkg::timer_t_gm::timer_cmp
    add wave -noupdate -hex -color orange -label cycle_cnt sv_timer_t_gm_pkg::timer_t_gm::cycle_cnt
    # add wave -noupdate -hex -color orange -label irq_signal_next_clock sv_timer_t_gm_pkg::timer_t_gm::irq_signal_next_clock
    # add wave -noupdate -hex -color orange -label reset_cnt_next_clock sv_timer_t_gm_pkg::timer_t_gm::reset_cnt_next_clock
}

proc customize_gui { TOP_MODULE HDL_DUT } {
    # View simulation waves
    view wave
    # Remove all previous waves first
    delete wave *
    # Clock and reset signals
    puts $TOP_MODULE
    puts $HDL_DUT
    basic /top/timer_t_if
    itimer_itf top/timer_t_if

    # Additional wave configuration
    TreeUpdate [SetDefaultTree]
    configure wave -namecolwidth 200
    configure wave -valuecolwidth 100
    configure wave -justifyvalue left
    configure wave -signalnamewidth 0
    configure wave -gridoffset 0
    configure wave -gridperiod {10 ns}
    configure wave -griddelta 50
    configure wave -timeline 0
    configure wave -timelineunits ns
    WaveRestoreZoom {0 ns} {250 ns}
    update
    view structure
    view signals
    wave refresh
}
