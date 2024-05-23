s.boot;
s.meter;

VSTPlugin.search;

(
//setup code for busses, synths, groups
~setup = {
	s.newBusAllocators;
	~fxBus = Bus.audio(s,2);
	~srcBus = Bus.audio(s,2);
	~freqBus = Bus.control(s);
	~hasFreqBus = Bus.control(s);
	s.bind({
		~sourceGrp = Group.new;
		~src = Synth.new(\source, [\out, ~srcBus, \gain, 0], ~sourceGrp);
		~pitchTracker = Synth.new(\pitchTracker, [\in, ~srcBus, \freqBus, ~freqBus, \hasFreqBus, ~hasFreqBus], ~sourceGrp, \addToTail);
		~synthGrp = Group.after(~sourceGrp);
		~autoHarm = Synth.new(\autoHarmonizer, [\in, ~srcBus, \out, ~fxBus, \harmDiffbufNum1, ~harmDiffbuf1.bufnum, \harmDiffbufNum2, ~harmDiffbuf2.bufnum, \harmDiffbufNum3, ~harmDiffbuf3.bufnum], ~synthGrp, \addToTail);
		~fxGrp = Group.after(~synthGrp);
		~reverb = Synth(\reverb, [\in, ~fxBus, \out, 0, \wet, 0.6, \roomsize, 80, \revtime, 2, \damping, 0.41, \inputbw, 0.8, \earlylevel, -18, \taillevel, 0], ~fxGrp, \addToTail);
		~chorus = Synth.new(\chorus, [\in, ~fxBus, \out, 0, \wet, 0.7, \modFreq, 0.25, \modAmount, 0.08], ~fxGrp, \addToTail);
		~distortion = Synth.new(\distortion, [\in, ~fxBus, \out, 0], ~fxGrp, \addToTail);
		~distortionPlugin = VSTPluginController(~distortion, id:\distortion);
		~distortionPlugin.open("C:/Program Files/Common Files/VST3/Distortion_Effect.vst3", editor: false, verbose: false);
		~drySynth =  Synth.new(\dry, [\in, ~fxBus, \out, 0, \outputVolume, 0], ~fxGrp, \addToTail);
		~dryMic =  Synth.new(\dry, [\in, ~srcBus, \out, 0, \outputVolume, -12], ~fxGrp, \addToTail);

	});
	0.5.wait;
	~distortionPlugin.set(0, "Hard");
	~distortionPlugin.set(1, 1);
	~distortionPlugin.set(2, 1);
	~distortionPlugin.set(3, 0.092);
	~distortionPlugin.editor;
};
ServerTree.removeAll;
ServerTree.add(~setup);
)

(

// b = Buffer.read(s, PathName(thisProcess.nowExecutingPath).parentPath ++ "Api 3#30.aif");
b = Buffer.read(s, PathName(thisProcess.nowExecutingPath).parentPath ++ "audio_sample.mp3");

// b = Buffer.read(s, PathName(thisProcess.nowExecutingPath).parentPath ++ "post.wav");

/*b.play;*/


SynthDef(\source, {
	var sig;
	sig = Select.ar(\choose.kr(1), [
		SoundIn.ar([0,1]),
		PlayBuf.ar(1, b, loop: 1)!2,
	]);
	sig = sig * \gain.kr(0).dbamp;
	Out.ar(\out.kr(0), sig);
}).add;

// SynthDef for pitch tracking
SynthDef(\pitchTracker, {
    var hasFreq, freq, tooHigh, tooLow, amp;

	amp = Amplitude.kr(In.ar(\in.ir(0),1), 0.25, 0.25);

    # freq, hasFreq = Tartini.kr(in: In.ar(\in.ir(0),1), threshold: 0.93, n: 2048, k: 1024, overlap: 1024, smallCutoff: 0.9);


	tooHigh = freq >= 84.midicps;
	tooLow = freq <= 40.midicps;
	hasFreq = hasFreq * tooHigh.not * tooLow.not; // Set hasFreq to 0 if the frequency is greater than C6 or lower than C2

	hasFreq = hasFreq * (amp >= 0.01);

	freq = Clip.kr(freq, 34.midicps, 84.midicps);

    Out.kr(\freqBus.ir(0), freq);
    Out.kr(\hasFreqBus.ir(0), hasFreq);
}).add;

// SynthDef for pitch tracking
SynthDef(\chorus, {
    var in, out, env;

	in = In.ar(\in.ir(0),1) * \inVolume.kr(0).dbamp;

	env = EnvGen.kr(Env.adsr(attackTime: 2.5, decayTime: 0.3, sustainLevel: 1.0, releaseTime: 0.5, peakLevel: 1.0, curve: -4.0), \gate.kr(1));

	out = DelayC.ar(in, maxdelaytime: 0.2,  delaytime: SinOsc.kr({ExpRand(0.5, 2) * \modFreq.kr(0.25)}!4).range(0, {ExpRand(0.5, 2)*\modAmount.kr(0.02)}!4));

	out = Splay.ar(out * env);

	Out.ar(\out.ir(0), out);
}).add;


SynthDef(\reverb, { |roomsize, revtime, damping, inputbw, spread = 15, earlylevel, taillevel|

	var in = In.ar(\in.ir(0),1) * \inVolume.kr(0).dbamp;

	var out = GVerb.ar(
            in,
            roomsize,
            revtime,
            damping,
            inputbw,
            spread,
            0,
            earlylevel.dbamp,
            taillevel.dbamp,
            roomsize);

	out = RLPF.ar(out, \lPFreq.kr(6000));

	out = RHPF.ar(out, \hPFreq.kr(100));

	out = Splay.ar(out * \outputVolume.kr(1));

	Out.ar(\out.ir(0), out);

}).add;

SynthDef.new(\distortion , {
	var env;
	env = EnvGen.kr(Env.adsr(attackTime: 2.5, decayTime: 0.3, sustainLevel: 1.0, releaseTime: 0.5, peakLevel: 1.0, curve: -4.0), \gate.kr(1));
	Out.ar(\out.ir(0), VSTPlugin.ar(In.ar(\in.ir(0), 2) * \inVolume.kr(0).dbamp, 2, id:\distortion) * env);
}).add;


~calculateDiffBuffer = {
	arg key, maj = true, interval;
	var keySteps, mapped, table, difference, buffer;
	if (maj,
		{keySteps = [0, 0, 2, 2, 4, 5, 5, 7, 7, 9, 9, 11]}, // maj
		{keySteps = [0, 0, 2, 3, 3, 5, 5, 7, 8, 8, 10, 10]} // min
	);
	mapped = ((key + keySteps) % 12).rotate(key * -1 + interval * -1); // 0 -> (C), ..., 11 -> (B).

	table = Array.fill(12, {arg i; i}); // [0,1,...,11]
	difference = Array.fill(table.size, {0});

	table.do({arg item, i;
		difference[i]  = (mapped[i]  - table[i]).midiratio;
	});

	Buffer.loadCollection(s, difference);
};


~setKeyandScale = {
	arg key = 0, maj = true;
	~harmDiffbuf1.free;
	~harmDiffbuf2.free;
	~harmDiffbuf3.free;

	~harmDiffbuf1 = ~calculateDiffBuffer.(key, maj, 0);
	~harmDiffbuf2 = ~calculateDiffBuffer.(key, maj, 4);
	~harmDiffbuf3 = ~calculateDiffBuffer.(key, maj, 7);

	~autoHarm.set(\harmDiffbufNum1, ~harmDiffbuf1.bufnum);
	~autoHarm.set(\harmDiffbufNum2, ~harmDiffbuf2.bufnum);
	~autoHarm.set(\harmDiffbufNum3, ~harmDiffbuf3.bufnum);
};


// harmonizer
SynthDef.new(\autoHarmonizer,{
	var in, amp, freq, hasFreq, out;
	var midiNoteRound;
	var harmony1, harmony2, harmony3, partials;
	var env;


	in = In.ar(\in.ir(0),2);

	midiNoteRound = In.kr(~freqBus).cpsmidi.round(1);


	harmony1 = WrapIndex.kr(\harmDiffbufNum1.kr, midiNoteRound);
	harmony2 = WrapIndex.kr(\harmDiffbufNum2.kr, midiNoteRound);
	harmony3 = WrapIndex.kr(\harmDiffbufNum3.kr, midiNoteRound);


	partials = [
		harmony1/2,
		harmony1,
		harmony2,
		harmony3,
	];

	env = EnvGen.kr(Env.adsr(attackTime: 0.5, decayTime: 0.3, sustainLevel: 1.0, releaseTime: 0.5, peakLevel: 1.0, curve: -4.0), \gate.kr(1));

	out = Splay.ar(PitchShift.ar(in, 0.2, (partials.ratiomidi - In.kr(~freqBus).cpsmidi + midiNoteRound).midiratio, 0, 0.005), spread: 0.3);

	out = DelayL.ar(out, delaytime: 0.07);

	Out.ar(\out.ir(0),out * \outVolume.kr(0).dbamp * env);

}).add;

SynthDef.new(\midiHarmIN , {
	var in, freq, hasFreq, env, out, sign;

	env = EnvGen.kr(Env.adsr(attackTime: 0.05, decayTime: 0.3, sustainLevel: 1.0, releaseTime: 0.1, peakLevel: 1.0, curve: -4.0), \gate.kr(1).varlag(0.07), doneAction:2);

	in = In.ar(\in.ir(0), 1) * env * \amp.kr;

	in = DelayL.ar(in, delaytime: 0.07);

	(In.kr(\freq.kr(1), 1).cpsmidi).poll;

	(In.kr(\hasFreq.ir(1), 1)).poll;

	sign = PitchShift.ar(in, 0.2, ((\note.kr - In.kr(\freq.kr(1), 1).cpsmidi) + \bend.kr).midiratio, 0, 0.005);

	out = SelectX.ar(In.kr(\hasFreq.ir(1), 1).varlag(0.05),
		[
			PinkNoise.ar * Amplitude.kr(in, 0.5,0.5),
			sign
		]
	);

	Out.ar(\out.ir(0), out!2);
}).add;


MIDIClient.init;
MIDIIn.connectAll;

~notes = Array.newClear(128);

MIDIdef.noteOn(\noteOnTest, {
	arg vel, nn;
	~notes[nn] = Synth.new(\midiHarmIN,
		[
			\in, ~fxBus,
			\freq, ~freqBus,
			\hasFreq, ~hasFreqBus,
			\del, 0.1,
			\note, nn,
			\amp, vel.linexp(1,127,0.75,0.75),
			\gate, 1,
		],

	);
});

MIDIdef.noteOff(\noteOffTest, {
	arg vel, nn;
	~notes[nn].set(\gate, 0);
	~notes[nn] = nil;
});


SynthDef.new(\dry , {
	Out.ar(\out.ir(0), In.ar(\in.ir(0), 2) * \outputVolume.kr(0).dbamp);
}).add;

)

/*// ____ SOURCE
~src.set(\choose, 1);  // buffer in
~src.set(\choose, 0);  // audio in
~src.set(\gain, -inf); // nulls input
~src.set(\gain, 0);   //
// ____

// ____ CHORUS
~chorus.set(\outputVolume, -100);
~chorus.set(\outputVolume, 0);
~chorus.set(\gate, 0);
~chorus.set(\gate, 1);
// ____

// ____ DISTORTION
~distortion.set(\gate, 0);
~distortion.set(\gate, 1);
// ____

// ____ REVERB
~reverb.set(\outputVolume, 0);
~reverb.set(\outputVolume, 1);
// ____


// ____ DRY
~dryMic.set(\outputVolume, -inf);
~dryMic.set(\outputVolume, -12);
// ____


~setKeyandScale.(1, false); // C# min
~setKeyandScale.(0, true);  // C maj*/



// COMMUNICATION WITH ARDUINO AND PROCESSING
// opening serial communication to speak with arduino
(
~ardToScCanal = SerialPort(
    "COM6",    //edit to match your port. SerialPort.listDevices
    baudrate: 115200,    //check that baudrate is the same as in arduino sketch
    crtscts: true);

~scToProcCanal = NetAddr.new("127.0.0.1", 12000);

~routineCommunication= Routine({
	var byte, str, arduinoMsg, arduinoMsgsplitted;
	var grayScaleValue, accYValue, accZValue;

	// reading msgs from arduino and sending them to processing
	99999.do{|i|
		if(~ardToScCanal.read==10, {
			str = "";
			while({byte = ~ardToScCanal.read; byte !=13 }, {
				str= str++byte.asAscii;
			});
			arduinoMsg= str;

			// format of arduino msg = "grayScaleValue, accYValue, accZValue"
			// Separare la stringa utilizzando il delimitatore ", "
			arduinoMsgsplitted = arduinoMsg.split($,);

			grayScaleValue = arduinoMsgsplitted[0].asFloat.linlin(0, 1024, 0, 1);
			accYValue = arduinoMsgsplitted[1].asInteger;
			accZValue = arduinoMsgsplitted[2].asInteger;

			// setting the reverb based on grayscale sensor
			~reverb.set(\outputVolume, grayScaleValue);
			~distortion.set(\gate, accYValue);
			~chorus.set(\gate, accZValue);

			// sending msgs taken from arduino to processing
			~scToProcCanal.sendMsg("/reverbValueMsg", grayScaleValue);
			~scToProcCanal.sendMsg("/accYValueMsg", accYValue);
			~scToProcCanal.sendMsg("/accZValueMsg", accZValue);

			0.001.wait
		});
	};

}).play;


// receiving msgs from processing (sent by the user) to set some parameters on sc

OSCdef('OSCreceiverHarmSelection',
	{
		arg msg;

		msg.postln;

		if (
			msg[1].asString == "harmonizer",
			{~autoHarm.set(\gate, 1); msg[1].asString},
			{~autoHarm.set(\gate, 0)}
		);



    }, '/harmSelected', nil, 57120);

OSCdef('OSCreceiverHarmSettings',
	{
		arg msg;

		var key, majorMinor;

		majorMinor = msg[1].asString == "major";
		key = msg[2].asInteger;

		~setKeyandScale.(key, false); // C# min


    }, '/harmSetting', nil, 57120);

OSCdef('OSCreceiverVoiceLevel',
	{
		arg msg;

		msg.postln;

		~dryMic.set(\outputVolume, msg[1].asFloat.ampdb);



    }, '/voiceLevel', nil, 57120);
)



// ______ STOPPA TUTTO CI STANNO TRACCIANDO _____
(
ServerTree.removeAll;
~routineCommunication.stop;
~ardToScCanal.close;
~scToProcCanal.stop;
)


