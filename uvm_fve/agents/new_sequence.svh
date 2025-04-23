// This class represents UVM sequence reseting the DUT/DUV.
class new_timer_t_sequence_reset extends timer_t_sequence;

    // registration of object tools
    `uvm_object_utils( new_timer_t_sequence_reset )

    // Constructor - creates new instance of this class
    function new( string name = "new_timer_t_sequence_reset" );
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
endclass: new_timer_t_sequence_reset

class new_timer_t_sequence_basic extends timer_t_sequence;

    // registration of object tools
    `uvm_object_utils( new_timer_t_sequence_basic )

    // Constructor - creates new instance of this class
    function new( string name = "new_timer_t_sequence_basic" );
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
        default_DATA_IN = TIMER_CR_AUTO_RESTART;
        create_and_finish_item();

        // just counting
        default_ADDRESS = 32'b0;
        default_REQUEST = 3'b0;
        default_DATA_IN = 32'b00;
        create_and_finish_item();
        create_and_finish_item();
        create_and_finish_item();
        create_and_finish_item();

        // reset
        default_RST     = RST_ACT_LEVEL;
        default_ADDRESS = 0;
        default_REQUEST = 0;
        default_DATA_IN = 0;
        create_and_finish_item();
        default_RST = ~RST_ACT_LEVEL;
        create_and_finish_item();

        //setting control to ONE_SHOT
        default_ADDRESS = TIMER_CR; // 8'h08
        default_REQUEST = CP_REQ_WRITE; // 2'b10
        default_DATA_IN = TIMER_CR_ONESHOT;
        create_and_finish_item();

        // just counting
        default_ADDRESS = 32'b0;
        default_REQUEST = 3'b0;
        default_DATA_IN = 32'b00;
        create_and_finish_item();
        create_and_finish_item();
        create_and_finish_item();
        create_and_finish_item();

        // reset
        default_RST     = RST_ACT_LEVEL;
        default_ADDRESS = 0;
        default_REQUEST = 0;
        default_DATA_IN = 0;
        create_and_finish_item();
        default_RST = ~RST_ACT_LEVEL;
        create_and_finish_item();

        //setting control to ONE_SHOT
        default_ADDRESS = TIMER_CR; // 8'h08
        default_REQUEST = CP_REQ_WRITE; // 2'b10
        default_DATA_IN = TIMER_CR_CONTINUOUS;
        create_and_finish_item();

        // just counting
        default_ADDRESS = 32'b0;
        default_REQUEST = 3'b0;
        default_DATA_IN = 32'b00;
        create_and_finish_item();
        create_and_finish_item();
        create_and_finish_item();
        create_and_finish_item();

        default_ADDRESS = 32'h17;
        default_REQUEST = CP_REQ_WRITE;
        default_DATA_IN = TIMER_CR_CONTINUOUS;
        create_and_finish_item();
        create_and_finish_EMPTY_item();
        create_and_finish_EMPTY_item();
        create_and_finish_EMPTY_item();
        create_and_finish_EMPTY_item();

        default_ADDRESS = TIMER_CR;
        default_REQUEST = CP_REQ_WRITE;
        default_DATA_IN = TIMER_CR_CONTINUOUS;
        create_and_finish_item();

        default_ADDRESS = TIMER_CR;
        default_REQUEST = CP_REQ_READ;
        default_DATA_IN = 0;
        create_and_finish_item();

        create_and_finish_EMPTY_item();
        create_and_finish_EMPTY_item();
        create_and_finish_EMPTY_item();
    endtask: body

endclass: new_timer_t_sequence_basic


class random1_timer_t_sequence extends uvm_sequence #(extended1_timer_t_transaction);
    `uvm_object_utils( random1_timer_t_sequence )

    // Constructor
    function new( string name = "random1_timer_t_sequence" );
        super.new( name );
    endfunction: new
endclass: random1_timer_t_sequence

// class new_timer_t_sequence_rand extends timer_t_sequence;
//     // registration of object tools
//     `uvm_object_utils( new_timer_t_sequence_rand )

//     // default constraints for each input interface port

//     // Constructor - creates new instance of this class
// 	  function new( string name = "new_timer_t_sequence_rand" );
// 		    super.new( name );
// 	  endfunction: new

//   	// body - implements behavior of the reset sequence (unidirectional)
//   	task body();
//   	  // initialize PRNG
//   	  this.srandom( SEED );
//   	  repeat ( TRANSACTION_COUNT1 ) begin
//         extended1_timer_t_transaction ext_txn;
//         ext_txn = extended1_timer_t_transaction::type_id::create("ext_txn");
//   	    if ( !this.randomize() ) begin
//   	      `uvm_error( "body:", "Failed to randomize!" )
//   	    end
//   	    create_and_finish_item();
//   	  end
//   	endtask: body
// endclass: new_timer_t_sequence_rand

class new_timer_t_sequence_rand extends random1_timer_t_sequence;
    `uvm_object_utils( new_timer_t_sequence_rand )

    function new( string name = "new_timer_t_sequence_rand" );
        super.new( name );
        this.srandom( SEED );
    endfunction: new

    task body();
        REQ item;
        repeat ( TRANSACTION_COUNT1 ) begin
            item = extended1_timer_t_transaction::type_id::create("item");

            start_item(item);

            if ( !item.randomize() ) begin
                `uvm_error( get_type_name(), "Failed to randomize transaction item!" )
            end else begin
                 `uvm_info(get_type_name(), $sformatf("Randomized item:\n%s", item.sprint()), UVM_HIGH)
            end

            finish_item(item);
        end
    endtask: body
endclass: new_timer_t_sequence_rand
