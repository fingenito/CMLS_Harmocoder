s.boot;
s.meter;

MIDIClient.init;
MIDIIn.connectAll;

b = Buffer.read(s, PathName(thisProcess.nowExecutingPath).parentPath ++ "Api 3#30.aif");

b = Buffer.read(s, PathName(thisProcess.nowExecutingPath).parentPath ++ "post.wav");

b.play;

(
SynthDef(\source, {
	var sig;
	sig = Select.ar(\choose.kr(1), [
		SoundIn.ar(0!2),
		PlayBuf.ar(1, b, loop: 1)!2,
	]);
	sig = sig * \amp.kr(1);
	Out.ar(\out.kr(0), sig);
}).add;

// SynthDef for pitch tracking
SynthDef(\pitchTracker, {
    var hasFreq, freq, tooHigh, tooLow, amp;

	amp = Amplitude.kr(In.ar(\in.ir(0),1), 0.25, 0.25);

    # freq, hasFreq = Tartini.kr(in: In.ar(\in.ir(0),1), threshold: 0.93, n: 2048, k: 1024, overlap: 1024, smallCutoff: 0.9);

	tooHigh = K2A.ar(in: freq) >= 84.midicps;
	tooLow = K2A.ar(in: freq) <= 34.midicps;
	hasFreq = hasFreq * tooHigh.not * tooLow.not; // Set hasFreq to 0 if the frequency is greater than C6 or lower than C2

	hasFreq = hasFreq * (K2A.ar(in: amp) >= 0.02);

	freq = Clip.kr(freq, 34.midicps, 84.midicps);

	// [freq.cpsmidi, hasFreq].poll;

	amp.poll;

    Out.kr(\freqBus.ir(0), freq);
    Out.kr(\hasFreqBus.ir(0), hasFreq);
}).add;
)

~hasFreqBus.scope;

(
//setup code for busses, synths, groups
~setup = {
	s.newBusAllocators;
	~fxBus = Bus.audio(s,2);
	~freqBus = Bus.control(s);
	~hasFreqBus = Bus.control(s);
	s.bind({
		~sourceGrp = Group.new;
		~src = Synth.new(\source, [\out, ~fxBus], ~sourceGrp);
		~pitchTracker = Synth.new(\pitchTracker, [\in, ~fxBus, \freqBus, ~freqBus, \hasFreqBus, ~hasFreqBus], ~sourceGrp, \addToTail);
		~fxGrp = Group.after(~sourceGrp);
	});
};
ServerTree.removeAll;
ServerTree.add(~setup);
)


// ____
~src.set(\choose, 1); // buffer
~src.set(\choose, 0); // audio in
// ____

(
SynthDef.new(\midiHarmIN , {
	var in, freq, hasFreq, env, out, sign;

	env = EnvGen.kr(Env.adsr(attackTime: 0.05, decayTime: 0.3, sustainLevel: 1.0, releaseTime: 0.1, peakLevel: 1.0, curve: -4.0), \gate.kr(1).varlag(0.07), doneAction:2);

	in = In.ar(\in.ir(0), 1) * env * \amp.kr;

	in = DelayL.ar(in, delaytime: 0.07);

	sign = PitchShift.ar(in, 0.1, ((In.kr(\freq.kr(1), 1).cpsmidi - \note.kr) + \bend.kr).midiratio.reciprocal, 0, 0.005);

	out = SelectX.ar(In.kr(\hasFreq.ir(0), 1).varlag(0.2),[PinkNoise.ar * Amplitude.kr(sign, 0.25,0.25);, sign]);

	Out.ar(\out.ir(0), out!2);
}).add;
)


(
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
		~fxGrp
	);
});

MIDIdef.noteOff(\noteOffTest, {
	arg vel, nn;
	~notes[nn].set(\gate, 0);
	~notes[nn] = nil;
});
)

// harmonizer
(
var table;
var mapped, mapped2, mapped3, diffbuf, diffbuf2, diffbuf3;
var difference, difference2, difference3;
var key, majKeySteps, minKeySteps, keySteps;

key = 1; // 0 -> (C), ..., 11 -> (B).

majKeySteps = [0, 0, 2, 2, 4, 5, 5, 7, 7, 9, 9, 11]; // Maj key steps

minKeySteps = [0, 0, 2, 3, 3, 5, 5, 7, 8, 8, 10, 10]; // Min key steps


// define a table of reference notes [c c# d ... b]
table = Array.fill(12, {arg i; i}); // [0,1,...,11]

mapped = ((key + minKeySteps) % 12).rotate(key);
mapped2 = mapped.rotate(-4);
mapped3 = mapped.rotate(-7);

difference = Array.fill(table.size, {0});
difference2= Array.fill(table.size, {0});
difference3= Array.fill(table.size, {0});

table.do({arg item, i;
	difference[i]  = (mapped[i]  - table[i]).midiratio;
	difference2[i] = (mapped2[i] - table[i]).midiratio;
	difference3[i] = (mapped3[i] - table[i]).midiratio;
});

diffbuf = Buffer.loadCollection(s,difference ,action:{|msg| msg.postln;});
diffbuf2= Buffer.loadCollection(s,difference2,action:{|msg| msg.postln;});
diffbuf3= Buffer.loadCollection(s,difference3,action:{|msg| msg.postln;});

// define the Synth itself:
// - first it determines the pitch of what it hears in the microphone
SynthDef.new(\pitchFollow1,{

    var in, amp, freq, hasFreq, out;
	var midiNoteRound;
	var harmony, harmony2, harmony3, partials;

	in = In.ar(\in.ir(0),1);

	amp = Amplitude.kr(in, 0.05, 1);

	// # freq, hasFreq = Pitch.kr(in);

	midiNoteRound = In.kr(~freqBus).cpsmidi.round(1);

	harmony = WrapIndex.kr(diffbuf.bufnum, midiNoteRound);
	harmony2= WrapIndex.kr(diffbuf2.bufnum, midiNoteRound);
	harmony3= WrapIndex.kr(diffbuf3.bufnum, midiNoteRound);


	partials = [
		harmony/2,
		harmony,
		harmony2,
		harmony3,
	];

	out = Mix.new(PitchShift.ar(in, 0.2, (partials.ratiomidi - In.kr(~freqBus).cpsmidi + midiNoteRound).midiratio, 0, 0.004));

	out = DelayL.ar(out, delaytime: 0.07);

	Out.ar(\out.ir(0),(out/partials.size)!2);

}).add;
)

~sound = Synth.new(\pitchFollow1, [\in, ~fxBus, \out, 0], ~fxGrp, \addToTail);

