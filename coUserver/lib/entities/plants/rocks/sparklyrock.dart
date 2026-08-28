part of entity;

class SparklyRock extends Rock {
	SparklyRock(String id, num x, num y, num z, num rotation, bool h_flip, String streetName) : super(id, x, y, z, rotation, h_flip, streetName) {
		type = "Sparkly Rock";

		// Sprite sheet converted locally from the CC0 tinyspeck/glitch-items
		// source (harvestable_resources/rock_sparkly/rock_sparkly_1/rock_sparkly_1.swf)
		// via tools/build-sprite-sheet.py; see content/source-manifest.json for
		// provenance and content/runtime-manifest.json for the route entry. This
		// replaces the previous hardcoded link to the retired childrenofur.com
		// asset host. Like MetalRock, the source main timeline has 6 real frames
		// (not the 5 the old hardcoded metadata implied); all 6 are used here.
		// rock_sparkly_1 of the 3 sibling numbered variant folders was used
		// arbitrarily as the representative source, matching the MetalRock
		// precedent; the other two were not converted in this pass.
		states =
		{
			"5-4-3-2-1" : new Spritesheet("5-4-3-2-1", "files/sprites/generated/converted/rock_sparkly-5-4-3-2-1.png", 930, 130, 155, 130, 6, false)
		};
		setState('5-4-3-2-1');
		state = new Random().nextInt(currentState.numFrames);

		responses['mine_$type'] = [
			"You rock my world!",
			"I've taken a shine to you.",
			"Here! What's mined is yours!",
			"Pick me! Pick me!",
			"I sparkle! You sparkle! Sparkles!",
			"Oooh, you're cute. You into carbon-dating?",
			"Oh yeah! Who's your magma?!?",
			"Yay! You picked me!",
			"Hey, cutestuff! You make me sliver.",
			"You crack me up, Urchin!",
			"Yay! Everything should sparkle! Except maybe vampires.",
			"Together, we'll make the world sparkly, Urling!"
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
			await InventoryV2.addItemToUser(email, items['chunk_sparkly'].getMap(), qty, id);
		}

		return success;
	}
}
