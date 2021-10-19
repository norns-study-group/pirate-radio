// first put PirateRadio.sc into your class directory (see here: https://doc.sccode.org/Guides/UsingExtensions.html)
// then recompile with Ctl+Shift+L (windows)

(
// define radio with 2 stations
p=PirateRadio.new(s,2,"/home/zns/Music/rach");
// set band and bandwidth of station 0
p.setBand(0,94.7,0.5);
// set band and bandwidth of station 1
p.setBand(1,98.6,0.5);
)


// make a mouse dial
(
{
	var m;
	m=MouseX.kr(90,102);
	SendTrig.kr(Impulse.kr(10),0,m);
	Silent.ar(2);
}.play;
o.free;
o = OSCFunc({ arg msg, time;
	p.setDial(msg[3].postln);
},'/tr', s.addr);
)


// change the dial to different stations
p.setDial(94.9); // no station
p.setDial(94.6); // station "0"
p.setDial(98.6); // station "1"

// interrupt station broadcast with a file (afte rwhich it continues)
// (useful for shoutouts)
p.setNextFile(0,"C:\\Users\\zacks\\Desktop\\temp\\shortaudio\\172-8-12.wav");