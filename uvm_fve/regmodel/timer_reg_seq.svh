class timer_reg_seq extends uvm_reg_sequence;
  `uvm_object_utils(timer_reg_seq)

  /*
   * Class properties
   */
  
   // RAL, status, data
  timer_reg_block m_timer_reg_block; 
  uvm_reg_data_t value;
  uvm_status_e   status;

  /*
   * Class item methods
   */
  extern function new(string name = "timer_reg_seq");
  extern virtual task body();
  extern task timer_set_mode(bit [1:0] mode);
  extern task timer_set_cnt(bit [31:0] cnt);
  extern function void check_status();
endclass : timer_reg_seq

/*
 * Constructor for timer_reg_seq
 * @param name - instance name
 */
function timer_reg_seq::new(string name = "timer_reg_seq");
  super.new(name);
endfunction : new

/*
 * Main body task
 */
task timer_reg_seq::body();
  timer_set_mode(2'b01);

  timer_set_cnt(32'h000000FF);
endtask : body

/* 
 * timer_set_mode - Setting mode for timer
 * @param nvm_wr_en - enabling bit
 */
task timer_reg_seq::timer_set_mode(bit [1:0] mode);
  m_timer_reg_block.TIMER_CTRL.write(status, mode);
  check_status();
endtask : timer_set_mode

task timer_reg_seq::timer_set_cnt(bit [31:0] cnt);
  m_timer_reg_block.TIMER_CNT.write(status, cnt);
  check_status();
endtask : timer_set_cnt

/*
 * check_status - checking status of RAL operations
 */
function void timer_reg_seq::check_status();
  if (status == UVM_NOT_OK)
    `uvm_fatal(get_type_name(), "RAL access status returned UVM_NOT_OK.")
endfunction: check_status
