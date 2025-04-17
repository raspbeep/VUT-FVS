// This class represents UVM sequence reseting the DUT/DUV.
class write_registers_sequence_reset extends timer_t_sequence;

    // registration of object tools
    `uvm_object_utils( write_registers_sequence_reset )

    // Constructor - creates new instance of this class
    function new( string name = "write_registers_sequence_reset" );
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
endclass: write_registers_sequence_reset

class write_registers_sequence_basic extends timer_t_sequence;

    // registration of object tools
    `uvm_object_utils( write_registers_sequence_basic )

    // Constructor - creates new instance of this class
    function new( string name = "write_registers_sequence_basic" );
        super.new( name );
    endfunction: new

    // body - implements behavior of the reset sequence (unidirectional)
    task body();
        default_RST = ~RST_ACT_LEVEL;

        // setting control register DISABLED
        default_ADDRESS = TIMER_CR; // 8'h08
        default_REQUEST = CP_REQ_WRITE; // 2'b10
        default_DATA_IN = TIMER_CR_DISABLED;
        create_and_finish_item();

        // setting control register to AUTO_RESTART
        default_ADDRESS = TIMER_CR; // 8'h08
        default_REQUEST = CP_REQ_WRITE; // 2'b10
        default_DATA_IN = TIMER_CR_AUTO_RESTART;
        create_and_finish_item();

        // setting control register to ONESHOT
        default_ADDRESS = TIMER_CR; // 8'h08
        default_REQUEST = CP_REQ_WRITE; // 2'b10
        default_DATA_IN = TIMER_CR_ONESHOT;
        create_and_finish_item();

        // setting control register to CONTINUOUS
        default_ADDRESS = TIMER_CR; // 8'h08
        default_REQUEST = CP_REQ_WRITE; // 2'b10
        default_DATA_IN = TIMER_CR_CONTINUOUS;
        create_and_finish_item();

        ///////////////////////////////////////////

        // write to cnt
        default_ADDRESS = TIMER_CNT; // 8'h00
        default_REQUEST = CP_REQ_WRITE; // 2'b10
        default_DATA_IN = 32'b0;
        create_and_finish_item();

        // write to cnt
        default_ADDRESS = TIMER_CNT; // 8'h00
        default_REQUEST = CP_REQ_WRITE; // 2'b10
        default_DATA_IN = 32'b1;
        create_and_finish_item();

        // write to cnt
        default_ADDRESS = TIMER_CNT; // 8'h00
        default_REQUEST = CP_REQ_WRITE; // 2'b10
        default_DATA_IN = 32'b11111111111111111111111111111111;
        create_and_finish_item();

        // wait for overflow
        create_and_finish_EMPTY_item();

        ///////////////////////////////////////////

        // write to cmp
        default_ADDRESS = TIMER_CMP; // 8'h04
        default_REQUEST = CP_REQ_WRITE; // 2'b10
        default_DATA_IN = 32'b0;
        create_and_finish_item();

        // write to cmp
        default_ADDRESS = TIMER_CMP; // 8'h04
        default_REQUEST = CP_REQ_WRITE; // 2'b10
        default_DATA_IN = 32'b1;
        create_and_finish_item();

        // write to cmp
        default_ADDRESS = TIMER_CMP; // 8'h04
        default_REQUEST = CP_REQ_WRITE; // 2'b10
        default_DATA_IN = 32'b11111111111111111111111111111111;
        create_and_finish_item();

        ///////////////////////////////////////////

        // write to cmp
        default_ADDRESS = TIMER_CMP; // 8'h00
        default_REQUEST = CP_REQ_WRITE; // 2'b10
        default_DATA_IN = 32'b11111111111111111111111111111111;
        create_and_finish_item();

        // write to cnt
        default_ADDRESS = TIMER_CNT; // 8'h00
        default_REQUEST = CP_REQ_WRITE; // 2'b10
        default_DATA_IN = 32'b11111111111111111111111111111111;
        create_and_finish_item();

        // wait for irq and 
        create_and_finish_EMPTY_item();

        ///////////////////////////////////////////
        // write to cycle_l, cycle_h should have no effect, just acknowledge
        
        // write to cycle_l
        default_ADDRESS = TIMER_CYCLE_L; // 8'h00
        default_REQUEST = CP_REQ_WRITE; // 2'b10
        default_DATA_IN = 42;
        create_and_finish_item();

        // write to cycle_h
        default_ADDRESS = TIMER_CYCLE_H; // 8'h00
        default_REQUEST = CP_REQ_WRITE; // 2'b10
        default_DATA_IN = 42;
        create_and_finish_item();

        ///////////////////////////////////////////
        // read from all registers
        default_ADDRESS = TIMER_CR;
        default_REQUEST = CP_REQ_READ;
        default_DATA_IN = 0;
        create_and_finish_item();

        default_ADDRESS = TIMER_CNT;
        default_REQUEST = CP_REQ_READ;
        default_DATA_IN = 0;
        create_and_finish_item();

        default_ADDRESS = TIMER_CMP;
        default_REQUEST = CP_REQ_READ;
        default_DATA_IN = 0;
        create_and_finish_item();

        default_ADDRESS = TIMER_CYCLE_L;
        default_REQUEST = CP_REQ_READ;
        default_DATA_IN = 0;
        create_and_finish_item();

        default_ADDRESS = TIMER_CYCLE_H;
        default_REQUEST = CP_REQ_READ;
        default_DATA_IN = 0;
        create_and_finish_item();

        default_ADDRESS = TIMER_CMP;
        default_REQUEST = CP_REQ_WRITE;
        default_DATA_IN = 0;
        create_and_finish_item();

        default_ADDRESS = TIMER_CNT;
        default_REQUEST = CP_REQ_WRITE;
        default_DATA_IN = 32'hfffffffe;
        create_and_finish_item();
        
        create_and_finish_EMPTY_item();
        create_and_finish_EMPTY_item();
        create_and_finish_EMPTY_item();
        create_and_finish_EMPTY_item();
    endtask: body

endclass: write_registers_sequence_basic
