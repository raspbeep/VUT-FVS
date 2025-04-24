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

property addrOORResponse;
    @(posedge CLK)
    disable iff ($isunknown(RST) || RST === RST_ACT_LEVEL)
    (ADDRESS > 8'h14 && (REQUEST == CP_REQ_READ || REQUEST == CP_REQ_WRITE)) |-> ##1 (RESPONSE === CP_RSP_OOR);
endproperty

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

// OOR has priority over UNALIGNED
property prReadWriteOOR;
     @(posedge CLK)
     disable iff ($isunknown(RST) || RST === RST_ACT_LEVEL)
     (REQUEST === CP_REQ_READ || REQUEST === CP_REQ_WRITE) && (ADDRESS > 8'h14)
        |-> ##1 (RESPONSE === CP_RSP_OOR);
endproperty

// does not apply if the address is OOR
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
    // 1) write cycle: RST must be known & inactive
    (REQUEST == CP_REQ_WRITE
       && (ADDRESS == TIMER_CNT || ADDRESS == TIMER_CMP || 
          (ADDRESS == TIMER_CR && DATA_IN <= TIMER_CR_CONTINUOUS)),
     v_addr  = ADDRESS,
     v_data  = DATA_IN)
    // 2) read cycle: again RST known & inactive
    ##1 (
      REQUEST == CP_REQ_READ
      && ADDRESS == v_addr
    )
  // 3) data‐out check one cycle later: still RST known & inactive
  |-> ##1 (
      DATA_OUT == v_data
    );
endproperty

// does not apply if the address is OOR or UNALIGNED
property ackAfterCorrectAddr;
    @(posedge CLK)
    disable iff ($isunknown(RST) || RST === RST_ACT_LEVEL)
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
    disable iff ($isunknown(RST) || RST === RST_ACT_LEVEL)
    ( (REQUEST === CP_REQ_RESERVED) )
    |-> ##1
    ( RESPONSE === CP_RSP_ERROR );
endproperty

// this should never ever happen
property noWaitResponse;
    @(posedge CLK) (RST === !RST_ACT_LEVEL) |-> !(RESPONSE === CP_RSP_WAIT);
endproperty

property irqAfterCmpCntMatch;
    @(posedge CLK)
    disable iff ($isunknown(RST) || RST === RST_ACT_LEVEL)
    ((ctrl_reg_d != TIMER_CR_DISABLED) && (cnt_reg_d === cmp_reg_d))
        |-> ##1 (P_IRQ === 1);
endproperty

// does not apply if we change the mode during IRQ
property clearCntAfterCmpCntMatchAutoRestart;
    @(posedge CLK) ((cnt_reg_d === cmp_reg_d) && (ctrl_reg_d === TIMER_CR_AUTO_RESTART)
        && !((REQUEST == CP_REQ_WRITE && DATA_IN != TIMER_CR_DISABLED)))
        |-> ##1 ( cnt_reg_d === 0 );
endproperty

// does not apply if:
//      we are changing mode
//      OR we are writing another value to CNT
property incCntAfterCmpCntMatchContinuous;
    @(posedge CLK)
    disable iff ($isunknown(RST) || RST === RST_ACT_LEVEL)
    ((cnt_reg_d === cmp_reg_d) && (ctrl_reg_d === TIMER_CR_CONTINUOUS)
        && !((REQUEST == CP_REQ_WRITE && ADDRESS == TIMER_CR && DATA_IN != TIMER_CR_DISABLED) || (REQUEST == CP_REQ_WRITE && ADDRESS == TIMER_CNT)) )
        |-> ##1 ( cnt_reg_d === $past(cnt_reg_d) + 1 );
endproperty

// does not apply in cornercase
property clearCntDisAfterCmpCntMatchOneShot;
    @(posedge CLK) ((cnt_reg_d === cmp_reg_d) && (ctrl_reg_d === TIMER_CR_ONESHOT)
        && !(REQUEST == CP_REQ_WRITE && DATA_IN != TIMER_CR_DISABLED))
        |-> ##1 (cnt_reg_d === 0 && ctrl_reg_d === TIMER_CR_DISABLED);
endproperty

// must be the current clock value
property cycleLRead;
    @(posedge CLK)
    disable iff ($isunknown(RST) || RST === RST_ACT_LEVEL)
    (ADDRESS === TIMER_CYCLE_L && REQUEST === CP_REQ_READ)
        |-> ##1 (DATA_OUT === cycle_cnt[31:0]);
endproperty

// must be the current clock value
property cycleHRead;
    @(posedge CLK)
    disable iff ($isunknown(RST) || RST === RST_ACT_LEVEL)
    (ADDRESS === TIMER_CYCLE_H && REQUEST === CP_REQ_READ)
        |-> ##1 (DATA_OUT === cycle_cnt[63:32]);
endproperty

// must be synchronous
property cycleCntZeroDuringReset;
    @(posedge CLK) (RST === RST_ACT_LEVEL)
        |-> ##1 (cycle_cnt === 0);
endproperty

// --- Assertions and Covers ---

a_ResetRegCheck: assert property (asyncRegZeroWhenReset)
else
    begin
        `uvm_error("ABV_TIMER_ASSERT", "Assertion asyncRegZeroWhenReset FAILED: registers not resetting asynchronously with RST.")
    end

a_ResetCycleCntRegCheck: assert property (cyclecntRegZeroWhenReset)
else
    begin
        `uvm_error("ABV_TIMER_ASSERT", "Assertion cyclecntRegZeroWhenReset FAILED: cycle cnt not resetting synchronously with RST.")
    end

// --- asserts and covers from LAB4 ---

a_addrOORResponseCheck: assert property (addrOORResponse)
else
    begin
        `uvm_error("ABV_TIMER_ASSERT", $sformatf("Assertion addrOORResponse FAILED: OOR Address 0x%0h did not trigger OOR response (RESPONSE = %0d).", ADDRESS, RESPONSE))
    end

a_signalsKnownInactiveResetCheck: assert property(signalsKnownInactiveReset)
else
    begin
        `uvm_error("ABV_TIMER_ASSERT", "Assertion signalsKnownInactiveReset FAILED: ADDRESS, REQUEST, RESPONSE, P_IRQ are unknown with inactive RST.")
    end

// a   prUnknownDataRead
a_prUnknownDataRead: assert property (prUnknownDataRead)
else
    begin
        `uvm_error("ABV_TIMER_ASSERT", "Assertion prUnknownDataRead FAILED: DATA_IN or DATA_OUT has undefined values during reading.")
    end

// a   prUnknownDataWrite
a_prUnknownDataWrite: assert property (prUnknownDataWrite)
else
    begin
        `uvm_error("ABV_TIMER_ASSERT", "Assertion prUnknownDataWrite FAILED: DATA_IN or DATA_OUT has undefined values during writing.")
    end

// a+c prReadWriteOOR
a_prReadWriteOOR: assert property (prReadWriteOOR)
else
    begin
        `uvm_error("ABV_TIMER_ASSERT", "Assertion prReadWriteOOR FAILED: Writing or reading out of the allowed address range did not cause OOR response.")
    end

c_prReadWriteOOR: cover property (prReadWriteOOR);

// a+c prReadWriteUnaligned
a_prReadWriteUnaligned: assert property (prReadWriteUnaligned)
else
    begin
        `uvm_error("ABV_TIMER_ASSERT", "Assertion prReadWriteUnaligned FAILED: Writing or reading to/from unaligned address did not cause UNALIGNED response.")
    end

c_prReadWriteUnaligned: cover property (prReadWriteUnaligned);

// a+c checkWriteReadSameAddr
a_checkWriteReadSameAddr: assert property (checkWriteReadSameAddr)
else
    begin
        `uvm_error("ABV_TIMER_ASSERT", "Assertion checkWriteReadSameAddr FAILED: Read did not read fresh data after writing them in the previous clock.")
    end

c_checkWriteReadSameAddr: cover property (checkWriteReadSameAddr);

// a+c ackAfterCorrectAddr
a_ackAfterCorrectAddr: assert property (ackAfterCorrectAddr)
else
    begin
        `uvm_error("ABV_TIMER_ASSERT", "Assertion ackAfterCorrectAddr FAILED: No ACK response after a valid address read/write.")
    end

c_ackAfterCorrectAddr: cover property (ackAfterCorrectAddr);

// a+c idleResponseToNonReq
a_idleResponseToNonReq: assert property (idleResponseToNonReq)
else
    begin
        `uvm_error("ABV_TIMER_ASSERT", "Assertion idleResponseToNonReq FAILED: No IDLE response to NONE request.")
    end

c_idleResponseToNonReq: cover property (idleResponseToNonReq);

// a+c errorResponseToResReq
a_errorResponseToResReq: assert property (errorResponseToResReq)
else
    begin
        `uvm_error("ABV_TIMER_ASSERT", "Assertion errorResponseToResReq FAILED: No ERROR response to RESERVED request.")
    end

c_errorResponseToResReq: cover property (errorResponseToResReq);

// a   noWaitResponse
a_noWaitResponse: assert property (noWaitResponse)
else
    begin
        `uvm_error("ABV_TIMER_ASSERT", "Assertion noWaitResponse FAILED: There should not be any WAIT response (ever).")
    end

// a+c irqAfterCmpCntMatch
a_irqAfterCmpCntMatch: assert property (irqAfterCmpCntMatch)
else
    begin
        `uvm_error("ABV_TIMER_ASSERT", "Assertion irqAfterCmpCntMatch FAILED: IRQ should be (active) for exactly one clock after cmp_reg == cnt_reg match.")
    end

c_irqAfterCmpCntMatch: cover property (irqAfterCmpCntMatch);

// a+c clearCntAfterCmpCntMatchAutoRestart
a_clearCntAfterCmpCntMatchAutoRestart: assert property (clearCntAfterCmpCntMatchAutoRestart)
else
    begin
        `uvm_error("ABV_TIMER_ASSERT", "Assertion clearCntAfterCmpCntMatchAutoRestart FAILED: cnt_reg did not reset after IRQ in AUTO_RESTART mode.")
    end

c_clearCntAfterCmpCntMatchAutoRestart: cover property (clearCntAfterCmpCntMatchAutoRestart);

// a+c incCntAfterCmpCntMatchContinuous
a_incCntAfterCmpCntMatchContinuous: assert property (incCntAfterCmpCntMatchContinuous)
else
    begin
        `uvm_error("ABV_TIMER_ASSERT", "Assertion incCntAfterCmpCntMatchContinuous FAILED: cnt_reg did not increment after IRQ in CONTINUOUS mode.")
    end

c_incCntAfterCmpCntMatchContinuous: cover property (incCntAfterCmpCntMatchContinuous);

// a+c clearCntDisAfterCmpCntMatchOneShot
a_clearCntDisAfterCmpCntMatchOneShot: assert property (clearCntDisAfterCmpCntMatchOneShot)
else
    begin
        `uvm_error("ABV_TIMER_ASSERT", "Assertion clearCntDisAfterCmpCntMatchOneShot FAILED: cnt_reg did not reset OR the mode was not set to DISABLED after IRQ in ONE_SHOT mode.")
    end
c_clearCntDisAfterCmpCntMatchOneShot: cover property (clearCntDisAfterCmpCntMatchOneShot);

// a+c cycleLRead
a_cycleLRead: assert property (cycleLRead)
else
    begin
        `uvm_error("ABV_TIMER_ASSERT", "Assertion cycleLRead FAILED: cycle_l read did not return valid current clock value.")
    end

c_cycleLRead: cover property (cycleLRead);

// a+c cycleHRead
a_cycleHRead: assert property (cycleHRead)
else
    begin
        `uvm_error("ABV_TIMER_ASSERT", "Assertion cycleLRead FAILED: cycle_h read did not return valid current clock value.")
    end

c_cycleHRead: cover property (cycleHRead);

// a+c cycleCntZeroDuringReset
a_cycleCntZeroDuringReset: assert property (cycleCntZeroDuringReset)
else
    begin
        `uvm_error("ABV_TIMER_ASSERT", "Assertion cycleCntZeroDuringReset FAILED: cycle_cnt did not reset synchronously with RST signal.")
    end

c_cycleCntZeroDuringReset: cover property (cycleCntZeroDuringReset);
endmodule : abv_timer
