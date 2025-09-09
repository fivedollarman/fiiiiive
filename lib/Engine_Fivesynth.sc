
Engine_Fivesynth : CroneEngine {

	var kernel;

	*new { arg context, doneCallback;
		^super.new(context, doneCallback);
	}

	alloc {
	
		kernel = Fivesynth.new(Crone.server);
		
	  this.addCommand(\trig, "sff", { arg msg;
			var voiceKey = msg[1].asSymbol;
			var freq = msg[2].asFloat;
			var amp = msg[3].asFloat;
			kernel.trigger(voiceKey,freq,amp);
		});
		
		kernel.globalParams.keysValuesDo({ arg paramKey;
			this.addCommand(paramKey, "sf", {arg msg;
				kernel.setParam(msg[1].asSymbol,paramKey.asSymbol,msg[2].asFloat);
			});
		});
		
		this.addCommand(\free_all_notes, "", {
			kernel.freeAllNotes();
		});

		this.addCommand(\set_level, "sf", { arg msg;
			var voiceKey = msg[1].asSymbol;
			var freq = msg[2].asFloat;
			kernel.setLevel(voiceKey,freq);
		});

		this.addCommand(\set_pan, "sf", { arg msg;
			var voiceKey = msg[1].asSymbol;
			var freq = msg[2].asFloat;
			kernel.setPan(voiceKey,freq);
		});

		this.addCommand(\set_main, "sf", { arg msg;
			var key = msg[1].asSymbol;
			var val = msg[2].asFloat;
			kernel.setMain(key,val);
		});

	} // alloc

	free {
		kernel.freeAllNotes;
		kernel.voiceGroup.free;
	} // free


} // CroneEngine
