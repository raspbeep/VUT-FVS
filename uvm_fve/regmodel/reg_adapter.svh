class reg_adapter extends uvm_reg_adapter;

  `uvm_object_utils(reg_adapter)

 /*
  * Extern/pure tasks and functions declarations
  */
  extern function new(string name = "reg_adapter");
  extern function uvm_sequence_item reg2bus(const ref uvm_reg_bus_op rw);
  extern function void bus2reg(uvm_sequence_item bus_item, ref uvm_reg_bus_op rw);
endclass : reg_adapter 

/**
 * Constructor - creates new instance of this class
 * @param name - instance name
 */
function reg_adapter::new(string name = "reg_adapter");
   super.new(name);
endfunction : new

/**
 * reg2bus - Creating bus transaction from register transaction.
 * @param rw - register transaction
 */
function uvm_sequence_item reg_adapter::reg2bus(const ref uvm_reg_bus_op rw);
  timer_t_transaction trans = timer_t_transaction::type_id::create("trans");
  trans.REQUEST = (rw.kind == UVM_READ) ? CP_REQ_READ : CP_REQ_WRITE;
  trans.ADDRESS = rw.addr;
  trans.DATA_IN = (rw.kind == UVM_WRITE) ? rw.data : 0;
  trans.DATA_OUT = (rw.kind == UVM_READ) ? rw.data : 0;
  
  `uvm_info(get_type_name(), $sformatf("reg2bus rw::kind: %s, addr: 0x%0h, data: 0x%0h, status: %s", rw.kind.name(), rw.addr, rw.data, rw.status), UVM_LOW)
  return trans;
endfunction : reg2bus

/**
 * reg2bus - Creating register transaction from bus transaction.
 * @param rw - register transaction
 * @param bus_item - bus transaction
 */
function void reg_adapter::bus2reg(uvm_sequence_item bus_item, ref uvm_reg_bus_op rw);
  timer_t_transaction trans;
  if (!$cast(trans, bus_item))
    `uvm_fatal(get_type_name(),"Provided bus_item is not of the correct type")
  else begin
     `uvm_info("bus2reg", trans.convert2string(), UVM_HIGH);
  end
  
  rw.kind = (trans.REQUEST == CP_REQ_WRITE) ? UVM_WRITE : UVM_READ;
  rw.addr = trans.ADDRESS;
  rw.data = trans.DATA_IN;
  rw.status = UVM_IS_OK;
  
  `uvm_info(get_type_name(), $sformatf("bus2reg rw::kind: %s, addr: 0x%0h, data: 0x%0h, status: %s", rw.kind.name(), rw.addr, rw.data, rw.status), UVM_LOW)
endfunction : bus2reg

