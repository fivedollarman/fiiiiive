
Fivesynth {

  classvar <voiceKeys;

  var <globalParams;
	var <voiceParams;
	var <voiceGroup;
	var <singleVoices;

	var <synths;
	var <busses;
	var <g;
	
	*initClass {

		voiceKeys = [ \1, \2, \3, \4, \5 ];
		
		StartUp.add {
			var s = Server.default;

			s.waitForBoot {

				SynthDef(\Fivesynth, {
					arg out = 0, stopGate = 1,
					freq, sub_div,
					cutoff, resonance, cutoff_env,
					attack, release,
					amp, noise_amp, pan,
					freq_slew, amp_slew, noise_slew, pan_slew;

					var slewed_freq = freq.lag3(freq_slew);
					var pulse = Pulse.ar(freq: slewed_freq);
					var saw = Saw.ar(freq: slewed_freq);
					var sub = Pulse.ar(freq: slewed_freq/sub_div);
					var noise = WhiteNoise.ar(mul: noise_amp.lag3(noise_slew));
					var mix = Mix.ar([pulse,saw,sub,noise]);

					var envelope = EnvGen.kr(
						envelope: Env.perc(attackTime: attack, releaseTime: release, level: 1),
						gate: stopGate,
						doneAction: 2
					);
					var filter = MoogFF.ar(
						in: mix,
						freq: Select.kr(cutoff_env > 0, [cutoff, cutoff * envelope]),
						gain: resonance
					);
					var signal = Pan2.ar(filter*envelope,pan.lag3(pan_slew));
					Out.ar(out, signal * amp.lag3(amp_slew) * 0.25);
				}).add;
			}
		}
	}

	*new {
		^super.new.init();
	}

	init {
		var s = Server.default;
		
		synths = Dictionary.new;
		busses = Dictionary.new;
		
		voiceGroup = Group.new(s);
		
		globalParams = Dictionary.newFrom([
			\freq, 400,
			\sub_div, 2,
			\noise_amp, 0.1,
			\cutoff, 8000,
			\cutoff_env, 1,
			\resonance, 3,
			\attack, 0,
			\release, 0.4,
			\amp, 0.5,
			\pan, 0,
			\freq_slew, 0.0,
			\amp_slew, 0.05,
			\noise_slew, 0.05,
			\pan_slew, 0.5;
		]);
		
		singleVoices = Dictionary.new;
		voiceParams = Dictionary.new;
		voiceKeys.do({ arg voiceKey;
			singleVoices[voiceKey] = Group.new(voiceGroup);
			voiceParams[voiceKey] = Dictionary.newFrom(globalParams);
		});

		Routine {

			busses[\source] = Bus.audio(s, 1);
			busses[\main_out] = Bus.audio(s, 2);
			busses[\reverb_send] = Bus.audio(s, 2);
			busses[\delay_send] = Bus.audio(s, 2);

			// define patch synths, to control stereo field:
			SynthDef.new(\patch_pan, {
				Out.ar(\out.kr, Pan2.ar(In.ar(\in.kr), \pan.kr(0), \level.kr(1)));
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

				var mix = lo + mid + hi;

				Out.ar(\out.kr, mix * \level.kr(1));
			}).send(s);

			s.sync;

      g = Group.new(s);

			// instantiate main synth:
			synths[\source] = Synth.new(\Fivesynth,
				target:g, addAction:\addToHead, args:[
					\out, busses[\source]
			]);

			synths[\dry] = Synth.new(\patch_pan,
				target:synths[\source], addAction:\addAfter, args:[
					\in, busses[\source],
					\out, busses[\main_out],
					\level, 1.0
			]);

			synths[\delay_send] = Synth.new(\patch_pan,
				target:synths[\source], addAction:\addAfter, args:[
					\in, busses[\source],
					\out, busses[\delay_send],
					\level, 0.0
			]);

			synths[\delay] = SynthDef.new(\delay, {
				arg in, out, level=1;
				Out.ar(out, DelayC.ar(In.ar(in, 2), 1.0, 0.2, level));
			}).play(target:synths[\delay_send], addAction:\addAfter, args:[
				\in, busses[\delay_send], \out, busses[\main_out]
			]);

			synths[\main_out] = Synth.new(\patch_main,
				target:g, addAction:\addToTail, args: [
					\in, busses[\main_out], \out, 0
			]);

		}.play;
	}
	
	playVoice { arg voiceKey, freq, amp;
		singleVoices[voiceKey].set(\stopGate, -1.05);
		voiceParams[voiceKey][\freq] = freq;
		voiceParams[voiceKey][\amp] = amp;
		Synth.new(\Fivesynth, [\freq, freq, \amp, amp] ++ voiceParams[voiceKey].getPairs, singleVoices[voiceKey]);
	}

	trigger { arg voiceKey, freq, amp;
		if( voiceKey == 'all',{
			voiceKeys.do({ arg vK;
				this.playVoice(vK, freq, amp);
			});
		},
		{
			this.playVoice(voiceKey, freq, amp);
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

	setLevel { arg key, val;
		synths[key].set(\level, val);
	}

	setPan { arg key, val;
		synths[key].set(\pan, val);
	}

	setHz { arg val;
		synths[\source].set(\hz, val);
	}

	free {
	  voiceGroup.free;
		g.free;
		busses.do({arg bus; bus.free;});
	}

}
