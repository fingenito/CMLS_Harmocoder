s.boot;
s.meter;

(

b = Buffer.read(s, PathName(thisProcess.nowExecutingPath).parentPath ++ "Api 3#30.aif");

// b = Buffer.read(s, PathName(thisProcess.nowExecutingPath).parentPath ++ "post.wav");

/*b.play;*/


SynthDef(\source, {
	var sig;
	sig = Select.ar(\choose.kr(0), [
		SoundIn.ar([0,1]),
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
    var in, out;

	in = In.ar(\in.ir(0),1);

	out = DelayC.ar(in, maxdelaytime: 0.2,  delaytime: SinOsc.kr({ExpRand(0.5, 2) * \modFreq.kr(0.25)}!4).range(0, {ExpRand(0.5, 2)*\modAmount.kr(0.02)}!4));

	out = Splay.ar(out);

	out = Mix.ar([in * (1 - \wet.kr(1)), out * \wet.kr(1)]) * 0.5;

	Out.ar(\out.ir(0), out);
}).add;


SynthDef(\reverb, { |roomsize, revtime, damping, inputbw, spread = 15, drylevel, earlylevel, taillevel|

	var in = In.ar(\in.ir(0),1);

	var out = GVerb.ar(
            in,
            roomsize,
            revtime,
            damping,
            inputbw,
            spread,
            drylevel.dbamp,
            earlylevel.dbamp,
            taillevel.dbamp,
            roomsize);

	out = RLPF.ar(out, \lPFreq.kr(6000));

	out = RHPF.ar(out, \hPFreq.kr(100));

	out = Splay.ar([in * (1 - \wet.kr(1)), out * \wet.kr(1)]) * 0.5;


	Out.ar(\out.ir(0), out);

}).add;


// harmonizer
SynthDef.new(\autoHarmonizer,{

	var table;
	var mapped, mapped2, mapped3, diffbuf, diffbuf2, diffbuf3;
	var difference, difference2, difference3;
	var key, majKeySteps, minKeySteps, keySteps;
	var in, amp, freq, hasFreq, out;
	var midiNoteRound;
	var harmony, harmony2, harmony3, partials;

	majKeySteps = [0, 0, 2, 2, 4, 5, 5, 7, 7, 9, 9, 11]; // Maj key steps

	minKeySteps = [0, 0, 2, 3, 3, 5, 5, 7, 8, 8, 10, 10]; // Min key steps

	if (\selectKey.kr(1), {
		keySteps = majKeySteps;
	},{
		keySteps = minKeySteps;
	});

	// define a table of reference notes [c c# d ... b]
	table = Array.fill(12, {arg i; i}); // [0,1,...,11]

	mapped = ((key + keySteps) % 12).rotate(\key.kr(0)); // 0 -> (C), ..., 11 -> (B).
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

	out = Mix.new(PitchShift.ar(in, 0.2, (partials.ratiomidi - In.kr(~freqBus).cpsmidi + midiNoteRound).midiratio, 0, 0.005));

	out = DelayL.ar(out, delaytime: 0.07);

	Out.ar(\out.ir(0),(out/partials.size)!2);

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

)

~chorus = Synth.new(\chorus, [\in, 3, \modFreq, 0.25, \modAmount, 0.02, \wet, 0.5, \out, 0]);

~reverb = Synth(\reverb, [\in, 3, \out, 0, \wet, 0.4, \roomsize, 80, \revtime, 2, \damping, 0.41, \inputbw, 0.8, \drylevel -500, \earlylevel, -18, \taillevel, 0]);

~sound = Synth.new(\autoHarmonizer, [\in, ~fxBus, \out, 0], ~fxGrp, \addToTail);

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
		~src = Synth.new(\source, [\out, ~srcBus], ~sourceGrp);
		~pitchTracker = Synth.new(\pitchTracker, [\in, ~srcBus, \freqBus, ~freqBus, \hasFreqBus, ~hasFreqBus], ~sourceGrp, \addToTail);
		~synthGrp = Group.after(~sourceGrp);
		~autoHarm = Synth.new(\autoHarmonizer, [\in, ~srcBus, \out, ~fxBus], ~synthGrp, \addToTail);
		~fxGrp = Group.after(~synthGrp);
		~reverb = Synth(\reverb, [\in, ~fxBus, \out, 0, \wet, 0.3, \roomsize, 80, \revtime, 2, \damping, 0.41, \inputbw, 0.8, \drylevel -500, \earlylevel, -18, \taillevel, 0], ~fxGrp, \addToTail);
		~chorus = Synth.new(\chorus, [\in, ~fxBus, \out, 0, \wet, 0.7, \modFreq, 0.25, \modAmount, 0.02], ~fxGrp, \addToTail);

	});
};
ServerTree.removeAll;
ServerTree.add(~setup);
)

Synth.new(\source, [\out, 0]);

// ____
~src.set(\choose, 1); // buffer
~src.set(\choose, 0); // audio in
// ____