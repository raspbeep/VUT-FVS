package sv_param_pkg;
    import uvm_pkg::*;

    `include "uvm_macros.svh"

    // clocks and resets
    parameter CLK_PERIOD = 10ns;

    // generic parameters
    parameter logic RST_ACT_LEVEL = 1'b0;
    parameter DATA_WIDTH = 32;
    parameter ADDR_WIDTH = 32;
    parameter TIMER_ADDR_SPACE_BITS = 8;

    // test parameters
    // how many transaction to generate
    parameter TRANSACTION_COUNT = 10000;
    // initial seed for the PRNG
    parameter SEED = 10162;

    // REQUEST CONSTANTS
    typedef enum bit [1:0]
    {
        CP_REQ_NONE = 2'b00,
        CP_REQ_READ = 2'b01,
        CP_REQ_WRITE = 2'b10,
        CP_REQ_RESERVED = 2'b11
    } request_codes_e;

        // RESPONSE CONSTANTS
    typedef enum bit [2:0]
    {
        CP_RSP_IDLE = 3'b000,
        CP_RSP_ACK = 3'b001,
        CP_RSP_WAIT = 3'b010,
        CP_RSP_ERROR = 3'b011,
        CP_RSP_UNALIGNED = 3'b100,
        CP_RSP_OOR = 3'b101
    } response_codes_e;

    // timer register addresses
    // register addresses
    typedef enum bit [7:0]
    {
        TIMER_CNT = 8'h00,
        TIMER_CMP  = 8'h04,
        TIMER_CR = 8'h08,
        TIMER_CYCLE_L = 8'h10,
        TIMER_CYCLE_H = 8'h14
    } reg_address_codes_e;

    typedef enum bit [1:0]
    {
        TIMER_CR_DISABLED = 2'b00,
        TIMER_CR_AUTO_RESTART = 2'b01,
        TIMER_CR_ONESHOT = 2'b10,
        TIMER_CR_CONTINUOUS = 2'b11
    } timer_cr_mode_e;

endpackage: sv_param_pkg
