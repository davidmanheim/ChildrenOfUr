part of entity;

class DulliteRock extends Rock {
	DulliteRock(String id, num x, num y, num z, num rotation, bool h_flip, String streetName) : super(id, x, y, z, rotation, h_flip, streetName) {
		type = "Dullite Rock";

		// Sprite sheet converted locally from the CC0 tinyspeck/glitch-items
		// source (harvestable_resources/rock_dullite/rock_dullite_1/rock_dullite_1.swf)
		// via tools/build-sprite-sheet.py; see content/source-manifest.json for
		// provenance and content/runtime-manifest.json for the route entry. This
		// replaces the previous hardcoded link to the retired childrenofur.com
		// asset host. Like MetalRock, the source main timeline has 6 real frames
		// (not the 5 the old hardcoded metadata implied); all 6 are used here.
		// rock_dullite_1 of the 3 sibling numbered variant folders was used
		// arbitrarily as the representative source, matching the MetalRock
		// precedent; the other two were not converted in this pass.
		states =
		{
			"5-4-3-2-1" : new Spritesheet("5-4-3-2-1", "files/sprites/generated/converted/rock_dullite-5-4-3-2-1.png", 930, 118, 155, 118, 6, false)
		};
		setState('5-4-3-2-1');
		state = new Random().nextInt(currentState.numFrames);
		responses['mine_$type'] = [
			"Ooof. I feel lighter already.",
			"Mmm, thanks, I've been itching there all day.",
			"Ow. Ow-hangover. Ow-my-head. Ow.",
			"Not bad. Work on your backswing.",
			"You're really picking this up.",
			"Nothing wrong with a sedimentary lifestyle, chum.",
			"I should have been a wrestler. I'm rock-hard! Hee!",
			"Ah. You've taken a lode off my mind.",
			"You sure have an apatite for this.",
			"Woah. I'm tuff. But you're tuffer."
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
			await InventoryV2.addItemToUser(email, items['chunk_dullite'].getMap(), qty, id);
		}

		return success;
	}
}