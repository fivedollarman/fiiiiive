
Engine_Fivesynth : CroneEngine {

	var kernel;

	*new { arg context, doneCallback;
		^super.new(context, doneCallback);
	}

	alloc {
	
		kernel = Fivesynth.new(Crone.server);
		
	  this.addCommand(\trig, "sfff", { arg msg;
			var voiceKey = msg[1].asSymbol;
			var freq = msg[2];
			var amp = msg[3];
			var dur = msg[4];
			kernel.trigger(voiceKey,freq,amp,dur);
		});
		
		kernel.globalParams.keysValuesDo({ arg paramKey;
			this.addCommand(paramKey, "sf", {arg msg;
				kernel.setParam(msg[1].asSymbol,paramKey.asSymbol,msg[2]);
			});
		});
		
		this.addCommand(\free_all_notes, "", {
			kernel.freeAllNotes();
		});

		this.addCommand(\set_dry, "sf", { arg msg;
			var key = msg[1].asSymbol;
			var val = msg[2];
			kernel.setDry(key,val);
		});

		this.addCommand(\set_send, "sf", { arg msg;
			var key = msg[1].asSymbol;
			var val = msg[2];
			kernel.setSend(key,val);
		});

		this.addCommand(\set_main, "sf", { arg msg;
			var key = msg[1].asSymbol;
			var val = msg[2];
			kernel.setMain(key,val);
		});

	} // alloc

	free {
		kernel.freeAllNotes;
		kernel.voiceGroup.free;
	} // free


} // CroneEngine
