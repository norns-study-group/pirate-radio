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

	// most classes have a `*new` method
	*new {
		arg server, streamNum, fileLocation;
		// this is a common pattern:
		// construct the superclass, then call our init function on it
		// (beware that the superclass cannot also have a method named `init`)
		^super.new.init(server,streamNum, fileLocation);
	}


	//----------------------
	//----- instance methods

	// initialize a new `PirateRadio` object / allocate resources
	init {
		arg server, streamNum, fileLocationPath;

		server.postln;

		numStreams=streamNum;

		if (fileLocation.isNil, { fileLocation = fileLocationPath; });

		//--------------------
		//-- create busses
		// audio buses are stereo

		// main audio bus for stream
		streamBusses = Array.fill(numStreams, {
			Bus.audio(server, 2);
		});

		// noise for that radio-esque noise
		noiseBus = Bus.audio(server, 2);

		// output bus for holding the final sound
		// and transfering through various effects
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
		"creating dial".postln;
		dial = PradDialController.new(server, dialBus);

		"creating stations".postln;
		streamPlayers = Array.fill(numStreams, { arg i;
			PradStreamPlayer.new(i, server, streamBusses[i], strengthBusses[i], dialBus);
		});

		"updating stations with files".postln;
		this.scanFiles;

		"creating noise".postln;
		noise = PradNoise.new(server, noiseBus, dialBus);

		"creating selector".postln;
		selector = PradStreamSelector.new(server, streamBusses, strengthBusses, noiseBus, outputBus);

		// "adding effects".postln;
		// effects = PradEffects.new(server, outputBus);

		// "adding saturator".postln;
		// saturator = PradStereoBitSaturator.new(server, server, outputBus);

		// TODO: add 10-band equalizer at the end?

		"creating output synth".postln;
		outputSynth = {
			arg in, out=0, threshold=0.99, lookahead=0.2;
			var snd;
			snd = In.ar(in, 2);
			snd = Limiter.ar(snd, threshold, lookahead).clip(-1, 1);
			Out.ar(0, snd);
		}.play(target:server, args:[\in, outputBus.index], addAction:\addToTail);

		// for whatever reason this won't work without a little delay
		// so I am playing the first file for each station stream in this Routine
		Routine {
			1.wait;
			"starting stations playing".postln;
			streamPlayers.do({ arg syn, i;
				streamPlayers[i].playNextFile();
			});
		}.play;
	}

	// refresh the list of sound files
	scanFiles {
		("scanning files in "++fileLocation).postln;
		filePaths = PathName.new(fileLocation).files;

		// tell each station the available file paths and how many total
		// each station will determine which file path index to start and stop
		// based on its id. for example, the first station of N stations will
		// play files with index in [0,M files/N)
		(0..(numStreams-1)).do({ arg i;
			streamPlayers[i].setFilePaths(
				filePaths,
				(((filePaths.size-1)/numStreams).floor).asInteger
		)});
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

	// setNextFile queues up a particular file for a station
	setNextFile {
		arg i,fname;
		streamPlayers[i].setNextFile(fname);
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
	var <id;
	var <band;
	var <bandwidth;
	var <bufs;
	var <fnames;
	var <mp3s;
	var <synths;
	var <swap;
	var <server;
	var <outBus;
	var <outStrengthBus;
	var <inDialBus;
	var <currentSndID;
	var <crossfade;
	var <filePaths;
	var <fileIndexCurrent;
	var <fileIndexStart;
	var <fileIndexEnd;
	var <fileSpecial;

	*new {
		arg idArg, serverArg, outBusArg, outStrengthBusArg, inDialBusArg;
		^super.new.init(idArg, serverArg, outBusArg, outStrengthBusArg, inDialBusArg);
	}

	init {
		arg idArg, serverArg, outBusArg, outStrengthBusArg, inDialBusArg;
		("initializing station "++idArg).postln;
		id=idArg;
		server=serverArg;
		outBus=outBusArg;
		outStrengthBus=outStrengthBusArg;
		inDialBus=inDialBusArg;
		swap = 0;
		crossfade=1;
		fileIndexCurrent=(-1);
		synths=Array.newClear(2);
		bufs=Array.newClear(2);
		mp3s=Array.newClear(2);
		fnames=Array.newClear(2);
		//  use a dummy synth so we can replace it thus keeping the order of buses intact
		(0..1).do({
			arg i;
			("creating dummy "++i).postln;
			synths[i]={
				Silent.ar(1);
			}.play(target:server, addAction:\addToTail);
		});
	}


	playNextFile {
		var nextFile;
		if (fileSpecial.isNil,{
			fileIndexCurrent=fileIndexCurrent+1;
			if (fileIndexCurrent<fileIndexStart,{
				fileIndexCurrent=fileIndexStart;
			});
			if (fileIndexCurrent>(fileIndexEnd-1),{
				fileIndexCurrent=fileIndexStart;
			});
			if (filePaths[fileIndexCurrent]==nil,{
				fileIndexCurrent=fileIndexStart;
			});
			nextFile=filePaths[fileIndexCurrent];
		},{
			nextFile=fileSpecial;
			fileSpecial=nil;
		});
		// tell it to play the next file
		this.playFile(nextFile);
	}

	playFile {
		arg fname;
		var p,l;
		var durationSeconds=1;
		var xfade=0;

		// swap synths/buffers
		swap=1-swap;
		("station "++id++" playing file "++fname.asAbsolutePath).postln;
		fnames[swap]=(fname.asAbsolutePath).asString;
		fnames[swap].postln;

		// get sound file duration
		p = Pipe.new("ffprobe -i '"++fname.asAbsolutePath++"' -show_format -v quiet | sed -n 's/duration=//p'", "r");            // list directory contents in long format
		l = p.getLine;                    // get the first line
		p.close;                    // close the pipe to avoid that nasty buildup
		l.postln;

		// for whatever reason, if file is corrupted then skip it
		if (l.isNil,{},{
			durationSeconds=l.asFloat;
			// if the file length is less than crossfade, reconfigure xfade
			xfade=crossfade;
			if (xfade>(durationSeconds/3),{
				xfade=durationSeconds/3;
			});

			// close the current buffer and queue up the next one
			if (bufs[swap]!=nil,{
				bufs[swap].close;
				if (fnames[swap].endsWith(".ogg")==true||fnames[swap].endsWith(".mp3")==true,{
					mp3s[swap].free;
					mp3s[swap].finish;
				});
			});
			if (fnames[swap].endsWith(".ogg")==true||fnames[swap].endsWith(".mp3")==true,{
				mp3s[swap]=MP3(fname.absolutePath);
				mp3s[swap].start;
				bufs[swap]=Buffer.cueSoundFile(server,mp3s[swap].fifo);
			},{
				bufs[swap]=Buffer.cueSoundFile(server,fname.absolutePath);
			});

			// replace our current synth with the new one (preserves order)
			synths[swap] = {
				arg out=0,bufnum=0,ba=0,bw=1,xfade=1,duration=1;
				var snd, strength, dial,env;

				env=EnvGen.ar(Env.new([0,1,1,0],[xfade,duration-xfade-xfade,xfade]));

				bw=Clip.kr(bw,0.01,10);

				// dial is control by one
				dial = In.kr(inDialBus, 1);

				// strength emulates the "resonance" of a radio
				// strength is function of the dial position
				// and this stations band + bandwidth
				strength=exp(0.5.neg*(((dial-ba)/bw)**1).abs);
				// random bursts of lost strength
				strength=Clip.kr(strength-
					EnvGen.kr(Env.perc(
						TExpRand.kr(0.1,2,Impulse.kr(0.5)),
						TExpRand.kr(0.1,2,Impulse.kr(0.5)),
						TExpRand.kr(0.2,1,Impulse.kr(0.5)),
						[4,-4]),Dust.kr(1-strength+0.01))
				);
				// remove the long tail
				// set the strength to zero at bandwidth*3
				strength=Select.kr((dial-ba).abs>(3*bw),[strength,0]);

				// TODO: change the rate to match?
				snd = VDiskIn.ar(2, bufnum);

				// send strength through control bus
				Out.kr(outStrengthBus, strength);

				// send crossfaded sound through sound bus
				Out.ar(outBus,snd*env);
			}.play(target:synths[swap],args:[
				\ba, band,\bw,bandwidth,
				\xfade,xfade,\duration,durationSeconds,
				\out,outBus.index,\bufnum,bufs[swap]],addAction:\addReplace);

		});
		// start a clock to queue the next file (before current is done)
		SystemClock.sched(durationSeconds-xfade, {
			this.playNextFile;
			nil
		});
	}


	setBand {
		arg ba,bw;
		band=ba;
		bandwidth=bw;
		synths.do({ arg synth; synth.set(\ba, band,\bw,bandwidth); });
	}

	// setFilePaths will configure the indicies allowed to play through
	setFilePaths {
		arg fps,tfiles;
		var totalFiles;
		filePaths=fps;
		totalFiles=tfiles;
		fileIndexStart=id*totalFiles;
		fileIndexEnd=fileIndexStart+((id+1)*totalFiles);
	}

	// setNextFile will override the playlist and queue up specified file next
	setNextFile {
		arg fname;
		fileSpecial=fname;
	}

	////////////////

	free {
		synths.do({ arg synth; synth.free; });
		bufs.do({ arg buf; buf.free; });
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
			snd = BrownNoise.ar(0.1).dup + LPF.ar(Dust.ar(1), LinExp.kr(LFNoise2.kr(0.1),0,1,100, 4000));
			snd = snd + SinOsc.ar(LFNoise2.kr(LinExp.kr(LinLin.kr(LFNoise1.kr(0.5),0,1,50, 100),60,666)),mul:moving);
			snd = SelectX.ar(moving,[snd,snd.ring1(SinOsc.ar(LFNoise2.kr(LinExp.kr(LinLin.kr(LFNoise1.kr(0.5),0,1,1, 100),60,666))).dup)]);
			// commented because this is very very high pitched
			///// whoops, wants a `freq` arg - emb
			snd = snd + HenonC.ar(SinOsc.kr(0.1).range(900,1250),a:LFNoise2.kr(0.2).linlin(-1,1,1.1,1.5).dup,mul:0.05);
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
			arg bus, chorusRate=0.2, preGain=1.0,
			band1,band2,band3,band4,band5,band6,band7,band8,band9,band10;

			var snd;
			snd = In.ar(bus, 2);

			// 10-band equalizer
			snd = BPeakEQ.ar(snd,60,db:band1);
			snd = BPeakEQ.ar(snd,170,db:band2);
			snd = BPeakEQ.ar(snd,310,db:band3);
			snd = BPeakEQ.ar(snd,600,db:band4);
			snd = BPeakEQ.ar(snd,1000,db:band5);
			snd = BPeakEQ.ar(snd,3000,db:band6);
			snd = BPeakEQ.ar(snd,6000,db:band7);
			snd = BPeakEQ.ar(snd,12000,db:band8);
			snd = BPeakEQ.ar(snd,14000,db:band9);
			snd = BPeakEQ.ar(snd,16000,db:band10);

			////////////////
			snd = DelayC.ar(snd, delaytime:LFNoise2.kr(chorusRate).linlin(-1,1, 0.01, 0.06));
			snd = Greyhole.ar(snd);
			snd = (snd*preGain).distort.distort;
			//... or whatever
			///////////

			// `ReplaceOut` overwrites the bus contents (unlike `Out` which mixes)
			// so this is how to do an "insert" processor
			ReplaceOut.ar(bus, snd);

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
			var streams, strengths, noise, mix, snd, totalstrength;
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
			totalstrength=Clip.kr(Mix.new(strengths.collect({arg s; s})));

			// lose frames based on the strength
			mix=WaveLoss.ar(mix,LinLin.kr(totalstrength,0,1,70,0),100,2);

			// incorporate the noise based on strength
			noise = (1-totalstrength)*noise;

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
