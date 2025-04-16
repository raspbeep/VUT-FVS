class pseudo_random_seq extends timer_t_sequence;
    // registration of object tools
    `uvm_object_utils( pseudo_random_seq )

    // default constraints for each input interface port

    // Constructor - creates new instance of this class
	  function new( string name = "pseudo_random_seq" );
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
endclass: pseudo_random_seq
