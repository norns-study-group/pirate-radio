// a thin wrapper class exposing our stuff to norns
Engine_PirateRadio : CroneEngine {

	var radio;

	// norns system will call this when the engine is loaded
	alloc {

		// `context` is an inherited variable (a CroneAudioContext)
		var server =  context.server;

		radio = PirateRadio.new(server);

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