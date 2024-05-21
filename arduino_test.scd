(
// Definizione del Synth
SynthDef(\serialControlledOsc, { |freq = 440|
    var osc;
    osc = SinOsc.ar(freq, 0, 0.5);
    Out.ar(1, osc);
}).add;
)


SerialPort.closeAll;
SerialPort.devices;
SerialPort.listDevices;

(
p = SerialPort(
    "COM6",    //edit to match your port. SerialPort.listDevices
    baudrate: 115200,    //check that baudrate is the same as in arduino sketch
    crtscts: true);
)

~synth = Synth(\serialControlledOsc); // Istanzia il synth

(
r= Routine({
    var byte, str, res, f;
    99999.do{|i|
        if(p.read==10, {
            str = "";
            while({byte = p.read; byte !=13 }, {
                str= str++byte.asAscii;
            });
            res= str.asInteger;
			// ("read value:"+res).postln;
			f = res.linlin(1, 1024, 20, 1000);
			// f.postln;
			~synth.set(\freq, f);
        });
    };
}).play;
)

r.stop;

p.close;