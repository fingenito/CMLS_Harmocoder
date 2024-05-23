// Avvia SuperCollider
s.boot;

NetAddr("127.0.0.1",57120);
(
OSCdef('OSCreceiver',
	{
		arg msg;

		msg.postln;

		/*if (
			msg[1].asString == "synth1",
			{
				~synth1.set(\onOff, 1);
				~synth2.set(\onOff, 0);
			},
			{
				~synth2.set(\onOff, 1);
				~synth1.set(\onOff, 0);
		    }
		);*/

    }, '/harmSelected', nil, 57120);
)

(
OSCdef('OSCreceiver1',
	{
		arg msg;

		msg.postln;

		/*if (
			msg[1].asString == "synth1",
			{
				~synth1.set(\onOff, 1);
				~synth2.set(\onOff, 0);
			},
			{
				~synth2.set(\onOff, 1);
				~synth1.set(\onOff, 0);
		    }
		);*/

    }, '/harmSetting', nil, 57120);
)


(
var pippo;
pippo = "synth1";
if (
			pippo == "synth1",
			{
				~synth1.set(\onOff, 1);
				~synth2.set(\onOff, 0);
			},
			{
				~synth2.set(\onOff, 1);
				~synth1.set(\onOff, 0);
		    }
		);
)

// Definisci il SynthDef

(
SynthDef(\sine440, {
    |out = 0, freq = 440, amp = 0.5, amp1 = 0|
    var signal;
	signal = Select.ar(\onOff.kr(0), [
		SinOsc.ar(freq) * amp1,
		SinOsc.ar(freq) * amp, // Genera una sinusoide a 440 Hz
	]);
	Out.ar(out, signal ! 2); // Invia il segnale all'uscita stereo
}).add;
)


(
SynthDef(\sine880, {
    |out = 0, freq = 880, amp = 0.5, amp1 = 0|
    var signal;
	signal = Select.ar(\onOff.kr(0), [
		SinOsc.ar(freq) * amp1,
		SinOsc.ar(freq) * amp, // Genera una sinusoide a 440 Hz
	]);
    Out.ar(out, signal ! 2); // Invia il segnale all'uscita stereo
}).add;
)



~synth1 = Synth(\sine440);
~synth2 = Synth(\sine880);


~synth1.set(\onOff, 1);
~synth2.set(\onOff, 1);

(
~synth1.set(\onOff, 0);
~synth2.set(\onOff, 0);
)




~sourceGrp = Group.new;
~outBus = Bus.audio(s, 2);
~synth1 = Synth(\sine440, [\out, ~outBus]);
~synth1 = nil;
~synth2 = Synth(\sine880, [\out, ~outBus]);
~synth2 = nil;
