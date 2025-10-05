
Fivesynth {

  classvar <voiceKeys;

  var <globalParams;
  var <voiceParams;
  var <voiceGroup;
  var <singleVoices;
  var <g;
  var <synths;
  var <busses;

	*new {
		^super.new.init();
	}

	init {

		var s = Server.default;

		synths = Dictionary.new;
		busses = Dictionary.new;

		voiceKeys = [ \1, \2, \3, \4, \5 ];

		g = Group.new(s);

		voiceGroup = Group.head(g);

		globalParams = Dictionary.newFrom([
			\sub_div, 2,
			\noise_amp, 0,
			\coef, 0.75,
			\attack, 0,
			\release, 0.125,
			\slew, 0.5;
		]);

		singleVoices = Dictionary.new;
		voiceParams = Dictionary.new;
		voiceKeys.do({ arg voiceKey;
			singleVoices[voiceKey] = Group.head(voiceGroup);
			voiceParams[voiceKey] = Dictionary.newFrom(globalParams);
		});

		Routine {

			busses[\main_out] = Bus.audio(s, 2);
			busses[\delay_send] = Bus.audio(s, 2);
			busses[\synth] = Bus.audio(s, 1);

			SynthDef(\Fivesynth, {
					arg out, dur, stopGate = 1, freq,
					freqQ, filtQ, sub_div, coef,
					attack, release, amp, noise_amp,
					slew;

					var slewed_freq = freq.lag3(slew);
				  var plu = Pluck.ar(WhiteNoise.ar(amp/4), Trig.kr(amp*4,0.05), 8.reciprocal, (slewed_freq * freqQ).reciprocal, (dur*4)+release, (coef + (freq.reciprocal*(64*(1-coef)))).clip(-0.965, 0.965));
				    var sub = SinOsc.ar(slewed_freq/sub_div, 1pi, freq.reciprocal);
					var noise = WhiteNoise.ar(mul: noise_amp.lag3(slew));
				var mix = LPF.ar(Mix.ar([plu,sub,noise]), filtQ * slewed_freq);

					var envelope = EnvGen.kr(
						envelope: Env.linen(attackTime: attack, sustainTime: dur/4, releaseTime: release, level: 1), gate: stopGate, doneAction: 2);
					Out.ar(out, mix * envelope * 0.5);
			}).send(s);

			// define patch synths, to control stereo field:
			SynthDef.new(\patch_pan, {
				arg pan, lfof=0.25, lfoa=0.5;
				var lfo = SinOsc.kr(lfof, 0pi, lfoa, pan.neg*lfoa);
				Out.ar(\out.kr, Pan2.ar(In.ar(\in.kr), pan + lfo, \level.kr(1)));
			}).send(s);

			SynthDef.new(\patch_main, {
				var src = In.ar(\in.kr, 2);
				var fc1 = \fc1.kr(600);
				var fc2 = \fc2.kr(1800);
				var ampLo = \ampLo.kr(1);
				var ampMid = \ampMid.kr(1);
				var ampHi = \ampHi.kr(1);
				var lo = LPF.ar(LPF.ar(src, fc1), fc1) * ampLo;
				var mid = HPF.ar(HPF.ar(LPF.ar(LPF.ar(src, fc2), fc2), fc1), fc1) * ampMid;
				var hi = HPF.ar(HPF.ar(src, fc2), fc2) * ampHi;
				var mix = (lo + mid + hi) * \gain.kr(1);
				var cli = mix.distort.tanh;
				Out.ar(\out.kr, cli * \level.kr(1));
			}).send(s);

			s.sync;

			synths[\dry] = Synth.new(\patch_pan,
				target:voiceGroup, addAction:\addAfter, args:[
					\in, busses[\synth],
					\out, busses[\main_out],
					\level, 0.0
			]);

			synths[\delay_send] = Synth.new(\patch_pan,
				target:voiceGroup, addAction:\addAfter, args:[
					\in, busses[\synth],
					\out, busses[\delay_send],
					\level, 0.0
			]);

			synths[\delay] = SynthDef.new(\delay, {
				arg in, out, lfof=0.025, lfoa=0.003, delay=0.2, decay=5, level=1;
			    var lfo = LFNoise2.kr(lfof, lfoa);
				Out.ar(out, CombL.ar(In.ar(in, 2), 2, delay + lfo, decay, level));
			}).play(target:synths[\delay_send], addAction:\addAfter, args:[
				\in, busses[\delay_send], \out, busses[\main_out]
			]);

			synths[\main_out] = Synth.new(\patch_main,
				target:g, addAction:\addToTail, args: [
					\in, busses[\main_out], \out, 0
			]);

		}.play;
	}

	playVoice { arg voiceKey, freq, amp, dur;
		singleVoices[voiceKey].set(\stopGate, -1.05);
		Synth.new(\Fivesynth,
			target:singleVoices[voiceKey], addAction:\addToHead,
			args: [\freq, freq, \amp, amp, \dur, dur, \out, busses[\synth]] ++ voiceParams[voiceKey].getPairs);
	}

	trigger { arg voiceKey, freq, amp, dur;
		if( voiceKey == 'all',{
			voiceKeys.do({ arg vK;
				this.playVoice(vK, freq, amp, dur);
			});
		},
		{
			this.playVoice(voiceKey, freq, amp, dur);
		});
	}

	adjustVoice { arg voiceKey, paramKey, paramValue;
		singleVoices[voiceKey].set(paramKey, paramValue);
		voiceParams[voiceKey][paramKey] = paramValue
	}

	setParam { arg voiceKey, paramKey, paramValue;
		if( voiceKey == 'all',{
			voiceKeys.do({ arg vK;
				this.adjustVoice(vK, paramKey, paramValue);
			});
		},
		{
			this.adjustVoice(voiceKey, paramKey, paramValue);
		});
	}

	freeAllNotes {
		voiceGroup.set(\stopGate, -1.05);
	}

	setDry { arg key, val;
		synths[\dry].set(key, val);
	}

	setSend { arg key, val;
		synths[\delay_send].set(key, val);
	}

	setMain { arg key, val;
		synths[\main_out].set(key, val);
	}

	free {
	  voiceGroup.free;
		busses.do({arg bus; bus.free;});
	}

}
