part of entity;

class Salmon extends NPC {
	Salmon(String id, num x, num y, num z, num rotation, bool h_flip, String streetName) : super(id, x, y, z, rotation, h_flip, streetName) {
		actions.add(
			new Action.withName('pocket')
				..actionWord = 'pocketing'
				..description = 'Put in pocket'
				..energyRequirements = new EnergyRequirements(energyAmount: 4)
		);
		type = "Salmon";
		renameable = true;
		speed = 35;
		ySpeed = 0;
		// Sprite sheets converted locally from the CC0 tinyspeck/glitch-items
		// source (inhabitants/salmon/npc_salmon.swf, DefineSprite 16, the
		// sole animated symbol in the file) via tools/build-sprite-sheet.py;
		// see content/source-manifest.json for provenance and
		// content/runtime-manifest.json for the route entry. These replace
		// the previous hardcoded links to the retired childrenofur.com asset
		// host. Every resolved real frame count exactly matched what was
		// already hardcoded here; only pixel dimensions changed.
		const String base = "files/sprites/generated/converted/salmon-";
		states = {
			"swimDown15": new Spritesheet("swimRightDown15", "${base}swimDown15.png", 1320, 41, 60, 41, 22, true),
			"swimDown30": new Spritesheet("swimRightDown30", "${base}swimDown30.png", 1320, 41, 60, 41, 22, true),
			"swimUp15": new Spritesheet("swimRightUp15", "${base}swimUp15.png", 1320, 41, 60, 41, 22, true),
			"swimUp30": new Spritesheet("swimRightUp30", "${base}swimUp30.png", 1320, 41, 60, 41, 22, true),
			"swim": new Spritesheet("swimRight", "${base}swim.png", 1320, 41, 60, 41, 22, true),
			"turn": new Spritesheet("turnRight", "${base}turn.png", 660, 41, 60, 41, 11, false),
			"gone": NPC.TRANSPARENT_SPRITE
		};
		setState("swim");
		//50/50 chance to face left or right to start
		facingRight = rand.nextInt(2) == 1;
	}

	void update({bool simulateTick: false}) {
		super.update();

		moveXY(yAction: () {
			y += ySpeed~/NPC.updateFps;
		}, ledgeAction: () {});

		if (respawn != null && respawn.compareTo(new DateTime.now()) <= 0) {
			// if we just turned, we should say we're facing the other way, then we should start moving (that's why we turned around after all)
			if (currentState.stateName == 'turn') {
				// if we turned left, we are no longer facing right, etc.
				facingRight = !facingRight;
				// start swimming left
				setState('swim');
			} else {
				//sometimes move around
				int roll = rand.nextInt(10);
				switch (roll) {
					case 0:
					case 1:
					// turn around
						setState('turn');
						ySpeed = 0;
						break;

					case 2:
					// swim up (steeply)
						setState('swimUp30');
						ySpeed = -75;
						break;

					case 3:
					// swim up (unholy)
						setState('swimUp15');
						ySpeed = -40;
						break;

					case 4:
					// swim down (steeply)
						setState('swimDown30');
						ySpeed = 75;
						break;

					case 5:
					// swim down (unholy)
						setState('swimDown15');
						ySpeed = 40;
						break;
				}
			}
		}
	}

	Future<bool> pocket({WebSocket userSocket, String email}) async {
		if (currentState == states['gone']) return false;
		bool success = await super.trySetMetabolics(email, energy: -4, imgMin: 1, imgRange: 5);
		if (!success) return false;

		// 50% chance to get a pocket salmon
		// 50% chance to let it slip out of your hands, you only catch a bubble
		if (new Random().nextInt(2) == 1) {
			await InventoryV2.addItemToUser(email, items['pocket_salmon'].getMap(), 1, id);
			StatManager.add(email, Stat.salmon_pocketed);
			setState("gone");
			respawn = new DateTime.now().add(new Duration(minutes: 2));
			return true;
		} else {
			await InventoryV2.addItemToUser(email, items['salmon_bubble'].getMap(), 1, id);
			say("You missed me, but you managed to grab a bubble.");
			return false;
		}
	}
}
