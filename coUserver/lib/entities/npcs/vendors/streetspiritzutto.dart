part of entity;

class StreetSpiritZutto extends StreetSpirit {
	StreetSpiritZutto(String id, String streetName, String tsid, num x, num y, num z, num rotation, bool h_flip) : super(id, streetName, tsid, x, y, z, rotation, h_flip) {
		speed = 0;
		itemsPredefined = false;
		states = {
			"hoverIdle":new Spritesheet("hoverIdle", 'files/sprites/generated/converted/ss_zutto-hoverIdle.png', 1955, 61, 85, 61, 23, true),
			"groundIdle":new Spritesheet("groundIdle", 'files/sprites/generated/converted/ss_zutto-groundIdle.png', 2040, 61, 85, 61, 24, true),
			"raise":new Spritesheet("raise", 'files/sprites/generated/converted/ss_zutto-raise.png', 2635, 61, 85, 61, 31, false),
			"lower":new Spritesheet("lower", 'files/sprites/generated/converted/ss_zutto-lower.png', 2210, 61, 85, 61, 26, false),
			"hoverTalk":new Spritesheet("hoverTalk", 'files/sprites/generated/converted/ss_zutto-hoverTalk.png', 3910, 61, 85, 61, 46, true)
		};
		setState('groundIdle');
	}

	@override
	void update({bool simulateTick: false}) {
		super.update();

		if(respawn != null && respawn.compareTo(new DateTime.now()) <= 0) {
			setState('groundIdle');
			respawn = null;
			return;
		}
		if (respawn == null) {
			if(rand.nextInt(4) == 4) {
				// 20% chance to stand up for 5 seconds
				setState('hoverIdle');
			}
		}
	}

	@override
	void buy({WebSocket userSocket, String email}) {
		setState("raise");
		super.buy(userSocket:userSocket, email:email);
	}

	@override
	void sell({WebSocket userSocket, String email}) {
		setState("raise");
		super.sell(userSocket:userSocket, email:email);
	}

	@override
	void close({WebSocket userSocket, String email}) {
		openCount -= 1;
		//if no one else has them open
		if(openCount <= 0) {
			openCount = 0;
			setState("lower");
		}
	}
}