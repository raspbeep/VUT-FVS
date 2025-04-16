//////////////////////////////////////////////////////////////////////////////
// Register definition
//////////////////////////////////////////////////////////////////////////////
class TIMER_CTRL_t extends uvm_reg;
  `uvm_object_utils(TIMER_CTRL_t)

  rand uvm_reg_field timer_mode;
  
  function new(input string name="TIMER_CTRL_t");
    super.new(name, 16, build_coverage(UVM_CVR_FIELD_VALS));
  endfunction : new

  virtual function void build();
    timer_mode = uvm_reg_field::type_id::create("timer_mode");
    
    /*
    function void configure(		uvm_reg 	parent,
                                int 	unsigned 	size,
                                int 	unsigned 	lsb_pos,
                                string 	access,
                                bit 	volatile,
                                uvm_reg_data_t 	reset,
                                bit 	has_reset,
                                bit 	is_rand,
                                bit 	individually_accessible	)*/

    timer_mode.configure(this, 2, 0, "RW", 0, 0, 0, 1, 1);
  endfunction

endclass : TIMER_CTRL_t

class TIMER_CNT_t extends uvm_reg;
  `uvm_object_utils(TIMER_CNT_t)

  rand uvm_reg_field timer_cnt_reg;
  
  function new(input string name="TIMER_CNT_t");
    super.new(name, 32, build_coverage(UVM_CVR_FIELD_VALS));
  endfunction : new

  virtual function void build();
    timer_cnt_reg = uvm_reg_field::type_id::create("timer_cnt_reg");
    
    /*
    function void configure(		uvm_reg 	parent,
                                int 	unsigned 	size,
                                int 	unsigned 	lsb_pos,
                                string 	access,
                                bit 	volatile,
                                uvm_reg_data_t 	reset,
                                bit 	has_reset,
                                bit 	is_rand,
                                bit 	individually_accessible	)*/

    timer_cnt_reg.configure(this, 4, 0, "RW", 0, 0, 0, 1, 1);
  endfunction

endclass : TIMER_CNT_t

//////////////////////////////////////////////////////////////////////////////
// Register block definition
//////////////////////////////////////////////////////////////////////////////
class timer_reg_block extends uvm_reg_block;
  `uvm_object_utils(timer_reg_block)

  rand TIMER_CTRL_t TIMER_CTRL;
  rand TIMER_CNT_t TIMER_CNT;
    
  function new(input string name="timer_reg_block");
    super.new(name, UVM_NO_COVERAGE);
  endfunction : new

  virtual function void build();
    // Now create all registers
    TIMER_CTRL = TIMER_CTRL_t::type_id::create("TIMER_CTRL", , get_full_name());
    TIMER_CNT = TIMER_CNT_t::type_id::create("TIMER_CNT", , get_full_name());
    
    // Now build the registers. Set parent and hdl_paths
    TIMER_CTRL.configure(this, null, "");
    TIMER_CTRL.build();

    TIMER_CNT.configure(this, null, "");
    TIMER_CNT.build();
    
    // Now define address mappings
    default_map = create_map("default_map", 0, 8, UVM_LITTLE_ENDIAN);
    default_map.add_reg(TIMER_CNT, `UVM_REG_ADDR_WIDTH'h0, "RW");
    default_map.add_reg(TIMER_CTRL, `UVM_REG_ADDR_WIDTH'h8, "RW");

  endfunction

endclass : timer_reg_block
 
