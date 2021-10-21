// a thin wrapper class exposing our stuff to norns
Engine_PirateRadio : CroneEngine {

	var radio;

	// norns system will call this when the engine is loaded
	alloc {

		// `context` is an inherited variable (a CroneAudioContext)
		var server =  context.server;

		var numStations=3;
		var numLoopingStations=1;

		// start a radio 
		radio = PirateRadio.new(server,numStations,numLoopingStations,"/home/we/dust/audio/tape");
		server.sync;

		// the first <numLoopingStations> are looping stations
		// set band and bandwidth of station 0
		// station 0 is used as the weather station in `weather.lua`
		radio.setBand(0,94.7,0.5);
		radio.setNextFile(0,"/home/we/dust/code/pirate-radio/lib/data/weather.flac");

		// all other stations automatically go through the playlist
		// set band and bandwidth of station 1
		radio.setBand(1,98.6,0.5);

		// set band and bandwidth of station 2
		radio.setBand(2,81.6,0.8);
		radio.setBand(3,86.0,0.5);

		// etc. how many stations?

		this.addCommand(\dial, "f", {
			arg msg;
			radio.setDial(msg[1]);
		});

		this.addCommand(\refresh, "s", {
			arg msg;
			radio.refreshStations(msg[1].asString);
		});

		this.addCommand(\setNextFile, "is", {
			arg msg;
			radio.setNextFile(msg[1],msg[2]);
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
