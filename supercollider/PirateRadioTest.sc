// first put PirateRadio.sc into your class directory (see here: https://doc.sccode.org/Guides/UsingExtensions.html)
// then recompile with Ctl+Shift+L (windows)

(
// define radio
p=PirateRadio.new(s,"C:\\Users\\zacks\\Desktop\\temp\\shortaudio");
// set band and bandwidth of station 0
p.setBand(0,94.7,0.1);
// set band and bandwidth of station 1
p.setBand(1,98.6,0.2);
)

// change the dial to different stations
p.setDial(90.7); // no station
p.setDial(94.7); // station "0"
p.setDial(98.6); // station "1"

// interrupt station broadcast with a file (afte rwhich it continues)
// (useful for shoutouts)
p.playFile(0,"C:\\Users\\zacks\\Desktop\\temp\\shortaudio\\172-8-12.wav");



