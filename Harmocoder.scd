s.boot;
s.meter;

MIDIClient.init;
MIDIIn.connectAll;


b = Buffer.read(s, PathName(thisProcess.nowExecutingPath).parentPath ++ "post.wav");

b.play;

var bufferPost = PlayBuf.ar(1!2, b, loop:1);

// pitch shift input - USE HEADPHONES to prevent feedback.
(play({
	PitchShift.ar(
        AudioIn.ar([1,2]), // stereo audio input
        0.1,               // grain size
        MouseX.kr(0.5,2),  // mouse x controls pitch shift ratio
		0,                 // pitch dispersion
		0.004              // time dispersion
    )
}))

~notes = Array.newClear(128);

(
MIDIdef.noteOn(\noteOnTest, {
	arg vel, nn;
	~notes[nn] = Synth.new(\midiHarm,
		[
			\note, nn,
			\amp, vel.linexp(1,127,0.01,0.3),
			\gate, 1,
		]
	);
});
)

(
MIDIdef.noteOff(\noteOffTest, {
	arg vel, nn;
	~notes[nn].set(\gate, 0);
	~notes[nn] = nil;
});
)

(
MIDIdef.bend(\bendTest, {
	arg val, chan, src;
	/*~bend = val;*/
	[val, chan, src].postln;
});
)

~bend =

(
SynthDef.new(\midiHarm , {
	arg note, amp, gate = 1, bend = 0;
	var in, freq, hasFreq, midiNoteSang, poll, env, out;

	var bufferPost = PlayBuf.ar(1!2, b, loop:1);

	/*in = Mix.new(bufferPost); // stereo audio input*/
	in = SoundIn.ar([0]); // stereo audio input

	# freq, hasFreq = Pitch.kr(in);
	midiNoteSang = freq.cpsmidi.round(1);

/*	poll = Poll.kr(Impulse.kr(5), (midiNoteSang - note).midiratio.reciprocal, 0, {
		arg val;
		val.postln;  // Stampa la frequenza su console
		0;  // Resetta l'oggetto Poll
	});*/

	env = EnvGen.kr(Env.adsr, gate, doneAction:2);

    out = PitchShift.ar(
        in, // stereo audio input
        0.1,               // grain size
		((midiNoteSang - note) + bend).midiratio.reciprocal,  // mouse x controls pitch shift ratio
		0,                 // pitch dispersion
		0.005              // time dispersion
    );

	out = out * env;

	Out.ar(0,out);
	Out.ar(1,out);

}).add;
)




// harmonizer
(
var table;
var mapped, mapped2, mapped3, diffbuf, diffbuf2, diffbuf3;
var miditoname;
var nametomidi;
var sound;
var difference, difference2, difference3;
var key, majKeySteps, minKeySteps, keySteps;
var createKey;
var diffBtwC4;

key = 60; // 60 -> (C4), ..., 71 -> (B4).

diffBtwC4 = key - 60;

majKeySteps = [0, 0, 2, 2, 4, 5, 5, 7, 7, 9, 9, 11]; // Maj key steps

minKeySteps = [0, 0, 2, 3, 3, 5, 5, 7, 8, 8, 10, 10]; // Min key steps



// define a function to convert a midi note number to a midi note name
miditoname = ({ arg note = 60, style = \American ;
		var offset = 0 ;
		var midi, notes;
		case { style == \French } { offset = -1}
			{ style == \German } { offset = -3} ;
		midi = (note + 0.5).asInteger;
		notes = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"];

		(notes[midi%12] ++ (midi.div(12)-1+offset))
});

// define a function to convert a midi note name to a midi note number
nametomidi = ({ arg name = "C4", style = \American ;
		var offset = 0 ; // French usage: +1 ; German usage: +3
		var twelves, ones, octaveIndex, midis;

		case { style == \French } { offset = 1}
			{ style == \German } { offset = 3} ;

		midis = Dictionary[($c->0),($d->2),($e->4),($f->5),($g->7),($a->9),($b->11)];
		ones = midis.at(name[0].toLower);

		if( (name[1].isDecDigit), {
			octaveIndex = 1;
		},{
			octaveIndex = 2;
			if( (name[1] == $#) || (name[1].toLower == $s) || (name[1] == $+), {
				ones = ones + 1;
			},{
				if( (name[1] == $b) || (name[1].toLower == $f) || (name[1] == $-), {
					ones = ones - 1;
				});
			});
		});
		twelves = (name.copyRange(octaveIndex, name.size).asInteger) * 12;

		(twelves + 12 + ones + (offset*12))
});

// define a table of reference notes [c c# d ... b]
table = Array.fill(12, {arg i; i + 60}); // [60,61,...,71]

mapped = (key + majKeySteps).rotate(diffBtwC4);
mapped2 = mapped.rotate(-4);
mapped3 = mapped.rotate(-7);


// define a table to store the difference between reference and mapped note
difference = Array.fill(table.size, {0});
difference2= Array.fill(table.size, {0});
difference3= Array.fill(table.size, {0});


table.do({arg item, i;
	difference3[i] = (table[i] - mapped3[i]).midiratio.reciprocal;
	difference2[i] = (table[i] - mapped2[i]).midiratio.reciprocal;
	difference[i] = (table[i] - mapped[i]).midiratio.reciprocal;
});


diffbuf= Buffer.loadCollection(s,difference,action:{|msg| msg.postln;});
diffbuf2= Buffer.loadCollection(s,difference2,action:{|msg| msg.postln;});
diffbuf3= Buffer.loadCollection(s,difference3,action:{|msg| msg.postln;});



// define the Synth itself:
// - first it determines the pitch of what it hears in the microphone
SynthDef.new(\pitchFollow1,{

    var in, amp, freq, hasFreq, out;
	var t, midiNoteRound;
	var harmony, harmony2, harmony3, partials;
	var poll;
	var startFreq = 261.63; // (C4)
    var freqEnv;
	var isLow;
	var isHigh;

	var midiNoteReal,autoTuneRatio;

	var freqEnvArray = Array.newClear(0);


	// Iterazione attraverso le note della scala cromatica
	12.do({ |i|
		var currentFreq = startFreq * (2 ** (i / 12)); // Calcolo della frequenza corrente

		// Aggiunta della coppia di valori corrente all'array
		freqEnvArray = freqEnvArray.add([i, currentFreq]);

		// Aggiunta di un punto intermedio tra ogni coppia di punti
		/*freqEnvArray = freqEnvArray.add([i + 0.99, currentFreq]);*/
	});


	// Conversione dell'array in un inviluppo utilizzabile
	/*freqEnv = EnvGen.kr(Env.pairs(freqEnvArray), doneAction: 2);*/

    in = Mix.new(SoundIn.ar([0,1]));
	/*in = Mix.new(bufferPost);*/
	amp = Amplitude.kr(in, 0.05, 1);
    /*# freq, hasFreq = Pitch.kr(SinOsc.ar(freqEnv));*/
	# freq, hasFreq = Pitch.kr(in);
	/*# freq, hasFreq = ZeroCrossing.kr(in); //In case of CPU overload*/

	midiNoteReal = freq.cpsmidi;

	midiNoteRound = freq.cpsmidi.round(1);

	autoTuneRatio = (midiNoteReal - midiNoteRound);

	//

/*    freqQuant = midiNoteRound.midicps;*/
	harmony = WrapIndex.kr(diffbuf.bufnum, midiNoteRound);
	harmony2= WrapIndex.kr(diffbuf2.bufnum, midiNoteRound);
	harmony3= WrapIndex.kr(diffbuf3.bufnum, midiNoteRound);


/*		// Inizializza l'oggetto Poll
	poll = Poll.kr(Impulse.kr(5), [freq.cpsmidi, hasFreq], 0, {
		arg val;
		val.postln;  // Stampa la frequenza su console
		0;  // Resetta l'oggetto Poll
	});*/

	partials = [
/*		1,*/
		0.5 * harmony,
		harmony,
		harmony2,
		harmony3,

	];



/*	isLow = autoTuneRatio < 0.5;
	isHigh = autoTuneRatio > 0.5;


	/*partials = partials - (autoTuneRatio - 1);*/

	if (
		isLow,
		{"sotto".postln},
		{"sopra".postln}
	);*/
		/*partials = (partials.reciprocal.ratiomidi - autoTuneRatio.ratiomidi).midiratio.reciprocal;*/
		/*partials = (partials.reciprocal.ratiomidi + (1 - autoTuneRatio.ratiomidi)).midiratio.reciprocal;*/

	out = Mix.new(PitchShift.ar(in, 0.2, partials, 0, 0.004));
	/*out = Mix.new(PitchShift.ar(LFTri.ar(freqEnv), 0.1, partials, 0, 0.05));*/

   /* 7.do({
		out = AllpassN.ar(out, 0.040, [0.040.rand,0.040.rand], 2)
    });*/

	Out.ar(~distortionBus,(out/partials.size));
	// Out.ar([0,1],(out/partials.size));



}).add;

)


// Crea un bus audio per collegare l'uscita del synth pitchFollow con il plugin VST3
~distortionBus = Bus.audio(s, 2);

// Definisci il synth per il plugin di distorsione VST3
(SynthDef(\distortion, {|in, out|
	var sound = In.ar(in, 2);
	ReplaceOut.ar(out, VSTPlugin.ar(sound, 2, id: \distortion));
	// Out.ar(out,Pan2.ar(VSTPlugin.ar(sound, 2, id: \distortion), 0));

	// Out.ar(out,VSTPlugin.ar(sound, 2, id: \distortion));
}).add;
)
// Apri il plugin VST3 di distorsione
~distortion = VSTPluginController(Synth(\distortion, [\in, ~distorsionBus, \out, [2,3]]), id: \distortion);
~distortion.open("C:/Program Files/Common Files/VST3/Distortion_Effect.vst3", editor:true, verbose:true);


~distortion.editor;
~distortion.gui;






~sound = Synth.new(\pitchFollow1);



s.plotTree;
s.scope;


(
~sound.free;
~distortion.close;
)

VSTPlugin.search;



