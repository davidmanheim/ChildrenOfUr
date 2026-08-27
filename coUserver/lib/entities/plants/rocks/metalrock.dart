part of entity;

class MetalRock extends Rock {
	MetalRock(String id, num x, num y, num z, num rotation, bool h_flip, String streetName) : super(id, x, y, z, rotation, h_flip, streetName) {
		type = "Metal Rock";

		ItemRequirements itemReq = new ItemRequirements()
			..any = ['fancy_pick']
			..error = 'You need a special pick to mine harder rocks.';
		actions.singleWhere((Action a) => a.actionName == 'mine')
			..itemRequirements = itemReq
			..energyRequirements = new EnergyRequirements(energyAmount: 10);

		// Sprite sheet converted locally from the CC0 tinyspeck/glitch-items
		// source (harvestable_resources/rock_metal/rock_metal_1/rock_metal_1.swf)
		// via tools/build-sprite-sheet.py; see content/source-manifest.json for
		// provenance and content/runtime-manifest.json for the route entry.
		// This replaces the previous hardcoded link to the retired
		// childrenofur.com asset host. The source SWF's main timeline has 6
		// real frames (not the 5 the old hardcoded metadata implied); all 6
		// are used here rather than dropping one to match the old count.
		states =
		{
			"5-4-3-2-1" : new Spritesheet("5-4-3-2-1", "files/sprites/generated/converted/metalrock-5-4-3-2-1.png", 822, 101, 137, 101, 6, false)
		};
		setState('5-4-3-2-1');
		state = new Random().nextInt(currentState.numFrames);
		responses['mine_$type'] = [
			"Slave to the GRIND, kid! ROCK ON!",
			"I’d feel worse if I wasn’t under such heavy sedation.",
			"Sweet! Air pickaxe solo! C'MON!",
			"Yeah. Appetite for destruction, man. I feel ya.",
			"LET THERE BE ROCK!",
			"Those who seek true metal, we salute you!",
			"YEAH, man! You SHOOK me!",
			"All hail the mighty metal power of the axe!",
			"Metal, man! METAL!",
			"Wield that axe like a metal-lover, man!",
			"I Wanna Rock!"
		];
	}

	Future<bool> mine({WebSocket userSocket, String email}) async {
		bool success = await super.mine(userSocket:userSocket, email:email);

		if(success) {
			int miningLevel = await SkillManager.getLevel(Rock.SKILL, email);
			int qty = 1;
			if (miningLevel == 4) {
				qty = (rand.nextInt(3) == 3 ? 4 : 3);
			} else if (miningLevel >= 1) {
				qty = 2;
			}
			//give the player the 'fruits' of their labor
			await InventoryV2.addItemToUser(email, items['chunk_metal'].getMap(), qty, id);
		}

		return success;
	}
}