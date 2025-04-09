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

property pr1;
    @(posedge CLK) RST == 0 |-> ctrl_reg_d == 0;
endproperty

property pr2;
    @(posedge CLK) disable iff (!RST) RST == 0 |-> cycle_cnt == 0;
endproperty

// ak je adresa mimo rozsah -> skontroluj v dalsom cykle vystavenie response OOR

// Property pr3: Checks if an out-of-range address results in OOR response next cycle
// Assuming CP_RSP_OOR is defined in sv_param_pkg
property pr3;
    @(posedge CLK)  (ADDRESS > 8'h14) |-> ##1 (RESPONSE == CP_RSP_OOR);
endproperty


// counter register is not stable while waiting for IRQ
sequence checkNotStable;
    // cnt reg is not stable while waiting for IRQ
    !$stable(cnt_reg_d) throughout (RST == 1 && P_IRQ == 0);
endsequence

// mod nie je disabled
property pr4:
    @(posedge CLK) ctrl_reg_d != TIMER_CR_DISABLED |-> checkNotStable;
endproperty


// --- Assertions ---

ResetCtrlRegCheck: assert property (pr1)
    // Pass action block
    begin
        `uvm_info("ABV_TIMER_ASSERT", "Assertion pr1 PASSED: ctrl_reg_d reset correctly.", UVM_LOW)
    end
else
    // Fail action block
    begin
        `uvm_error("ABV_TIMER_ASSERT", "Assertion pr1 FAILED: ctrl_reg_d not reset correctly when RST == 0.")
    end

ResetCycleCntCheck: assert property (pr2)
    // Pass action block
    begin
        `uvm_info("ABV_TIMER_ASSERT", "Assertion pr2 PASSED: cycle_cnt reset correctly.", UVM_LOW)
    end
else
    // Fail action block
    begin
        // Using fatal as in the original code
        `uvm_fatal("ABV_TIMER_ASSERT", "Assertion pr2 FAILED: cycle_cnt not reset correctly when RST == 0.")
    end

// You defined pr3 but didn't assert it, let's add it:
AddrRangeCheck: assert property (pr3)
    // Pass action block
    begin
        // Use $sformatf for more informative messages
        `uvm_info("ABV_TIMER_ASSERT", $sformatf("Assertion pr3 PASSED: OOR Address 0x%0h triggered correct response.", ADDRESS), UVM_LOW)
    end
else
    // Fail action block
    begin
        `uvm_error("ABV_TIMER_ASSERT", $sformatf("Assertion pr3 FAILED: OOR Address 0x%0h did not trigger OOR response (RESPONSE = %0d).", ADDRESS, RESPONSE))
    end


endmodule : abv_timer
