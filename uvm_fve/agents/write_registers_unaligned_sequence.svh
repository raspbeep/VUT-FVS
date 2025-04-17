// This class represents UVM sequence reseting the DUT/DUV.
class write_registers_unaligned_sequence_reset extends timer_t_sequence;

    // registration of object tools
    `uvm_object_utils( write_registers_sequence_reset )

    // Constructor - creates new instance of this class
    function new( string name = "write_registers_unaligned_sequence_reset" );
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
endclass: write_registers_unaligned_sequence_reset

class write_registers_unaligned_sequence_basic extends timer_t_sequence;

    // registration of object tools
    `uvm_object_utils( write_registers_unaligned_sequence_basic )

    // Constructor - creates new instance of this class
    function new( string name = "write_registers_unaligned_sequence_basic" );
        super.new( name );
    endfunction: new

    // body - implements behavior of the reset sequence (unidirectional)
    task body();
        default_RST = ~RST_ACT_LEVEL;

        default_ADDRESS = 32'h01;
        default_REQUEST = CP_REQ_WRITE;
        default_DATA_IN = TIMER_CR_DISABLED;
        create_and_finish_item();

        default_ADDRESS = 32'h03;
        create_and_finish_item();

        default_ADDRESS = 32'h05;
        create_and_finish_item();

        default_ADDRESS = 32'h07;
        create_and_finish_item();

        default_ADDRESS = 32'h09;
        create_and_finish_item();

        default_ADDRESS = 32'h0b;
        create_and_finish_item();

        default_ADDRESS = 32'h0d;
        create_and_finish_item();

        default_ADDRESS = 32'h0f;
        create_and_finish_item();

        default_ADDRESS = 32'h11;
        create_and_finish_item();

        default_ADDRESS = 32'h13;
        create_and_finish_item();

        default_ADDRESS = 32'h15;
        create_and_finish_item();

        default_ADDRESS = 32'h17;
        create_and_finish_item();

        default_ADDRESS = 32'hfff;
        create_and_finish_item();

        default_ADDRESS = 32'hffffff;
        create_and_finish_item();

        default_ADDRESS = 32'hffffffff;
        create_and_finish_item();

    endtask: body

endclass: write_registers_unaligned_sequence_basic
