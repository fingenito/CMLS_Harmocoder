s.boot;

(
OSCdef('OSCreceiver',
	{
		arg msg;

		msg.postln;

    }, '/harmSelected', nil, 57120);
)

(
OSCdef('OSCreceiver1',
	{
		arg msg;

		msg.postln;

    }, '/harmSetting', nil, 57120);
)

// connect with serial port
(
p = SerialPort(
    "COM6",    //edit to match your port. SerialPort.listDevices
    baudrate: 115200,    //check that baudrate is the same as in arduino sketch
    crtscts: true);
)

// SerialPort.listDevices


(
SynthDef(\insert, {arg bus;
	var sig;
	sig = In.ar(bus, 2);
	sig = VSTPlugin.ar(sig, 2, id:\instrument);
	sig = VSTPlugin.ar(sig, 2, id:\effect1);
	sig = VSTPlugin.ar(sig, 2, id:\effect2);
	ReplaceOut.ar(bus, sig, 2);
}).add;

)

(
~synth = Synth(\insert, [\bus, 0]);
~instrument = VSTPluginController(~synth, \instrument);
~effect1 = VSTPluginController(~synth, \effect1);
~effect2 = VSTPluginController(~synth, \effect2);
)
// ~instrument.open("C:/Program Files/Common Files/VST2/SINTETIZZATORI/VK-1 Viking Synthesizer.dll", editor:true);
// ~instrument.gui;
// ~instrument.editor;
// ~instrument.program_(1);

~effect1.open("C:/Program Files/Common Files/VST3/Distortion_Effect.vst3", editor:true);
~effect1.gui;
~effect1.editor;

~effect2.open("C:/Program Files/Common Files/VST3/ValhallaFreqEcho.vst3", editor:true);
~effect2.gui;
~effect2.editor;

// VSTPlugin.search;

// ~ctl = Bus.control;
// ~lfo = {Out.kr(~ctl, SinOsc.kr(0.005, 0, 0.5, 0.5))}.play;
// ~effect.map(2, ~ctl);

// (
// c = Pbind(
// 	\type, \midi,
// 	\midiout, ~instrument.midi,
// 	\chan, 0,
// 	\degree, Pwhite(0, 12, inf),
// 	\dur, Prand(#[4.125, 4.25, 4.5, 4], inf),
// 	\legato, Pexprand(0.5, 1.0, inf),
// 	\amp, Pexprand(0.5, 1.0, inf)
// ).play(quant:1);
// )

// sending msg to processing
thisProcess.openUDPPort(12000);
b = NetAddr.new("127.0.0.1", 12000);


(
r= Routine({
    var byte, str, arduinoMsg, arduinoMsgsplitted, grayScaleValue, accYValue, accZValue;
    99999.do{|i|
        if(p.read==10, {
            str = "";
            while({byte = p.read; byte !=13 }, {
                str= str++byte.asAscii;
            });
            arduinoMsg= str;
			// arduinoMsg.postln;

			// Separare la stringa utilizzando il delimitatore ", "
			arduinoMsgsplitted = arduinoMsg.split($,);

			/*// Stampare i risultati
			arduinoMsgsplitted.do { |str, i|
				("String #" ++ (i+1) ++ ": " ++ str).postln;

			};*/

			// dealing with grayScale value
			grayScaleValue = arduinoMsgsplitted[0].asFloat.linlin(0, 1024, 0, 1).postln;
			/*~effect1.set(2, grayScaleValue);*/

			accYValue = arduinoMsgsplitted[1].asFloat.postln;

			accZValue = arduinoMsgsplitted[2].asFloat.postln;







			/*mapped_value = res.linlin(0, 1024, 0, 1);
			mapped_value.postln;
			~effect1.set(2, mapped_value);
			b.sendMsg("/sliderMsg", mapped_value);*/

			//0.001.wait
        });
    };
}).play;
)

c.stop;
r.stop;
p.close;
SerialPort.closeAll;



~effect.set(2, 0.75);

(
var inputString, separatedStrings;

// La stringa di input
inputString = "1, 2, 3";

// Separare la stringa utilizzando il delimitatore ", "
separatedStrings = inputString.split($,);

// Stampare i risultati
separatedStrings.do { |str, i|
    ("String #" ++ (i+1) ++ ": " ++ str).postln;
};
)


