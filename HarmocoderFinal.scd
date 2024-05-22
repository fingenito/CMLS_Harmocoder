s.boot;
s.meter;

(

b = Buffer.read(s, PathName(thisProcess.nowExecutingPath).parentPath ++ "Api 3#30.aif");

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

	// [freq.cpsmidi, hasFreq].poll;

	// amp.poll;

    Out.kr(\freqBus.ir(0), freq);
    Out.kr(\hasFreqBus.ir(0), hasFreq);
}).add;

// SynthDef for pitch tracking
SynthDef(\chorus, {
    var in, out, env;

	in = In.ar(\in.ir(0),1);

	env = EnvGen.kr(Env.adsr(attackTime: 2.5, decayTime: 0.3, sustainLevel: 1.0, releaseTime: 0.5, peakLevel: 1.0, curve: -4.0), \gate.kr(1));

	out = DelayC.ar(in, maxdelaytime: 0.2,  delaytime: SinOsc.kr({ExpRand(0.5, 2) * \modFreq.kr(0.25)}!4).range(0, {ExpRand(0.5, 2)*\modAmount.kr(0.02)}!4));

	out = Splay.ar(out * \outputVolume.kr(0).dbamp * env);

	Out.ar(\out.ir(0), out);
}).add;


SynthDef(\reverb, { |roomsize, revtime, damping, inputbw, spread = 15, earlylevel, taillevel|

	var in = In.ar(\in.ir(0),1);

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

	out = Splay.ar(out * \outputVolume.kr(0).dbamp) * 0.5;

	Out.ar(\out.ir(0), out);

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

~setKeyandScale.(0,true);


// harmonizer
SynthDef.new(\autoHarmonizer,{
	var in, amp, freq, hasFreq, out;
	var midiNoteRound;
	var harmony1, harmony2, harmony3, partials;


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


	out = Splay.ar(PitchShift.ar(in, 0.2, (partials.ratiomidi - In.kr(~freqBus).cpsmidi + midiNoteRound).midiratio, 0, 0.005));

	out = DelayL.ar(out, delaytime: 0.07);

	Out.ar(\out.ir(0),(out/partials.size));

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
		~src = Synth.new(\source, [\out, ~srcBus, \gain, -6], ~sourceGrp);
		~pitchTracker = Synth.new(\pitchTracker, [\in, ~srcBus, \freqBus, ~freqBus, \hasFreqBus, ~hasFreqBus], ~sourceGrp, \addToTail);
		~synthGrp = Group.after(~sourceGrp);
		~autoHarm = Synth.new(\autoHarmonizer, [\in, ~srcBus, \out, ~fxBus, \harmDiffbufNum1, ~harmDiffbuf1.bufnum, \harmDiffbufNum2, ~harmDiffbuf2.bufnum, \harmDiffbufNum3, ~harmDiffbuf3.bufnum], ~synthGrp, \addToTail);
		~fxGrp = Group.after(~synthGrp);
		~reverb = Synth(\reverb, [\in, ~fxBus, \out, 0, \wet, 0.6, \roomsize, 80, \revtime, 2, \damping, 0.41, \inputbw, 0.8, \earlylevel, -18, \taillevel, 0], ~fxGrp, \addToTail);
		~chorus = Synth.new(\chorus, [\in, ~fxBus, \out, 0, \wet, 0.7, \modFreq, 0.25, \modAmount, 0.02], ~fxGrp, \addToTail);
		~dry =  Synth.new(\dry, [\in, ~fxBus, \out, 0, \outputVolume, -6], ~fxGrp, \addToTail);

	});
};
ServerTree.removeAll;
ServerTree.add(~setup);
)

~src2 = Synth.new(\source, [\out, ~fxBus, \gain, -6], ~sourceGrp);


// ____ SOURCE
~src.set(\choose, 1);  // buffer in
~src.set(\choose, 0);  // audio in
~src.set(\gain, -inf); // nulls input
~src.set(\gain, 3);   //
// ____

// ____ CHORUS
~chorus.set(\outputVolume, -100);
~chorus.set(\outputVolume, 0);
~chorus.set(\gate, 0);
~chorus.set(\gate, 1);
// ____

// ____ REVERB
~reverb.set(\outputVolume, -100);
~reverb.set(\outputVolume, 0);
// ____


// ____ DRY
~dry.set(\outputVolume, -100);
~dry.set(\outputVolume, -18);
// ____


~setKeyandScale.(1, false); // C# min
~setKeyandScale.(0, true);  // C maj