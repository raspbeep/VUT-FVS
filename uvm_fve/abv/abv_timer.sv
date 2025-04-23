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

property asyncRegZeroWhenReset;
    @(posedge CLK) RST === RST_ACT_LEVEL |-> (
        ctrl_reg_d === TIMER_CR_DISABLED &&
        cnt_reg_d  === 0 &&
        cmp_reg_d  === 0
    );
endproperty

property cyclecntRegZeroWhenReset;
    @(posedge CLK) RST === RST_ACT_LEVEL |=> cnt_reg_d  === 0;
endproperty

// Property pr3: Checks if an out-of-range address results in OOR response next cycle
property addrOORResponse;
    @(posedge CLK)
    disable iff ($isunknown(RST) || RST === RST_ACT_LEVEL)
    (ADDRESS > 8'h14) |-> ##1 (RESPONSE === CP_RSP_OOR);
endproperty

// counter register is not stable while waiting for IRQ
sequence checkNotStable;
    // cnt reg is not stable while waiting for IRQ
    !$stable(cnt_reg_d) throughout (RST === RST_ACT_LEVEL && P_IRQ === 0);
endsequence

property signalsKnownInactiveReset;
    @(posedge CLK)
    disable iff ($isunknown(RST) || RST === RST_ACT_LEVEL)
    (!$isunknown(ADDRESS) &&
     !$isunknown(REQUEST) &&
     !$isunknown(RESPONSE) &&
     !$isunknown(P_IRQ)
    );
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
     @(posedge CLK)
     disable iff ($isunknown(RST) || RST === RST_ACT_LEVEL)
     (REQUEST === CP_REQ_READ || REQUEST === CP_REQ_WRITE) && (ADDRESS > 8'h14)
        |-> ##1 (RESPONSE === CP_RSP_OOR);
endproperty

property prReadWriteUnaligned;
     @(posedge CLK)
     disable iff ($isunknown(RST) || RST === RST_ACT_LEVEL)
     (REQUEST === CP_REQ_READ || REQUEST === CP_REQ_WRITE) && (ADDRESS <= 8'h14) && (ADDRESS[1:0] != 2'b00)
        |-> ##1 (RESPONSE === CP_RSP_UNALIGNED);
endproperty

property checkWriteReadSameAddr;
  logic [ADDR_WIDTH-1:0] v_addr;
  logic [DATA_WIDTH-1:0] v_data;

  @(posedge CLK)
  disable iff ($isunknown(RST) || RST === RST_ACT_LEVEL)
    (REQUEST === CP_REQ_WRITE && (ADDRESS === TIMER_CR || ADDRESS === TIMER_CMP), v_addr = ADDRESS, v_data = DATA_IN)

      ##1 (REQUEST === CP_REQ_READ 
            && ADDRESS === v_addr)

    |-> ##1 (DATA_OUT === v_data);
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
    @(posedge CLK) ((cnt_reg_d === cmp_reg_d) && (ctrl_reg_d === TIMER_CR_AUTO_RESTART)
        && !((REQUEST == CP_REQ_WRITE && DATA_IN != TIMER_CR_DISABLED)))
        |-> ##1 ( cnt_reg_d === 0 );
endproperty

// does not apply if:
//      we are changing mode
//      OR we are writing another value to CNT
property incCntAfterCmpCntMatchContinuous;
    @(posedge CLK) ((cnt_reg_d === cmp_reg_d) && (ctrl_reg_d === TIMER_CR_CONTINUOUS)
        && !((REQUEST == CP_REQ_WRITE && ADDRESS == TIMER_CR && DATA_IN != TIMER_CR_DISABLED) || (REQUEST == CP_REQ_WRITE && ADDRESS == TIMER_CNT)) )
        |-> ##1 ( cnt_reg_d === $past(cnt_reg_d) + 1 );
endproperty

property clearCntDisAfterCmpCntMatchOneShot;
    @(posedge CLK) ((cnt_reg_d === cmp_reg_d) && (ctrl_reg_d === TIMER_CR_ONESHOT)
        && !((REQUEST == CP_REQ_WRITE && DATA_IN != TIMER_CR_DISABLED)) )
        |-> ##1 (cnt_reg_d === 0 && ctrl_reg_d === TIMER_CR_DISABLED);
endproperty

property cycleLRead;
    @(posedge CLK) (ADDRESS === TIMER_CYCLE_L && REQUEST === CP_REQ_READ)
        |-> ##1 (DATA_OUT === cycle_cnt[31:0]);
endproperty

property cycleHRead;
    @(posedge CLK) (ADDRESS === TIMER_CYCLE_H && REQUEST === CP_REQ_READ)
        |-> ##1 (DATA_OUT === cycle_cnt[63:32]);
endproperty

property cycleCntZeroDuringReset;
    @(posedge CLK) (RST === RST_ACT_LEVEL)
        |-> ##1 (cycle_cnt === 0);
endproperty



// --- Assertions ---

ResetRegCheck: assert property (asyncRegZeroWhenReset)
else
    begin
        `uvm_error("ABV_TIMER_ASSERT", "Assertion asyncRegZeroWhenReset FAILED: registers not resetting asynchronously with RST.")
    end

ResetCycleCntRegCheck: assert property (cyclecntRegZeroWhenReset)
else
    begin
        `uvm_error("ABV_TIMER_ASSERT", "Assertion cyclecntRegZeroWhenReset FAILED: cycle cnt not resetting synchronously with RST.")
    end

addrOORResponseCheck: assert property (addrOORResponse)
else
    begin
        `uvm_error("ABV_TIMER_ASSERT", $sformatf("Assertion addrOORResponse FAILED: OOR Address 0x%0h did not trigger OOR response (RESPONSE = %0d).", ADDRESS, RESPONSE))
    end

signalsKnownInactiveResetCheck: assert property(signalsKnownInactiveReset)
else
    begin
        `uvm_error("InputSignalNotUnknown", "Assertion signalsKnownInactiveReset FAILED: ADDRESS, REQUEST, RESPONSE, P_IRQ are unknown with inactive RST.")
    end

// a   prUnknownDataRead
a_prUnknownDataRead: assert property (prUnknownDataRead) else $error("ACK did not follow REQ within 2 cycles");

// a   prUnknownDataWrite
a_prUnknownDataWrite: assert property (prUnknownDataWrite) else $error("ACK did not follow REQ within 2 cycles");

// a+c prReadOOR
a_prReadWriteOOR: assert property (prReadWriteOOR) else $error("ACK did not follow REQ within 2 cycles");
c_prReadWriteOOR: cover property (prReadWriteOOR);

// a+c prReadWriteUnaligned
a_prReadWriteUnaligned: assert property (prReadWriteUnaligned) else $error("ACK did not follow REQ within 2 cycles");
c_prReadWriteUnaligned: cover property (prReadWriteUnaligned);

// a+c checkWriteReadSameAddr
a_checkWriteReadSameAddr: assert property (checkWriteReadSameAddr) else $error("ACK did not follow REQ within 2 cycles");
c_checkWriteReadSameAddr: cover property (checkWriteReadSameAddr);

// a+c ackAfterCorrectAddr
a_ackAfterCorrectAddr: assert property (ackAfterCorrectAddr) else $error("ACK did not follow REQ within 2 cycles");
c_ackAfterCorrectAddr: cover property (ackAfterCorrectAddr);

// a+c idleResponseToNonReq
a_idleResponseToNonReq: assert property (idleResponseToNonReq) else $error("ACK did not follow REQ within 2 cycles");
c_idleResponseToNonReq: cover property (idleResponseToNonReq);

a_errorResponseToResReq: assert property (errorResponseToResReq) else $error("ACK did not follow REQ within 2 cycles");
// a   noWaitResponse
a_noWaitResponse: assert property (noWaitResponse) else $error("ACK did not follow REQ within 2 cycles");

// a+c irqAfterCmpCntMatch
a_irqAfterCmpCntMatch: assert property (irqAfterCmpCntMatch) else $error("ACK did not follow REQ within 2 cycles");
c_irqAfterCmpCntMatch: cover property (irqAfterCmpCntMatch);

// a+c clearCntAfterCmpCntMatchAutoRestart
a_clearCntAfterCmpCntMatchAutoRestart: assert property (clearCntAfterCmpCntMatchAutoRestart) else $error("ACK did not follow REQ within 2 cycles");
c_clearCntAfterCmpCntMatchAutoRestart: cover property (clearCntAfterCmpCntMatchAutoRestart);

// a+c incCntAfterCmpCntMatchContinuous
a_incCntAfterCmpCntMatchContinuous: assert property (incCntAfterCmpCntMatchContinuous) else $error("ACK did not follow REQ within 2 cycles");
c_incCntAfterCmpCntMatchContinuous: cover property (incCntAfterCmpCntMatchContinuous);

// a+c clearCntDisAfterCmpCntMatchOneShot
a_clearCntDisAfterCmpCntMatchOneShot: assert property (clearCntDisAfterCmpCntMatchOneShot) else $error("ACK did not follow REQ within 2 cycles");
c_clearCntDisAfterCmpCntMatchOneShot: cover property (clearCntDisAfterCmpCntMatchOneShot);

// a+c cycleLRead
a_cycleLRead: assert property (cycleLRead) else $error("ACK did not follow REQ within 2 cycles");
c_cycleLRead: cover property (cycleLRead);

// a+c cycleHRead
a_cycleHRead: assert property (cycleHRead) else $error("ACK did not follow REQ within 2 cycles");
c_cycleHRead: cover property (cycleHRead);

// a+c cycleCntZeroDuringReset
a_cycleCntZeroDuringReset: assert property (cycleCntZeroDuringReset) else $error("ACK did not follow REQ within 2 cycles");
c_cycleCntZeroDuringReset: cover property (cycleCntZeroDuringReset);
endmodule : abv_timer
