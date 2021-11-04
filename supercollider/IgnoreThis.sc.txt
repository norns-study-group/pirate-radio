// this is a classless pirate radio that I wrote to get the basic functionality
// its a bit of a mess
// three synthdefs
// dial -> N stations -> final output

(
// dial is a synth that sends out the current dialed in frequency
// this is outputed to each station
SynthDef("dial",{
	arg band=99.6,busBand;
	Out.kr(busBand,MouseX.kr(90,105));
}).add;

// station has a set band and bandwidth
// station listens to the dial through a control bus (busBand)
// station outputs its strength (computed from dialed frequency)
// station outputs attenuated sound
SynthDef("station",{
	arg band=0,bandwidth=0.5,busBand,busStrength,busSound,buf,id,sndid;
	var snd,currentBand,strength,done;
	// get the current band
	currentBand=In.kr(busBand,1);

	// strength is a function centered around band (sorta Gaussian)
	strength=exp(0.5.neg*(((currentBand-band)/bandwidth)**2).abs);

	// any sound
	snd = VDiskIn.ar(2, buf);

	// send a trigger when its out
	SendTrig.kr(Done.kr(snd),id,sndid);

	// output the strength
	Out.kr(busStrength,strength);

	// output the attenuated sound
	Out.ar(busSound,snd*strength);
}).add;


// final stage
// collects the final sound through audio bus (busSound)
// collects the final strength through control bus (busStrength)
// adds noise based on inverse of strength
// does eq
// does fx
SynthDef("final",{
	arg out,busSound,busStrength,busBand;
	var snd,bandStrength,noise,dial,moving;
	// get the current strength
	bandStrength=In.kr(busStrength,1);
	snd=In.ar(busSound,2);
	dial=In.kr(busBand,1);

	// add moving noise
	moving = EnvGen.kr(Env.perc(0.1,1),Changed.kr(dial)+Dust.kr(0.1));
	noise = BrownNoise.ar(0.2).dup + LPF.ar(Dust.ar(1), LinExp.kr(LFNoise2.kr(0.1),0,1,100, 4000));
	noise = noise + SinOsc.ar(LFNoise2.kr(LinExp.kr(LinLin.kr(LFNoise1.kr(0.5),0,1,50, 100),60,666)),mul:moving);
	noise = SelectX.ar(moving,[noise,noise.ring1(SinOsc.ar(LFNoise2.kr(LinExp.kr(LinLin.kr(LFNoise1.kr(0.5),0,1,1, 100),60,666))).dup)]);

	// add fx like white noise inversely related to total band strength
	snd=snd+(noise*(Clip.kr(1-bandStrength)));

	// add limiter
	snd = Limiter.ar(snd, 0.99, 0.2).clip(-1, 1);

	Out.ar(out,snd);
}).add;
)


(
Routine {
	// trigger handler for setting up next songs
	~getTrig.free;
	~getTrig= OSCFunc({ arg msg, time;
		var nextSong=0, stationID=0;
		stationID=msg[2];
		nextSong=msg[3]+1;
		if (nextSong>~stationFileRange[stationID][1],{
			nextSong=~stationFileRange[stationID][0];
		});
		("updating station to "++stationID++" to song "++nextSong).postln;
		~stationBuffers[stationID].free;
		~stationBuffers[stationID]=Buffer.cueSoundFile(s,~fileList[nextSong].asAbsolutePath);
		~stationSyn[stationID].free;
		~stationSyn[stationID]=Synth.new("station",[\buf,~stationBuffers[stationID],\band,~bands[stationID],\busBand,~busBand,\busStrength,~busStrength,\busSound,~busSound,\id,stationID,\sndid,nextSong]);
	},'/tr', s.addr);


	// control bus for the current band
	~busBand=Bus.control(s,1);

	// control bus for the band strength
	// each station outputs its strength based on the current band
	~busStrength=Bus.control(s,1);

	// audio bus for the station sound
	// each station output its sound attenuated by its strength
	~busSound=Bus.control(s,2);

	// filelist containing all the music files
	// CHANGE THIS TO YOUR FILE
	~fileList=PathName.new("C:\\Users\\zacks\\Desktop\\temp\\shortaudio").files;
	// randomize filelist
	~fileList=~fileList.scramble;


	// setup an array of stations
	// the bands can be hard coded
	~bands=[95,99,103];

	// define the buffers
	~stationBuffers=Array.fill(~bands.size,{
		Buffer.alloc(s,400,2);
	});
	~stationFileRange=Array.fill(~bands.size,{
		arg i;
		var maxNum=((~fileList.size/~bands.size).floor).asInteger;
		var startNum=i*maxNum;
		[startNum,maxNum+startNum-1].postln
	});
	~stationSyn=Array.fill(~bands.size,{arg i;
		var fsnd=SoundFile.new;
		var fname=~fileList[~stationFileRange[i][0]];
		fname.postln;
		~stationBuffers[i]=Buffer.cueSoundFile(s,fname.absolutePath);
		Synth.new("station",[\buf,~stationBuffers[i],\band,~bands[i],\busBand,~busBand,\busStrength,~busStrength,\busSound,~busSound,\id,i,\sndid,~stationFileRange[i][0]])
	});


	// add the control dial (currently just Mouse X position)
	Synth.head(s,"dial",[\busBand,~busBand]);

	// add the final stage
	Synth.tail(s,"final",[\busSound,~busSound,\busStrength,~busStrength,\busBand,~busBand]);
}.play;
)
