part of entity;

class StreetSpiritFirebog extends StreetSpirit {
	StreetSpiritFirebog(String id, String streetName, String tsid, num x, num y, num z, num rotation, bool h_flip) : super(id, streetName, tsid, x, y, z, rotation, h_flip) {
		itemsPredefined = false;
		states = {
			"idle_cry":new Spritesheet("idle_cry", 'files/sprites/generated/converted/ss_firebog-idle_cry.png', 6792, 549, 283, 549, 24, false),
			"idle_move":new Spritesheet("idle_move", 'files/sprites/generated/converted/ss_firebog-idle_move.png', 6792, 549, 283, 549, 24, false),
			"open":new Spritesheet("open", 'files/sprites/generated/converted/ss_firebog-open.png', 5377, 549, 283, 549, 19, false),
			"close":new Spritesheet("close", 'files/sprites/generated/converted/ss_firebog-close.png', 4811, 549, 283, 549, 17, false),
			"talk":new Spritesheet("talk", 'files/sprites/generated/converted/ss_firebog-talk.png', 17546, 549, 283, 549, 62, false)
		};
		setState('idle_move');
	}

	void update({bool simulateTick: false}) {
		super.update();

		if(respawn != null && respawn.compareTo(new DateTime.now()) <= 0) {
			//if we just cried, we should say we're facing the other way
			//then we should start moving (that's why we turned around after all)
			if(currentState.stateName == 'idle_cry') {
				if (rand.nextInt(5) == 1) {
					facingRight = !facingRight;
					setState('idle_move');
					return;
				}
			} else {
				//sometimes use talk so that the blinking isn't predictable
				int roll = rand.nextInt(3);
				if(roll == 1) {
					setState('talk');
				} else {
					setState('idle_move');
					respawn = null;
				}
				return;
			}
		}
		if(respawn == null) {
			//sometimes move around
			int roll = rand.nextInt(20);
			if(roll == 3) {
				setState('idle_cry');
			}
		}
	}

	@override
	void buy({WebSocket userSocket, String email}) {
		setState('open');
		super.buy(userSocket: userSocket, email: email);
	}

	void sell({WebSocket userSocket, String email}) {
		setState('open');
		super.sell(userSocket:userSocket, email:email);
	}
}