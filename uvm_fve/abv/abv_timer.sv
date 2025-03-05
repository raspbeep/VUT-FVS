`include "uvm_macros.svh"
import uvm_pkg::*;
import sv_param_pkg::*;

module abv_timer (
    input logic                  CLK,
    input logic                  RST,
    input logic                  P_IRQ,
    input logic [ADDR_WIDTH-1:0] ADDRESS,
    input logic [1:0]            REQUEST,
    input logic [2:0]            RESPONSE,
    input logic [DATA_WIDTH-1:0] DATA_OUT,
    input logic [DATA_WIDTH-1:0] DATA_IN,
    input logic [1:0]            ctrl_reg_d,
    input logic [DATA_WIDTH-1:0] cnt_reg_d,
    input logic [DATA_WIDTH-1:0] cmp_reg_d,
    input logic [63:0]           cycle_cnt
);


endmodule : abv_timer
