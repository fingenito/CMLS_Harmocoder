s.boot;

// connect with serial port
(
p = SerialPort(
    "COM6",    //edit to match your port. SerialPort.listDevices
    baudrate: 115200,    //check that baudrate is the same as in arduino sketch
    crtscts: true);
)




(
SynthDef(\insert, {arg bus;
	var sig;
	sig = In.ar(bus, 2);
	sig = VSTPlugin.ar(sig, 2, id:\instrument);
	sig = VSTPlugin.ar(sig, 2, id:\effect);
	ReplaceOut.ar(bus, sig, 2);
}).add;

)

~synth = Synth(\insert, [\bus, 0]);
~instrument = VSTPluginController(~synth, \instrument);
~effect = VSTPluginController(~synth, \effect);

~instrument.open("C:/Program Files/Common Files/VST2/SINTETIZZATORI/VK-1 Viking Synthesizer.dll", editor:true);
~instrument.gui;
~instrument.editor;
~instrument.program_(1);

~effect.open("C:/Program Files/Common Files/VST3/Distortion_Effect.vst3", editor:true);
~effect.gui;
~effect.editor;

~ctl = Bus.control;
~lfo = {Out.kr(~ctl, SinOsc.kr(0.005, 0, 0.5, 0.5))}.play;
~effect.map(2, ~ctl);

(
c = Pbind(
	\type, \midi,
	\midiout, ~instrument.midi,
	\chan, 0,
	\degree, Pwhite(0, 12, inf),
	\dur, Prand(#[4.125, 4.25, 4.5, 4], inf),
	\legato, Pexprand(0.5, 1.0, inf),
	\amp, Pexprand(0.5, 1.0, inf)
).play(quant:1);
)

// sending msg to processing
thisProcess.openUDPPort(12000);
b = NetAddr.new("127.0.0.1", 12000);


(
r= Routine({
    var byte, str, res, mapped_value;
    99999.do{|i|
        if(p.read==10, {
            str = "";
            while({byte = p.read; byte !=13 }, {
                str= str++byte.asAscii;
            });
            res= str.asInteger;
			mapped_value = res.linlin(0, 1024, 0, 1);
			mapped_value.postln;
			~effect.set(2, mapped_value);
			b.sendMsg("/sliderMsg", mapped_value);

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


