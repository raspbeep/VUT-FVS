package registers_pkg;
  
  `include "uvm_macros.svh"
  
  import uvm_pkg::*;
  import sv_timer_t_agent_pkg::*;
  import sv_param_pkg::*;
    
  `include "timer_reg_block.svh"
  `include "reg_adapter.svh"
  `include "timer_reg_seq.svh"

endpackage : registers_pkg
