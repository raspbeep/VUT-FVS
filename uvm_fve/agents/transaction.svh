// This class represents transaction which contains values of output signals for 'timer'.
class timer_t_transaction extends uvm_sequence_item;

    // registration of object tools
    `uvm_object_utils( timer_t_transaction )

    // Member attributes, equivalent with interface pins
    // make input attributes random, except for clocks
    rand logic                  RST;
    rand logic [ADDR_WIDTH-1:0] ADDRESS;
    rand logic [1:0]            REQUEST;
    rand logic [DATA_WIDTH-1:0] DATA_IN;

    logic                       P_IRQ;
    logic [2:0]                 RESPONSE;
    logic [DATA_WIDTH-1:0]      DATA_OUT;

    // Constructor - creates new instance of this class
    function new( string name = "timer_t_transaction" );
        super.new( name );
    endfunction: new

    // common UVM functions

    // Properly copy all transaction attributes.
    function void do_copy( uvm_object rhs );
        timer_t_transaction rhs_;

        if( !$cast(rhs_, rhs) ) begin
            `uvm_fatal( "do_copy:", "Failed to cast transaction object." )
            return;
        end
        // now copy all attributes
        super.do_copy( rhs );
        RST = rhs_.RST;
        P_IRQ = rhs_.P_IRQ;
        ADDRESS = rhs_.ADDRESS;
        REQUEST = rhs_.REQUEST;
        RESPONSE = rhs_.RESPONSE;
        DATA_OUT = rhs_.DATA_OUT;
        DATA_IN = rhs_.DATA_IN;
    endfunction: do_copy

    // Properly compare all transaction attributes representing output pins.
    function bit do_compare( uvm_object rhs, uvm_comparer comparer );
        timer_t_transaction rhs_;

        if( !$cast(rhs_, rhs) ) begin
            `uvm_error( "do_compare:", "Failed to cast transaction object." )
            return 0;
        end

        // using simple equivalence operator (faster)
        return ( super.do_compare(rhs, comparer) &&
            (P_IRQ == rhs_.P_IRQ) &&
            (RESPONSE == rhs_.RESPONSE) &&
            (DATA_OUT == rhs_.DATA_OUT) );
    endfunction: do_compare

    // Convert transaction into human readable form.
    function string convert2string();
        string s;
        s = $sformatf( "%s\n\tRST: 'h%0h\n\tP_IRQ: 'h%0h\n\tADDRESS: 'h%0h\n\tREQUEST: 'h%0h\n\tRESPONSE: 'h%0h\n\tDATA_OUT: 'h%0h\n\tDATA_IN: 'h%0h",
            super.convert2string(),
            RST,
            P_IRQ,
            ADDRESS,
            REQUEST,
            RESPONSE,
            DATA_OUT,
            DATA_IN );
        return s;
    endfunction: convert2string

    // Customize what gets printed or sprinted, use the uvm_printer policy classes.
    function void do_print( uvm_printer printer );
        super.do_print( printer );
        if ( printer != null ) begin
            printer.print_int( "RST", RST, $bits(RST) );
            printer.print_int( "REQUEST", REQUEST, $bits(REQUEST) );
            printer.print_int( "ADDRESS", ADDRESS, $bits(ADDRESS) );
            printer.print_int( "DATA_IN", DATA_IN, $bits(DATA_IN) );
            printer.print_int( "RESPONSE", RESPONSE, $bits(RESPONSE) );
            printer.print_int( "DATA_OUT", DATA_OUT, $bits(DATA_OUT) );
            printer.print_int( "P_IRQ", P_IRQ, $bits(P_IRQ) );
        end
    endfunction: do_print

    // Support the viewing of data objects as transactions in a waveform GUI.
    function void do_record( uvm_recorder recorder );
        super.do_record( recorder );
        `uvm_record_field( "RST", RST )
        `uvm_record_field( "P_IRQ", P_IRQ )
        `uvm_record_field( "ADDRESS", ADDRESS )
        `uvm_record_field( "REQUEST", REQUEST )
        `uvm_record_field( "RESPONSE", RESPONSE )
        `uvm_record_field( "DATA_OUT", DATA_OUT )
        `uvm_record_field( "DATA_IN", DATA_IN )
    endfunction: do_record

endclass: timer_t_transaction

// Extended transaction class
class extended_timer_t_transaction extends timer_t_transaction;

    `uvm_object_utils(extended_timer_t_transaction)

    // New random variable
    rand logic enable;

    // New variable for burst length
    rand int burst_length;

    // Constructor
    function new(string name = "extended_timer_t_transaction");
        super.new(name);
    endfunction : new

    
    constraint valid_burst_length {
        burst_length inside {[1:16]}
    }

    constraint address_alignment {
        ADDRESS[0] == 0;
    }

    constraint enable_implication {
        enable -> REQUEST != 0;
    }

    constraint valid_request {
        REQUEST inside {[1:3]};
    }

    function void do_copy(uvm_object rhs);
        extended_timer_t_transaction rhs_;
        if (!$cast(rhs_, rhs)) begin
        `uvm_fatal("do_copy:", "Failed to cast transaction object.")
        return;
        end
        super.do_copy(rhs);
        enable = rhs_.enable;
        burst_length = rhs_.burst_length;
    endfunction : do_copy

    function string convert2string();
        string s;
        s = $sformatf( "%s\n\tRST: 'h%0h\n\tP_IRQ: 'h%0h\n\tADDRESS: 'h%0h\n\tREQUEST: 'h%0h\n\tRESPONSE: 'h%0h\n\tDATA_OUT: 'h%0h\n\tDATA_IN: 'h%0h",
            super.convert2string(),
            RST,
            P_IRQ,
            ADDRESS,
            REQUEST,
            RESPONSE,
            DATA_OUT,
            DATA_IN );
        return s;
    endfunction: convert2string

    function void do_print(uvm_printer printer);
        super.do_print(printer);
        if ( printer != null ) begin
            printer.print_int( "RST", RST, $bits(RST) );
            printer.print_int( "REQUEST", REQUEST, $bits(REQUEST) );
            printer.print_int( "ADDRESS", ADDRESS, $bits(ADDRESS) );
            printer.print_int( "DATA_IN", DATA_IN, $bits(DATA_IN) );
            printer.print_int( "RESPONSE", RESPONSE, $bits(RESPONSE) );
            printer.print_int( "DATA_OUT", DATA_OUT, $bits(DATA_OUT) );
            printer.print_int( "P_IRQ", P_IRQ, $bits(P_IRQ) );
        end
    endfunction : do_print

    // Override the do_record function to include the new variables
    function void do_record( uvm_recorder recorder );
        super.do_record( recorder );
        `uvm_record_field( "RST", RST )
        `uvm_record_field( "P_IRQ", P_IRQ )
        `uvm_record_field( "ADDRESS", ADDRESS )
        `uvm_record_field( "REQUEST", REQUEST )
        `uvm_record_field( "RESPONSE", RESPONSE )
        `uvm_record_field( "DATA_OUT", DATA_OUT )
        `uvm_record_field( "DATA_IN", DATA_IN )
    endfunction: do_record

endclass : extended_timer_t_transaction
