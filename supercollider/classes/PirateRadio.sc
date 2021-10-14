// top-level processor abstraction, defining all our sea-wolf functionality
// it doesn't depend on norns

PirateRadio {

	//---------------------
	//----- class variables
	//----- these are global - best used sparsely, as constants etc

	// the `<` tells SC to create a getter method
	// (it's useful to at least have getters for everything during development)
	classvar <numStreams;
	classvar <defaultFileLocation = "/home/we/dust/audio/pirates";

	//------------------------
	//----- instance variables
	//----- created for each new `PirateRadio` object

	// where all our loot is stashed
	var <fileLocation;
	// all the loots
	var <filePaths;
	var <filesPerStream;

	//--- busses
	// array of busses for streams
	var <streamBusses;
	// strength busese for output the strength of the stream
	var <strengthBusses;
	// a bus for noise
	var <noiseBus;
	// final output bus. effects can be performed on this bus in-place
	var <outputBus;
	// a control bus for the dial position
	var <dialBus;

	//--- child components
	var <streamPlayers;
	var noise;
	var dial;
	var selector;
	var effects;
	var saturator;

	//--- synths

	// final output synth
	var outputSynth;

	//--------------------
	//----- class methods
	var trigSkip=0;

	// most classes have a `*new` method
	*new {
		arg server, fileLocation;
		// this is a common pattern:
		// construct the superclass, then call our init function on it
		// (beware that the superclass cannot also have a method named `init`)
		^super.new.init(server, fileLocation);
	}


	//----------------------
	//----- instance methods

	// initialize a new `PirateRadio` object / allocate resources
	init {
		arg server, fileLocationPath;

		server.postln;

		numStreams=2;

		if (fileLocation.isNil, { fileLocation = fileLocationPath; });
		this.scanFiles;

		// create a file handler trigger
		// create a trigger function that handles when a synth is finished
		// and sends it its next file
		OSCFunc({ arg msg, time;
			var sndID=0, stationID=0, maxNum=0, startNum=0;
			[msg, time].postln;
			// WTF: for some reason the trigger is triggering twice!?
			if (trigSkip>0,{
				// station ID
				stationID=msg[2];
				// the stream player plays files indexed by [startNum, filesPerStream)
				startNum=stationID*filesPerStream;
				// next file number
				sndID=msg[3].asInteger+1;
				// if we are at the end of playlist, start over
				if (sndID>(filesPerStream+startNum-1),{
					sndID=startNum;
				});
				// tell it to play the next file
				streamPlayers[stationID].playFile(sndID,filePaths[sndID]);
			});
			// WTF: see above
			trigSkip=1-trigSkip;
		},'/tr', server.addr);


		//--------------------
		//-- create busses
		// audio buses are stereo

		// main audio bus for stream
		streamBusses = Array.fill(numStreams, {
			Bus.audio(server, 2);
		});

		noiseBus = Bus.audio(server, 2);

		outputBus = Bus.audio(server, 2);

		// control buses are mono

		// a bus to hold the dial
		dialBus = Bus.control(server,1);

		// each station outputs its own strength
		strengthBusses = Array.fill(numStreams, {
			Bus.control(server, 1);
		});


		//------------------
		//-- create synths and components

		// since we are routing audio through several Synths in series,
		// it's important to manage their order of execution.
		// here we do that in the simplest way:
		// each component places its synths at the end of the server's node list
		// so, the order of instantation is also the order of execution
		dial = PradDialController.new(server, dialBus);

		"creating stations".postln;
		streamPlayers = Array.fill(numStreams, { arg i;
			PradStreamPlayer.new(i, server, streamBusses[i], strengthBusses[i], dialBus);
		});

		"creating noise".postln;
		noise = PradNoise.new(server, noiseBus, dialBus);

		"creating selector".postln;
		selector = PradStreamSelector.new(server, streamBusses, strengthBusses, noiseBus, outputBus);

		// TODO: more addons...

		// "adding effects".postln;
		// effects = PradEffects.new(server, outputBus);

		// "adding saturator".postln;
		// saturator = PradStereoBitSaturator.new(server, server, outputBus);

		"creating output synth".postln;
		outputSynth = {
			arg in, out=0, threshold=0.99, lookahead=0.2;
			var snd;
			snd = In.ar(in, 2);
			snd = Limiter.ar(snd, threshold, lookahead).clip(-1, 1);
			Out.ar(0, snd);
		}.play(target:server, args:[\in, outputBus.index], addAction:\addToTail);

		// WTF: for whatever reason this won't work without a little delay
		// so I am playing the first file for each station stream in this Routine
		Routine {
			1.wait;
			"initializing stations".postln;
			streamPlayers.do({ arg syn, i;
				var sndID=filesPerStream*i;
				sndID.postln;
				filePaths[sndID].postln;
				streamPlayers[i].playFile(sndID,filePaths[sndID].asAbsolutePath);
			});
		}.play;
	}

	// refresh the list of sound files
	scanFiles {
		("scanning files in "++fileLocation).postln;
		filePaths = PathName.new(fileLocation).files;
		// calculate the new number of files per stream
		filesPerStream=((filePaths.size/numStreams).floor).asInteger;
		("will have "++filesPerStream++" files per stream").postln;
	}

	// set the dial position
	setDial {
		arg value;
		dial.setDial(value);
	}

	// setBand will set the band and bandwidth of station i
	setBand {
		arg i,band,bandwidth;
		streamPlayers[i].setBand(band,bandwidth);
	}

	// playFile interrupts a broadcast of staiton i to play that file
	playFile {
		arg i,fname;
		streamPlayers[i].playFile(-1,fname);
	}

	// set an effect parameter
	setFxParam {
		arg key, value;
		effects.setParam(key, value);
	}

	// stop and free resources
	free {
		// by default i tend to free stuff in reverse order of alloctaion
		outputSynth.free;

		effects.free;
		selector.free;
		noise.free;
		streamPlayers.do({ arg player; player.free; });

		outputBus.free;
		noiseBus.free;
		streamBusses.do({ arg bus; bus.free; });
		strengthBusses.do({ arg bus; bus.free; });
	}
}

//------------------------------------
//-- helper classes
//
// supercollier doesn't have namespaces unfortunately (probably in v4)
// so this is a common pattern: use a silly class-name prefix as a pseudo-namespace

PradDialController {
	// a simple controller that sets the global "dial"
	var <synth;

	*new {
		arg server, outBus;
		^super.new.init(server, outBus);
	}

	init {
		arg server, outBus;
		synth = {
			arg dial;
			Out.kr(outBus, Lag.kr(dial,0.1));
		}.play(target:server, addAction:\addToTail);
	}

	setDial {
		arg value;
		synth.set(\dial, value);
	}

	free {
		synth.free;
	}
}

PradStreamPlayer {
	// streaming buffer(s) and synth(s)..
	// TODO: future (probably want 2x of each, to cue/crossfade)
	var <id;
	var <buf;
	var <synth;
	var <band;
	var <bandwidth;
	var <server;
	var <outBus;
	var <outStrengthBus;
	var <inDialBus;
	var <currentSndID;

	*new {
		arg idArg, serverArg, outBusArg, outStrengthBusArg, inDialBusArg;
		^super.new.init(idArg, serverArg, outBusArg, outStrengthBusArg, inDialBusArg);
	}

	init {
		// (minor) WTF naming: wasn't sure whether I could have a class variable named the same thing as an arg
		arg idArg, serverArg, outBusArg, outStrengthBusArg, inDialBusArg;
		("initializing station "++idArg).postln;
		id=idArg;
		server=serverArg;
		outBus=outBusArg;
		outStrengthBus=outStrengthBusArg;
		inDialBus=inDialBusArg;
		// WTF: use a dummy synth so we can replace it thus keeping the order of buses intact
		synth = {
			Silent.ar(1);
		}.play(target:server, addAction:\addToTail);
	}

	playFile {
		arg sndid,fname;

		("station "++id++" playing sound "++sndid++ "("++fname.asAbsolutePath++")").postln;
		// without a snd identifier, then move on next time
		if (sndid<0,{
			sndid=currentSndID+1;
		},{
			currentSndID=sndid;
		});

		// close the current buffer and queue up the next one
		if (buf!=nil,{
			buf.close;
		});
		buf=Buffer.cueSoundFile(server,fname.absolutePath);

		// replace our current synth with the new one (preserves order)
		synth = {
			arg out=0,bufnum=0,synSndID=0,synID=0,ba=0,bw=1;
			var snd, strength, dial;

			bw=Clip.kr(bw,0.01,10);

			// dial is control by one
			dial = In.kr(inDialBus, 1);

			// strength emulates the "resonance" of a radio
			// strength is function of the dial position
			// and this stations band + bandwidth
			strength=exp(0.5.neg*(((dial-ba)/bw)**2).abs);

			// TODO: change the rate to match?
			snd = VDiskIn.ar(2, bufnum);
			SendTrig.kr(Done.kr(snd),id,sndid);

			Out.kr(outStrengthBus, strength);
			Out.ar(outBus,snd);
		}.play(target:synth,args:[\ba, band,\bw,bandwidth,\out,outBus.index,\bufnum,buf,\synSndID,id,\synID,sndid],addAction:\addReplace);
	}

	setBand {
		arg ba,bw;
		band=ba;
		bandwidth=bw;
		synth.set(\ba, band,\bw,bandwidth);
	}

	////////////////

	free {
		synth.free;
		buf.free;
		// synths.do({ arg synth; synth.free; });
		// bufs.do({ arg buf; buf.free; });
	}
}


// noise generator
PradNoise {
	var <synth;

	*new {
		arg server, outBus, dialBus;
		^super.new.init(server, outBus, dialBus);
	}

	init {
		arg server, outBus, dialBus;
		synth = {
			arg out;
			var snd, dial, moving;

			dial = In.kr(dialBus,1);
			moving = EnvGen.kr(Env.perc(0.1,1),Changed.kr(dial)+Dust.kr(0.1));

			///////////////
			//// radio static
			snd = BrownNoise.ar(0.2).dup + LPF.ar(Dust.ar(1), LinExp.kr(LFNoise2.kr(0.1),0,1,100, 4000));
			snd = snd + SinOsc.ar(LFNoise2.kr(LinExp.kr(LinLin.kr(LFNoise1.kr(0.5),0,1,50, 100),60,666)),mul:moving);
			snd = SelectX.ar(moving,[snd,snd.ring1(SinOsc.ar(LFNoise2.kr(LinExp.kr(LinLin.kr(LFNoise1.kr(0.5),0,1,1, 100),60,666))).dup)]);
			// commented because this is very very high pitched
			///// whoops, wants a `freq` arg - emb
			// snd = snd + HenonC.ar(a:LFNoise2.kr(0.2).linlin(-1,1,1.1,1.5).dup);
			//... or whatever
			////////////////

			// force everything down to stereo
			snd = Mix.new(snd.clump(2));

			Out.ar(out, snd);
		}.play(target:server, args:[\out, outBus.index], addAction:\addToTail);
	}

	setDial {
		arg value;
		synth.set(\dial, value);
	}

	free {
		synth.free;
	}
}


// effects processor
// applies effects to stereo bus
PradEffects {
	var synth;
	*new {
		arg server, bus;
		^super.new.init(server, bus);
	}

	init { arg server, bus;

		// also could define the SynthDef explicitly
		synth = {
			// ... whatever args
			arg bus, chorusRate=0.2, preGain=1.0;

			var signal;
			signal = In.ar(bus, 2);

			////////////////
			signal = DelayC.ar(signal, delaytime:LFNoise2.kr(chorusRate).linlin(-1,1, 0.01, 0.06));
			signal = Greyhole.ar(signal);
			signal = (signal*preGain).distort.distort;
			//... or whatever
			///////////

			// `ReplaceOut` overwrites the bus contents (unlike `Out` which mixes)
			// so this is how to do an "insert" processor
			ReplaceOut.ar(bus, signal);

		}.play(target:server, args:[\bus, bus.index], addAction:\addToTail);
	}



	free {
		synth.free;
	}
}


// this will be responsible for selecting / mixing all the streams / noise
PradStreamSelector {
	var <synth;

	*new {
		arg server, streamBusses, strengthBusses, noiseBus, outBus;
		^super.new.init(server, streamBusses, strengthBusses, noiseBus, outBus);
	}

	init { arg server, streamBusses, strengthBusses, noiseBus, outBus;
		var numStreams = streamBusses.size;

		// also could define the SynthDef explicitly
		synth = {
			arg out; // the selection parameter
			var streams, strengths, noise, mix, snd;
			strengths = strengthBusses.collect({ arg bus;
				In.kr(bus.index, 1)
			});
			streams = streamBusses.collect({ arg bus;
				In.ar(bus.index, 2)
			});

			noise = In.ar(noiseBus, 2);

			// weight sound by strength
			mix = Mix.new(streams.collect({ arg snd, i;
				snd * strengths[i]
			}));

			// noise is attenuated by inverse of total strength
			noise = (1-Clip.kr(Mix.new(strengths.collect({arg s; s}))))*noise;

			// mix the sound and noise
			snd = mix + noise;

			Out.ar(out, snd);
		}.play(target:server, args:[\out, outBus.index], addAction:\addToTail);
	}

	free {
		synth.free;
	}
}









////////////////////
////////////////////
/// little bonus...

PradStereoBitSaturator {
	classvar <compressCurve;
	classvar <expandCurve;

	var <compressBuf, <expandBuf, <synth;

	*initClass {
		var n, mu, unit;
		n = 512;
		mu = 255;
		unit = Array.fill(n, {|i| i.linlin(0, n-1, -1, 1) });
		compressCurve = unit.collect({ |x|
			x.sign * log(1 + mu * x.abs) / log(1 + mu);
		});
		expandCurve = unit.collect({ |y|
			y.sign / mu * ((1+mu)**(y.abs) - 1);
		});
	}

	*new {
		arg server, target, bus;
		^super.new.init(server, target, bus);
	}

	init {
		arg server, target, bus;

		compressBuf = Buffer.loadCollection(server, Signal.newFrom(compressCurve).asWavetableNoWrap);
		expandBuf = Buffer.loadCollection(server, Signal.newFrom(expandCurve).asWavetableNoWrap);

		synth = {
			arg steps = 256, compAmt=1, expAmt=1;
			var src, comp, x, crush, exp;
			src = In.ar(bus.index, 2);
			comp = Shaper.ar(compressBuf.bufnum, src);
			x = SelectX.ar(compAmt, [src, comp]);
			crush = (x.abs * steps).round * x.sign / steps;
			exp = Shaper.ar(expandBuf.bufnum, crush);
			ReplaceOut.ar(bus.index, SelectX.ar(expAmt, [crush, exp]));
		}.play(target:target, addAction:\addToTail);
	}

	setParam {
		arg key, value;
		synth.set(key, value);
	}

	free {
		synth.free;
		expandBuf.free;
		compressBuf.free;
	}
}
