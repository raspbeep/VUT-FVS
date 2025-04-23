class random_timer_t_sequence extends uvm_sequence #(extended_timer_t_transaction);
    `uvm_object_utils( random_timer_t_sequence )

    // Constructor
    function new( string name = "random_timer_t_sequence" );
        super.new( name );
    endfunction: new
endclass: random_timer_t_sequence

class pseudo_random_seq extends random_timer_t_sequence;
    `uvm_object_utils( pseudo_random_seq )

    function new( string name = "pseudo_random_seq" );
        super.new( name );
        this.srandom( SEED );
    endfunction: new

    task body();
        REQ item;
        repeat ( TRANSACTION_COUNT ) begin
            item = extended_timer_t_transaction::type_id::create("item");

            start_item(item);

            if ( !item.randomize() ) begin
                `uvm_error( get_type_name(), "Failed to randomize transaction item!" )
            end else begin
                 `uvm_info(get_type_name(), $sformatf("Randomized item:\n%s", item.sprint()), UVM_HIGH)
            end

            finish_item(item);
        end
    endtask: body
endclass: pseudo_random_seq
