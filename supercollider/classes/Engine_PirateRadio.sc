// a thin wrapper class exposing our stuff to norns
Engine_PirateRadio : CroneEngine {

	var radio;

	// norns system will call this when the engine is loaded
	alloc {

		// `context` is an inherited variable (a CroneAudioContext)
		var server =  context.server;
		var numStations = 0;

		this.addCommand(\new, "i", {
			arg msg;
			if (radio.notNil,{
				radio.free;
			});
			numStations=msg[1];
			radio = PirateRadio.new(server,numStations);
		});

		this.addCommand(\band, "iff", {
			arg msg;
			if (msg[1]<numStations,{
				if (radio.notNil,{
					radio.setBand(msg[1],msg[2],msg[3]);
				})
			})
		});

		this.addCommand(\dial, "f", {
			arg msg;
			if (radio.notNil,{
				radio.setDial(msg[1]);
			});
		});

		this.addCommand(\refresh, "", {
			arg msg;
			if (radio.notNil,{
				radio.refreshStations;
			});
		});

		this.addCommand(\addFile, "is", {
			arg msg;
			if (radio.notNil,{
				radio.addFile(msg[1],msg[2].asString);
			});
		});

		this.addCommand(\clearFiles, "i", {
			arg msg;
			if (radio.notNil,{
				radio.clearFiles(msg[1]);
			});
		});

		this.addCommand(\fxParam, "sf", {
			arg msg;
			if (radio.notNil,{
				radio.setFxParam(msg[1].asSymbol, msg[2]);
			});
		});

		this.addCommand(\getEngineState, "", {
			arg msg;
			if (radio.notNil,{
				radio.getEngineState();
			});
		});
		
		// i, playlistPosition, currentFilename, currentTime
		this.addCommand(\syncStation, "", {
			arg msg;
			if (radio.notNil,{
				radio.syncStation(msg[1],msg[2],msg[3],msg[4]);
			});
		});




		//... other commands...

		///.. polls?

	}

	// norns system calls this
	free {
		radio.free;
	}
}
