part of entity;

class DirtPile extends Plant {
	DirtPile(String id, num x, num y, num z, num rotation, bool h_flip, String streetName) : super(id, x, y, z, rotation, h_flip, streetName) {
		actionTime = 3000;
		type = "Dirt Pile";

		ItemRequirements itemReq = new ItemRequirements()
			..any = ['shovel', 'ace_of_spades'];
		actions.add(
			new Action.withName('dig')
				..actionWord = 'digging'
				..timeRequired = actionTime
				..energyRequirements = new EnergyRequirements(energyAmount: 8)
				..itemRequirements = itemReq
		);
		// Sprite sheets converted locally from the CC0 tinyspeck/glitch-items
		// source (harvestable_resources/dirt_pile/dirt_pile.swf) via
		// tools/build-sprite-sheet.py; see content/source-manifest.json for
		// provenance and content/runtime-manifest.json for the route entry.
		// This replaces the previous hardcoded links to the retired
		// childrenofur.com asset host. The source has two undifferentiated
		// 11-frame DefineSprite variants (char ids 23 and 24, no distinguishing
		// frame labels or export names); they were assigned to maturity_1/2 in
		// the order ffdec exported them. Both frame counts (11) and dimensions
		// (195x71) match the previously hardcoded values exactly.
		states = {
			"maturity_1": new Spritesheet(
				"maturity_1",
				"files/sprites/generated/converted/dirt_pile-maturity_1.png",
				2145,
				71,
				195,
				71,
				11,
				false),
			"maturity_2": new Spritesheet(
				"maturity_2",
				"files/sprites/generated/converted/dirt_pile-maturity_2.png",
				2145,
				71,
				195,
				71,
				11,
				false)
		};
		int maturity = new Random().nextInt(states.length) + 1;
		setState('maturity_$maturity');
		state = new Random().nextInt(currentState.numFrames);
		maxState = 0;
	}

	@override
	void update({bool simulateTick: false}) {
		if (state >= currentState.numFrames) {
			setActionEnabled("dig", false);
		}

		if (respawn != null && new DateTime.now().compareTo(respawn) >= 0) {
			state = 0;
			setActionEnabled("dig", true);
			respawn = null;
		}

		if (state < maxState) {
			state = maxState;
		}
	}

	Future<bool> dig({WebSocket userSocket, String email}) async {
		//make sure the player has a shovel that can dig this dirt
		Action digAction = actions.singleWhere((Action a) => a.actionName == 'dig');
		List<String> types = digAction.itemRequirements.any;
		bool success = await InventoryV2.decreaseDurability(email, types);
		if(!success) {
			return false;
		}

		success = await trySetMetabolics(email, energy: -8, imgMin: 10, imgRange: 5);
		if (!success) {
			return false;
		}

		state++;
		if (state >= currentState.numFrames) {
			respawn = new DateTime.now().add(new Duration(minutes: 2));
		}

		//give the player the 'fruits' of their labor
		await InventoryV2.addItemToUser(email, items['earth'].getMap(), 1, id);

		//1 in 10 chance to get a lump of loam as well
		if (new Random().nextInt(10) == 5) {
			await InventoryV2.addItemToUser(email, items['loam'].getMap(), 1, id);
		}

		StatManager.add(email, Stat.dirt_dug).then((int dug) {
			if (dug >= 503) {
				Achievement.find("dirt_diggler").awardTo(email);
			} else if (dug >= 251) {
				Achievement.find("dirtomancer").awardTo(email);
			} else if (dug >= 127) {
				Achievement.find("loamist").awardTo(email);
			} else if (dug >= 61) {
				Achievement.find("dirt_monkey").awardTo(email);
			} else if (dug >= 29) {
				Achievement.find("shovel_jockey").awardTo(email);
			}
		});

		return true;
	}
}
