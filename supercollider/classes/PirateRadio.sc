// top-level processor abstraction, defining all our sea-wolf functionality
// it doesn't depend on norns

PirateRadio {

	//---------------------
	//----- class variables
	//----- these are global - best used sparsely, as constants etc

	// the `<` tells SC to create a getter method
	// (it's useful to at least have getters for everything during development)
	classvar <numStreams;

	//------------------------
	//----- instance variables
	//----- created for each new `PirateRadio` object

	//--- toggles
	var <spectrumSendFreq;

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
	// a control bus for the total strength
	var <totalStrengthBus;
	// a control bus for the spectrum analyzer
	var <spectrumAnalysisBus;


	//--- child components
	var <streamPlayers;
	var noise;
	var dial;
	var selector;
	var effects;
	var saturator;
	var sendRoutine;
	//--- synths

	// final output synth
	var outputSynth;

	//--- osc function
	var oscTrigger;

	//--------------------
	//----- class methods

	// most classes have a `*new` method
	*new {
		arg server, streamNum;
		// this is a common pattern:
		// construct the superclass, then call our init function on it
		// (beware that the superclass cannot also have a method named `init`)
		^super.new.init(server, streamNum);
	}


	//----------------------
	//----- instance methods

	// initialize a new `PirateRadio` object / allocate resources
	init {
		arg server, streamNum;

		server.postln;
		streamNum.postln;

		numStreams=streamNum;

		//--------------------
		//-- create osc trigger
		if (oscTrigger.notNil,{
			oscTrigger.free;
		});
		// oscTrigger =  OSCFunc({ arg msg, time;
		//     // [time, msg].postln;
		//     if (msg[2]==1,{
		// 	    NetAddr("127.0.0.1", 10111).sendMsg("strength",msg[3]);
		//     });
		//     if (msg[2]>99,{
		// 	    NetAddr("127.0.0.1", 10111).sendMsg("eq",msg[2]-99,msg[3]);
		//     });
		// },'/tr', server.addr);

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

		// buses to send information back to norns
		totalStrengthBus=Bus.control(server,1);
		spectrumAnalysisBus=Bus.control(server,10);


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
		streamPlayers = Array.fill(numStreams,{ arg i;
			("creating streaming player "++(i)).postln;
			PradStreamPlayer.new(i, server, streamBusses[i], strengthBusses[i], dialBus)
		});

		"creating noise".postln;
		noise = PradNoise.new(server, noiseBus, dialBus);

		"creating selector".postln;
		selector = PradStreamSelector.new(server, streamBusses, strengthBusses, noiseBus, outputBus, totalStrengthBus);

		// "adding effects".postln;
		effects = PradEffects.new(server, outputBus);

		// "adding saturator".postln;
		// saturator = PradStereoBitSaturator.new(server, server, outputBus);

		// TODO: add 10-band equalizer at the end?

		"creating output synth".postln;
		spectrumSendFreq=0;
		outputSynth = {
			arg in, out=0, threshold=0.99, lookahead=0.2, sendFreq=0, specBus;
			var snd, fft, array, arraySendFreq;
			snd = In.ar(in, 2);
			snd = Limiter.ar(snd, threshold, lookahead).clip(-1, 1);
			fft = FFT(LocalBuf(1024),snd[0]);
		    array = FFTSubbandPower.kr(fft, [30, 60, 110, 170, 310, 600, 1000, 3000, 6000],scalemode:2);
		    (0..9).do({ arg i;
				Out.kr(specBus+i,Lag.kr(Clip.kr(LinLin.kr(array[i].ampdb,-96,96,0,1)),2));
		    });
			Out.ar(0, snd/2);
		}.play(target:server, args:[\in, outputBus.index,\specBus,spectrumAnalysisBus.index], addAction:\addToTail);

		// send periodic information to norns
		sendRoutine=Routine{
			inf.do{
				(1/7).sleep;
				totalStrengthBus.get({ arg val;
					NetAddr("127.0.0.1", 10111).sendMsg("strength",val);
				});
				if (spectrumSendFreq>0,{
					spectrumAnalysisBus.getn(10,{ arg arr;
						NetAddr("127.0.0.1", 10111).sendMsg("spectrum",*arr);
					});
				});
			}
		}.play;
	}

	// set file location
	refreshStations {
		// clear system clock to prevent the current sleeping processes from
		// starting an overlapping stream
		SystemClock.clear;
		// stop the current file and play the next
		streamPlayers.do({ arg syn, i;
			streamPlayers[i].stopCurrent();
			streamPlayers[i].playNextFile();
		});
	}

	getEngineState {
		var nStreams=streamPlayers.size-1;
		var msg=List.new();
		msg.add("enginestate");
		(0..nStreams).do({arg i;
			("station"++i).postln;
			msg.add("station");
			msg.add(i);
			msg.add("file");
			msg.add(streamPlayers[i].fnames[streamPlayers[i].swap]);
			msg.add("pos");		
			msg.add(Main.elapsedTime - streamPlayers[i].fileCurrentPos);
			msg.add("playlist");
			msg.add(streamPlayers[i].fileIndexCurrent);
		});
		NetAddr("127.0.0.1", 10111).sendMsg(*msg);
	}


	// set the dial position
	setDial {
		arg value;
		dial.setDial(value);
	}

	// set the dial position
	setSpectrumSendFreq {
		arg value;
		("setting output send freq to"+value).postln;
		spectrumSendFreq=value;
	}

	// setBand will set the band and bandwidth of station i
	setBand {
		arg i,band,bandwidth;
		streamPlayers[i].setBand(band,bandwidth);
	}

	// setCrossfade will change the crossfade time (default 20 seconds)
	setCrossfade {
		arg i, xfade;
		streamPlayers[i].setCrossfade(i,xfade);
	}

	addFile {
		arg i,fname;
		streamPlayers[i].addFile(fname);
	}

	syncStation {
		arg i, playlistPosition, currentFileName, currentTime;
		streamPlayers[i].setPlaylistPosition(playlistPosition);
		streamPlayers[i].stopCurrent();
		streamPlayers[i].playFile(currentFileName,currentTime);
	}

	clearFiles {
		arg i;
		streamPlayers[i].clearFiles;
	}

	// set an effect parameter
	setFxParam {
		arg key, value;
		effects.setParam(key, value);
	}

	// stop and free resources
	free {
		// by default i tend to free stuff in reverse order of alloctaion
		SystemClock.clear;
		sendRoutine.stop;
		sendRoutine.free;
		outputSynth.free;

		effects.free;
		selector.free;
		dial.free;
		noise.free;
		streamPlayers.do({ arg player; player.free; });

		totalStrengthBus.free;
		spectrumAnalysisBus.free;
		dialBus.free;
		outputBus.free;
		noiseBus.free;
		streamBusses.do({ arg bus; bus.free; });
		strengthBusses.do({ arg bus; bus.free; });
		oscTrigger.free;
		"pkill -f ogg123".systemCmd;
		"pkill -f lame".systemCmd;
		"pkill -f curl".systemCmd;
		"rm -rf /dev/shm/sc3mp3*".systemCmd;
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
			Out.kr(outBus, Lag.kr(dial,0.01));
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
	var <ismp3;
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
	var <fileSpecial;
	var <fileCurrentPos;
	var <fileScheduler;

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
		filePaths=List();
		swap = 0;
		crossfade=10;
		fileIndexCurrent=(-1);
		fileCurrentPos=0;
		fileScheduler=0;
		synths=Array.newClear(2);
		bufs=Array.newClear(2);
		mp3s=Array.newClear(2);
		ismp3=Array.newClear(2);
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
		var nextFile=nil;
		if (fileSpecial.isNil,{
			if (filePaths.size>0,{
				fileIndexCurrent=fileIndexCurrent+1;
				if (fileIndexCurrent>(filePaths.size-1),{
					fileIndexCurrent=0;
				});
				if (filePaths[fileIndexCurrent]==nil,{
					fileIndexCurrent=0;
				});
				("station "+id+" queing next file "+(fileIndexCurrent+1)+" of "+filePaths.size).postln;
				nextFile=filePaths[fileIndexCurrent];
			});
		},{
			("using special file "+fileSpecial).postln;
			nextFile=fileSpecial;
			fileSpecial=nil;
		});
		if (nextFile.notNil,{
			this.playFile(nextFile);
		});
	}

	playFile {
		arg fname, startSeconds=0;
		var p,l,l2,l3;
		var durationSeconds=1,numChannels=2,numFrames=1.0;
		var xfade=0;
		var sndfile;
		var currentFileScheduler=0;
		var originalFname=fname;

		// swap synths/buffers
		swap=1-swap;
		("station "++id++" playing file "++fname.asAbsolutePath).postln;
		fnames[swap]=(fname.asAbsolutePath).asString;

		// send update to server that a song is playing
		NetAddr("127.0.0.1", 10111).sendMsg("playing",id,fnames[swap]);


		// get sound file information
		sndfile=SoundFile.openRead(fnames[swap]);
		if (sndfile.notNil,{
			durationSeconds=sndfile.duration;
			numChannels=sndfile.numChannels;
			numFrames=sndfile.numFrames;
			sndfile.close;
		},{
			// fallback in case soundfile fails
			["IS NIL: "++fnames[swap]].postln;
			// get sound file duration
			p = Pipe.new("ffprobe -i '"++fname.asAbsolutePath++"' -show_format -v quiet | sed -n 's/duration=//p'", "r"); 
			l = p.getLine;                    // get the first line
			p.close;                    // close the pipe to avoid that nasty buildup

			// get sound channels
			p = Pipe.new("ffprobe -loglevel quiet -i '"++fname.asAbsolutePath++"' -show_streams -select_streams a:0 | grep channels | sed 's/channels=//g'", "r");
			l2 = p.getLine;                    // get the first line
			p.close;                    // close the pipe to avoid that nasty buildup
			// ("channels: "++l2).postln;

			// get sound channels
			p = Pipe.new("ffprobe -i '"++fname.asAbsolutePath++"' -show_streams -v quiet | sed -n 's/sample_rate=//p'", "r"); 
			l3 = p.getLine;                    // get the first line
			p.close;                    // close the pipe to avoid that nasty buildup
			// ("sample rate: "++l3).postln;
			if (l.isNil||l2.isNil,{
				numChannels=2;
				durationSeconds=10;
				numFrames=48000*durationSeconds;
			},{
				numChannels=l2.asInteger;
				numFrames=l3.asFloat;
				durationSeconds=l.asFloat;
			});
		});
		if (startSeconds<durationSeconds,{
			durationSeconds=durationSeconds-startSeconds;
		});

		// if the file length is less than crossfade, reconfigure xfade
		xfade=crossfade;
		if (xfade>(durationSeconds/3),{
			xfade=durationSeconds/3;
		});

		// close the current buffer and queue up the next one
		if (bufs[swap]!=nil,{
			bufs[swap].free;
		});
		if (fnames[swap].endsWith(".ogg")==true,{
			if (mp3s[swap]!=nil,{
				mp3s[swap].finish;
			});
			mp3s[swap]=MP3(fname.absolutePath,\readfile,\ogg,startSeconds);
			bufs[swap]=Buffer.cueSoundFile(server,mp3s[swap].fifo,numChannels:numChannels);
		},{
			if (fnames[swap].endsWith(".mp3")==true,{
				"playing mp3".postln;
				if (mp3s[swap]!=nil,{
					mp3s[swap].finish;
				});
				mp3s[swap]=MP3(fname.absolutePath,\readfile,\mp3,startSeconds);
				bufs[swap]=Buffer.cueSoundFile(server,mp3s[swap].fifo,numChannels:numChannels);
			},{
				if (originalFname.beginsWith("http")==true,{
					"playing mp3 stream".postln;
					if (mp3s[swap]!=nil,{
						mp3s[swap].finish;
					});
					mp3s[swap]=MP3(originalFname,\readurl,\mp3,startSeconds);
					bufs[swap]=Buffer.cueSoundFile(server,mp3s[swap].fifo,numChannels:numChannels);
				},{
					bufs[swap]=Buffer.cueSoundFile(server,fname.absolutePath,startFrame:startSeconds*server.sampleRate, numChannels:numChannels);
				});
			});
		});

		// replace our current synth with the new one (preserves order)
		synths[swap] = {
			arg out=0,bufnum=0,ba=0,bw=1,xfade=1,duration=1,toggle=1;
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
					[4,-4]),Dust.kr(1-strength+SinOsc.kr(Rand(0.01,0.1)).range(0.01,0.05)))
			);
			// remove the long tail
			// set the strength to zero at bandwidth*3
			strength=Select.kr((dial-ba).abs>(3*bw),[strength,0]);
			// if its close, set it to 1
			strength=Select.kr((dial-ba).abs<0.02,[strength,1]);


			snd = VDiskIn.ar(numChannels, bufnum, BufRateScale.kr(bufnum));
			snd = Pan2.ar(snd);

			// send strength through control bus
			Out.kr(outStrengthBus, strength*toggle);

			// send crossfaded sound through sound bus
			Out.ar(outBus,snd*env*toggle);
		}.play(target:synths[swap],args:[
			\ba, band,\bw,bandwidth,
			\xfade,xfade,\duration,durationSeconds,
			\out,outBus.index,\bufnum,bufs[swap]],addAction:\addReplace);
		// start a clock to queue the next file (before current is done)
		fileCurrentPos=Main.elapsedTime;
		fileScheduler=fileScheduler+1;
		currentFileScheduler=fileScheduler;
		SystemClock.sched(durationSeconds-xfade, {
			if (currentFileScheduler==fileScheduler,{
				this.playNextFile;
			});
			nil
		});
	}

	setPlaylistPosition {
		arg i;
		fileIndexCurrent=i;
	}

	setBand {
		arg ba,bw;
		("setting station "++id++" to band "++ba++" +/- "++bw).postln;
		band=ba;
		bandwidth=bw;
		synths.do({ arg synth; synth.set(\ba, band,\bw,bandwidth); });
	}

	setCrossfade {
		arg xfade;
		crossfade=xfade;
	}

	// setFilePaths will configure the indicies allowed to play through
	addFile {
		arg fname;
		if (fname.notNil,{
			("station"+id+"adding file"+fname).postln;
			filePaths=filePaths.add(fname);
		},{
			"addFile: filename is nil!".postln;
		});
	}

	clearFiles {
		("station"+id+"clearing files").postln;
		filePaths=List();
	}

	stopCurrent {
		synths[swap].set(\toggle,0);
		// this ensures its clock won't fire
		fileScheduler=fileScheduler+1;
	}

	////////////////

	free {
		synths.do({ arg synth; synth.free; });
		bufs.do({ arg buf; buf.free; });
		(0..1).do({arg i;
			if (mp3s[i]!=nil,{
				mp3s[i].finish;
			});
		});
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
			band1=0,band2=0,band3=0,band4=0,band5=0,band6=0,band7=0,band8=0,band9=0,band10=0,
			effect_delay=0, effect_delaytime=0.2, effect_delaydecaytime=2, effect_delaymul=1,
			effect_granulator=0, effect_graintrigger=10, grainDur=0.2, effect_grainrate=1, effect_grainpos=0, effect_graininterp=2, effect_grainmul=1,
			grainPan=0;

			var snd, combBuf1, grnBuf1, effect_maxgrains=512;

	      		snd = In.ar(bus, 2);

			// 10-band equalizer
			snd = BPeakEQ.ar(snd,60,db:Lag.kr(band1));
			snd = BPeakEQ.ar(snd,170,db:Lag.kr(band2));
			snd = BPeakEQ.ar(snd,310,db:Lag.kr(band3));
			snd = BPeakEQ.ar(snd,600,db:Lag.kr(band4));
			snd = BPeakEQ.ar(snd,1000,db:Lag.kr(band5));
			snd = BPeakEQ.ar(snd,3000,db:Lag.kr(band6));
			snd = BPeakEQ.ar(snd,6000,db:Lag.kr(band7));
			snd = BPeakEQ.ar(snd,12000,db:Lag.kr(band8));
			snd = BPeakEQ.ar(snd,14000,db:Lag.kr(band9));
			snd = BPeakEQ.ar(snd,16000,db:Lag.kr(band10));

			////////////////
			// snd = DelayC.ar(snd, delaytime:LFNoise2.kr(chorusRate).linlin(-1,1, 0.01, 0.06));
			// snd = Greyhole.ar(snd);
			// snd = (snd*preGain).distort.distort;
			//... or whatever
			///////////
			

      // granulator
	  		effect_granulator=Lag.kr(effect_granulator,0.2);
			grnBuf1 = Buffer.alloc(server,server.sampleRate*1);
			snd = (snd*(1-effect_granulator))+
				(effect_granulator*GrainIn.ar(
					2,
					Impulse.kr(effect_graintrigger),
					grainDur,
					snd,
					grainPan
			));

			// delay
			effect_delay=Lag.kr(effect_delay,0.2);
      		combBuf1 = Buffer.alloc(server,48000,2);
      		snd = (snd*(1-effect_delay))+(effect_delay*BufCombC.ar(combBuf1,snd,effect_delaytime,effect_delaydecaytime,effect_delaymul));

      // `ReplaceOut` overwrites the bus contents (unlike `Out` which mixes)
			// so this is how to do an "insert" processor
			ReplaceOut.ar(bus, snd);
		}.play(target:server, args:[\bus, bus.index], addAction:\addToTail);
	}

	setParam {
		arg key, value;
		synth.set(key, value);
	}

	free {
		synth.free;
	}
}


// this will be responsible for selecting / mixing all the streams / noise
PradStreamSelector {
	var <synth;

	*new {
		arg server, streamBusses, strengthBusses, noiseBus, outBus, totalStrBus;
		^super.new.init(server, streamBusses, strengthBusses, noiseBus, outBus, totalStrBus);
	}

	init { arg server, streamBusses, strengthBusses, noiseBus, outBus, totalStrBus;
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
			Out.kr(totalStrBus, Lag.kr(totalstrength,0.05));

			// lose frames based on the strength
			mix=WaveLoss.ar(mix,LinLin.kr(totalstrength,0,1,90,0),100,2);

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
