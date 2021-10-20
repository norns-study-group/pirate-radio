// a thin wrapper class exposing our stuff to norns
Engine_PirateRadio : CroneEngine {

	var radio;

	// norns system will call this when the engine is loaded
	alloc {

		// `context` is an inherited variable (a CroneAudioContext)
		var server =  context.server;

		radio = PirateRadio.new(server,3,"/home/we/dust/audio/tape");
		server.sync;

		// set band and bandwidth of station 0
		radio.setBand(0,94.7,0.5);
		// set band and bandwidth of station 1
		radio.setBand(1,98.6,0.5);
		// set band and bandwidth of station 2
		radio.setBand(2,81.6,0.8);
		// etc. how many stations?

		this.addCommand(\dial, "f", {
			arg msg;
			radio.setDial(msg[1]);
		});

		this.addCommand(\fxParam, "sf", {
			arg msg;
			radio.setFxParam(msg[1].asSymbol, msg[2]);
		});

		//... other commands...

		///.. polls?

	}

	// norns system calls this
	free {
		radio.free;
	}
}