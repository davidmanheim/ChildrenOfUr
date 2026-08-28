part of entity;

class BerylRock extends Rock {
	BerylRock(String id, num x, num y, num z, num rotation, bool h_flip, String streetName) : super(id, x, y, z, rotation, h_flip, streetName) {
		type = "Beryl Rock";

		// Sprite sheet converted locally from the CC0 tinyspeck/glitch-items
		// source (harvestable_resources/rock_beryl/rock_beryl_1/rock_beryl_1.swf)
		// via tools/build-sprite-sheet.py; see content/source-manifest.json for
		// provenance and content/runtime-manifest.json for the route entry. This
		// replaces the previous hardcoded link to the retired childrenofur.com
		// asset host. Like MetalRock, the source main timeline has 6 real frames
		// (not the 5 the old hardcoded metadata implied); all 6 are used here.
		// rock_beryl_1 of the 3 sibling numbered variant folders was used
		// arbitrarily as the representative source, matching the MetalRock
		// precedent; the other two were not converted in this pass.
		states =
		{
			"5-4-3-2-1" : new Spritesheet("5-4-3-2-1", "files/sprites/generated/converted/rock_beryl-5-4-3-2-1.png", 930, 123, 155, 123, 6, false)
		};
		setState('5-4-3-2-1');
		state = new Random().nextInt(currentState.numFrames);
		responses['mine_$type'] = [
			"Hey! To the left a little next time.",
			"Ughh, you're so frikkin' picky.",
			"I wasn't cut out for this.",
			"Not in the face! Oh. Wait. No face.",
			"If you need any tips on technique, just axe.",
			"Pick on someone else, will you?",
			"You're on rocky ground, Urchin.",
			"I feel like you're taking me for granite.",
			"Well, at least that's a weight off me mined.",
			"You sure have one big axe to grind."
		];
	}

	Future<bool> mine({WebSocket userSocket, String email}) async {
		bool success = await super.mine(userSocket:userSocket, email:email);

		if(success) {
			int miningLevel = await SkillManager.getLevel(Rock.SKILL, email);
			int qty = 1;
			if (miningLevel == 4) {
				qty = (rand.nextInt(3) == 3 ? 3 : 2);
			} else if (miningLevel >= 1) {
				qty = 2;
			}
			//give the player the 'fruits' of their labor
			await InventoryV2.addItemToUser(email, items['chunk_beryl'].getMap(), qty, id);
		}

		return success;
	}
}
