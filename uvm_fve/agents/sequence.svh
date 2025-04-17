// This class represents UVM sequence base for DUT/DUV.
class timer_t_sequence extends uvm_sequence #(timer_t_transaction);

    // registration of object tools
    `uvm_object_utils( timer_t_sequence )

    // local shotimerut to transaction type
    typedef REQ seq_item_t;
    // member attributes, equivalent with interface ports
    rand logic                  default_RST;
    rand logic [ADDR_WIDTH-1:0] default_ADDRESS;
    rand logic [1:0]            default_REQUEST;
    rand logic [DATA_WIDTH-1:0] default_DATA_IN;

    // Constructor - creates new instance of this class
    function new( string name = "timer_t_sequence" );
        super.new( name );
    endfunction: new

    // create_and_finish_item - create single item, set default values and finish it
    protected task automatic create_and_finish_item();
        seq_item_t item;
        // create item using the factory
        item = seq_item_t::type_id::create( "item" );
        // blocks until the sequencer grants the sequence access to the driver
        start_item( item );
        // prepare item to be used (assign default data)
        item.RST     = default_RST;
        item.ADDRESS = default_ADDRESS;
        item.REQUEST = default_REQUEST;
        item.DATA_IN = default_DATA_IN;
        // block until the driver has completed its side of the transfer protocol
        finish_item( item );
    endtask: create_and_finish_item

    protected task automatic create_and_finish_EMPTY_item();
        seq_item_t item;
        // create item using the factory
        item = seq_item_t::type_id::create( "item" );
        // blocks until the sequencer grants the sequence access to the driver
        start_item( item );
        // prepare item to be used (assign default data)
        item.RST     = ~RST_ACT_LEVEL;
        item.ADDRESS = 0;
        item.REQUEST = 0;
        item.DATA_IN = 0;
        // block until the driver has completed its side of the transfer protocol
        finish_item( item );
    endtask: create_and_finish_EMPTY_item

endclass: timer_t_sequence

// This class represents UVM sequence reseting the DUT/DUV.
class timer_t_sequence_reset extends timer_t_sequence;

    // registration of object tools
    `uvm_object_utils( timer_t_sequence_reset )

    // Constructor - creates new instance of this class
    function new( string name = "timer_t_sequence_reset" );
        super.new( name );
    endfunction: new

    // body 
    task body();
        // set reset values, randomize() cannot be used here
        default_RST     = RST_ACT_LEVEL;
        default_ADDRESS = 0;
        default_REQUEST = 0;
        default_DATA_IN = 0;
        create_and_finish_item();
        create_and_finish_item();
    endtask: body
endclass: timer_t_sequence_reset


class timer_t_sequence_basic extends timer_t_sequence;

    // registration of object tools
    `uvm_object_utils( timer_t_sequence_basic )

    // Constructor - creates new instance of this class
    function new( string name = "timer_t_sequence_basic" );
        super.new( name );
    endfunction: new

    // body - implements behavior of the reset sequence (unidirectional)
    task body();
        default_RST = ~RST_ACT_LEVEL;

        //setting counter to 0
        default_ADDRESS = TIMER_CNT; // 8'h00
        default_REQUEST = CP_REQ_WRITE; // 2'b10
        default_DATA_IN = 32'b0;
        create_and_finish_item();

        //setting compare to 4
        default_ADDRESS = TIMER_CMP; // 8'h04
        default_REQUEST = CP_REQ_WRITE; // 2'b10
        default_DATA_IN = 32'b100;
        create_and_finish_item();

        //setting control to AUTO_RESTART
        default_ADDRESS = TIMER_CR; // 8'h08
        default_REQUEST = CP_REQ_WRITE; // 2'b10
        default_DATA_IN = 32'b01;
        create_and_finish_item();

        // just counting
        default_ADDRESS = 32'b0;
        default_REQUEST = 3'b0;
        default_DATA_IN = 32'b00;
        create_and_finish_item();
        create_and_finish_item();
        create_and_finish_item();
        create_and_finish_item();
        create_and_finish_item();
        create_and_finish_item();
        create_and_finish_item();
        create_and_finish_item();
        create_and_finish_item();
        create_and_finish_item();
        create_and_finish_item();
        create_and_finish_item();

    endtask: body

endclass: timer_t_sequence_basic


class timer_t_sequence_rand extends timer_t_sequence;
    /* INSERT YOUR CODE HERE */
    // registration of object tools
    `uvm_object_utils( timer_t_sequence_rand )

    // default constraints for each input interface port

    // Constructor - creates new instance of this class
	  function new( string name = "timer_t_sequence_rand" );
		    super.new( name );
	  endfunction: new

  	// body - implements behavior of the reset sequence (unidirectional)
  	task body();
  	  // initialize PRNG
  	  this.srandom( SEED );
  	  repeat ( TRANSACTION_COUNT ) begin
  	    if ( !this.randomize() ) begin
  	      `uvm_error( "body:", "Failed to randomize!" )
  	    end
  	    create_and_finish_item();
  	  end
  	endtask: body
endclass: timer_t_sequence_rand
