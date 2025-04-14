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

// default disable iff (RST === RST_ACT_LEVEL);

property pr1;
    @(posedge CLK) RST === 0 |-> ctrl_reg_d === 0;
endproperty

property pr2;
    @(posedge CLK) disable iff (!RST) RST === 0 |-> cycle_cnt === 0;
endproperty

// ak je adresa mimo rozsah -> skontroluj v dalsom cykle vystavenie response OOR

// Property pr3: Checks if an out-of-range address results in OOR response next cycle
// Assuming CP_RSP_OOR is defined in sv_param_pkg
property pr3;
    @(posedge CLK)  (ADDRESS > 8'h14) |-> ##1 (RESPONSE === CP_RSP_OOR);
endproperty


// counter register is not stable while waiting for IRQ
sequence checkNotStable;
    // cnt reg is not stable while waiting for IRQ
    !$stable(cnt_reg_d) throughout (RST === 1 && P_IRQ === 0);
endsequence

// mod nie je disabled
property pr4;
    @(posedge CLK) ctrl_reg_d != TIMER_CR_DISABLED |-> checkNotStable;
endproperty

property prUnknown;
    @(posedge CLK) RST === !RST_ACT_LEVEL |-> (!$isunknown(ADDRESS)) && (!$isunknown(REQUEST) && (!$isunknown(RESPONSE)) && (!$isunknown(P_IRQ)));
endproperty

property prUnknownDataRead;
    @(posedge CLK) (REQUEST === CP_REQ_READ)
        |=> (!$isunknown((DATA_IN))) && (!$isunknown((DATA_OUT)));
endproperty

property prUnknownDataWrite;
    @(posedge CLK) (REQUEST === CP_REQ_WRITE)
        |-> (!$isunknown((DATA_IN))) && (!$isunknown((DATA_OUT)));
endproperty

property prReadWriteOOR;
     @(posedge CLK) (REQUEST === CP_REQ_READ || REQUEST === CP_REQ_WRITE) && (ADDRESS > 8'h14)
        |-> ##1 (RESPONSE === CP_RSP_OOR);
endproperty

property prReadWriteUnaligned;
     @(posedge CLK) (REQUEST === CP_REQ_READ || REQUEST === CP_REQ_WRITE) && (ADDRESS[1:0] != 2'b00)
        |-> ##1 (RESPONSE === CP_RSP_UNALIGNED);
endproperty

property checkWriteReadSameAddr;
    logic [ADDR_WIDTH-1:0] v_addr;
    logic [DATA_WIDTH-1:0] v_data;

    @(posedge CLK)
    ( (REQUEST === CP_REQ_WRITE),
      v_addr = ADDRESS,
      v_data = DATA_IN )
    ##1
    ( REQUEST === CP_REQ_READ && ADDRESS === v_addr )
    |->
    ##1
    ( DATA_OUT === v_data );
endproperty

property ackAfterCorrectAddr;
    @(posedge CLK)
    ( (REQUEST === CP_REQ_READ || REQUEST === CP_REQ_WRITE) && ADDRESS <= 8'h14 && ADDRESS[1:0] === 2'b00)
    |-> ##1
    ( RESPONSE === CP_RSP_ACK );
endproperty

property idleResponseToNonReq;
    @(posedge CLK)
    ( (REQUEST === CP_REQ_NONE) )
    |-> ##1
    ( RESPONSE === CP_RSP_IDLE );
endproperty

property errorResponseToResReq;
    @(posedge CLK)
    ( (REQUEST === CP_REQ_RESERVED) )
    |-> ##1
    ( RESPONSE === CP_RSP_ERROR );
endproperty

property noWaitResponse;
    @(posedge CLK) (RST === !RST_ACT_LEVEL) |-> !(RESPONSE === CP_RSP_WAIT);
endproperty

property irqAfterCmpCntMatch;
    @(posedge CLK iff ctrl_reg_d != TIMER_CR_DISABLED) cnt_reg_d === cmp_reg_d
        |-> ##1 (P_IRQ === 1);
endproperty

property clearCntAfterCmpCntMatchAutoRestart;
    @(posedge CLK) ((cnt_reg_d === cmp_reg_d) && (ctrl_reg_d === TIMER_CR_AUTO_RESTART)) |-> ##1 ( cnt_reg_d === 0 );
endproperty

property incCntAfterCmpCntMatchContinuous;
    @(posedge CLK) ((cnt_reg_d === cmp_reg_d) && (ctrl_reg_d === TIMER_CR_CONTINUOUS)) |-> ##1 ( cnt_reg_d === $past(cnt_reg_d) + 1 );
endproperty

property clearCntDisAfterCmpCntMatchOneShot;
    @(posedge CLK) ((cnt_reg_d === cmp_reg_d) && (ctrl_reg_d === TIMER_CR_ONESHOT)) |-> ##1 (cnt_reg_d === 0 && ctrl_reg_d === TIMER_CR_DISABLED);
endproperty

property cycleLRead;
    @(posedge CLK) (ADDRESS === TIMER_CYCLE_L)
        |-> ##1 (DATA_OUT === cycle_cnt[31:0]);
endproperty

property cycleHRead;
    @(posedge CLK) (ADDRESS === TIMER_CYCLE_L)
        |-> ##1 (DATA_OUT === cycle_cnt[31:0]);
endproperty

property cycleCntZeroDuringReset;
    @(posedge CLK) (RST === RST_ACT_LEVEL)
        |-> ##1 (cycle_cnt === 0);
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
        `uvm_error("ABV_TIMER_ASSERT", "Assertion pr1 FAILED: ctrl_reg_d not reset correctly when RST === 0.")
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
        `uvm_fatal("ABV_TIMER_ASSERT", "Assertion pr2 FAILED: cycle_cnt not reset correctly when RST === 0.")
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

SignalsDefined: assert property(prUnknown)
        begin
            `uvm_info("InputSignalNotUnknown", "Assertion prUnknown PASSED: DATA_IN and DATA_OUT are always known.", UVM_LOW)
        end
    else
        // Fail action block
        begin
            // Using fatal as in the original code
            `uvm_fatal("InputSignalNotUnknown", "Assertion prUnknown FAILED: DATA_IN and DATA_OUT are unknown.")
        end

// a   prUnknownDataRead
a_prUnknownDataRead: assert property (prUnknownDataRead) else $error("ACK did not follow REQ within 2 cycles");

// a   prUnknownDataWrite
a_prUnknownDataWrite: assert property (prUnknownDataWrite) else $error("ACK did not follow REQ within 2 cycles");

// a+c prReadOOR
a_prReadWriteOOR: assert property (prReadWriteOOR) else $error("ACK did not follow REQ within 2 cycles");
c_prReadWriteOOR: cover property (prReadWriteOOR) $info("Correct REQ/ACK sequence observed");
// a+c prReadWriteUnaligned
a_prReadWriteUnaligned: assert property (prReadWriteUnaligned) else $error("ACK did not follow REQ within 2 cycles");
c_prReadWriteUnaligned: cover property (prReadWriteUnaligned) $info("Correct REQ/ACK sequence observed");
// a+c checkWriteReadSameAddr
a_checkWriteReadSameAddr: assert property (checkWriteReadSameAddr) else $error("ACK did not follow REQ within 2 cycles");
c_checkWriteReadSameAddr: cover property (checkWriteReadSameAddr) $info("Correct REQ/ACK sequence observed");
// a+c ackAfterCorrectAddr
a_ackAfterCorrectAddr: assert property (ackAfterCorrectAddr) else $error("ACK did not follow REQ within 2 cycles");
c_ackAfterCorrectAddr: cover property (ackAfterCorrectAddr) $info("Correct REQ/ACK sequence observed");
// a+c idleResponseToNonReq
a_idleResponseToNonReq: assert property (idleResponseToNonReq) else $error("ACK did not follow REQ within 2 cycles");
c_idleResponseToNonReq: cover property (idleResponseToNonReq) $info("Correct REQ/ACK sequence observed");

// a   noWaitResponse
a_noWaitResponse: assert property (noWaitResponse) else $error("ACK did not follow REQ within 2 cycles");

// a+c irqAfterCmpCntMatch
a_irqAfterCmpCntMatch: assert property (irqAfterCmpCntMatch) else $error("ACK did not follow REQ within 2 cycles");
c_irqAfterCmpCntMatch: cover property (irqAfterCmpCntMatch) $info("Correct REQ/ACK sequence observed");
// a+c clearCntAfterCmpCntMatchAutoRestart
a_clearCntAfterCmpCntMatchAutoRestart: assert property (clearCntAfterCmpCntMatchAutoRestart) else $error("ACK did not follow REQ within 2 cycles");
c_clearCntAfterCmpCntMatchAutoRestart: cover property (clearCntAfterCmpCntMatchAutoRestart) $info("Correct REQ/ACK sequence observed");
// a+c incCntAfterCmpCntMatchContinuous
a_incCntAfterCmpCntMatchContinuous: assert property (incCntAfterCmpCntMatchContinuous) else $error("ACK did not follow REQ within 2 cycles");
c_incCntAfterCmpCntMatchContinuous: cover property (incCntAfterCmpCntMatchContinuous) $info("Correct REQ/ACK sequence observed");
// a+c clearCntDisAfterCmpCntMatchOneShot
a_clearCntDisAfterCmpCntMatchOneShot: assert property (clearCntDisAfterCmpCntMatchOneShot) else $error("ACK did not follow REQ within 2 cycles");
c_clearCntDisAfterCmpCntMatchOneShot: cover property (clearCntDisAfterCmpCntMatchOneShot) $info("Correct REQ/ACK sequence observed");
// a+c cycleLRead
a_cycleLRead: assert property (cycleLRead) else $error("ACK did not follow REQ within 2 cycles");
c_cycleLRead: cover property (cycleLRead) $info("Correct REQ/ACK sequence observed");
// a+c cycleHRead
a_cycleHRead: assert property (cycleHRead) else $error("ACK did not follow REQ within 2 cycles");
c_cycleHRead: cover property (cycleHRead) $info("Correct REQ/ACK sequence observed");
// a+c cycleCntZeroDuringReset
a_cycleCntZeroDuringReset: assert property (cycleCntZeroDuringReset) else $error("ACK did not follow REQ within 2 cycles");
c_cycleCntZeroDuringReset: cover property (cycleCntZeroDuringReset) $info("Correct REQ/ACK sequence observed");


endmodule : abv_timer
