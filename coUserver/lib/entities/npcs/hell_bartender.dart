part of entity;

class HellBartender extends NPC {
	HellBartender(String id, num x, num y, num z, num rotation, bool h_flip, String streetName) : super(id, x, y, z, rotation, h_flip, streetName) {
		type = "Hell Bartender";
		actionTime = 0;
		speed = 0;
		actions = [
			new Action.withName('glass of wine')
				..timeRequired = actionTime
				..enabled = true
				..actionWord = 'wine',
			new Action.withName('pint of beer')
				..timeRequired = actionTime
				..enabled = true
				..actionWord = 'beer'
		];
		states = {
			"idle1": new Spritesheet(
				"idle1",
				"files/sprites/generated/converted/hell_bartender-idle1.png",
				20169, 206, 249, 206, 81, true
			),
			"idle2": new Spritesheet(
				"idle2",
				"files/sprites/generated/converted/hell_bartender-idle2.png",
				21663, 206, 249, 206, 87, false
			),
			"talk_left": new Spritesheet(
				"talk_left",
				"files/sprites/generated/converted/hell_bartender-talk_left.png",
				27390, 206, 249, 206, 110 , false
			),
			"talk_right_out": new Spritesheet(
				"talk_right_out",
				"files/sprites/generated/converted/hell_bartender-talk_right_out.png",
				1743, 206, 249, 206, 7 , false
			),
			"talk_right": new Spritesheet(
				"talk_right",
				"files/sprites/generated/converted/hell_bartender-talk_right.png",
				25647, 206, 249, 206, 103 , false
			)
		};
		setState("idle1");
	}

	@override
	update({bool simulateTick: false}) {
		if (respawn != null && new DateTime.now().isAfter(respawn)) {
			if (rand.nextInt(3) == 1) {
				setState('idle2');
			} else {
				setState('idle1');
			}
		}
	}

	Future glassOfWine({String email, WebSocket userSocket}) async {
		setState('talk_right', thenState: 'talk_right_out');
		say("I'm still setting up shop. Come back soon.");
	}

	Future pintOfBeer({String email, WebSocket userSocket}) async {
		setState('talk_right', thenState: 'talk_right_out');
		say("I'm still setting up shop. Come back soon.");
	}
}
