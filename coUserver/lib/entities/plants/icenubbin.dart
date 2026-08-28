part of entity;

class IceNubbin extends Plant {
	IceNubbin (String id, num x, num y, num z, num rotation, bool h_flip, String streetName) : super(id, x, y, z, rotation, h_flip, streetName) {
		actionTime = 2000;
		type = "Ice Nubbin";

		ItemRequirements itemReq = new ItemRequirements()
			..any = ['scraper', 'super_scraper'];
		EnergyRequirements energyReq = new EnergyRequirements(energyAmount: 4)
			..error = 'You need at least 4 energy to pull off ice cubes';
		actions.add(
			new Action.withName('collect')
				..actionWord = 'breaking the ice'
				..timeRequired = actionTime
				..energyRequirements = energyReq
				..itemRequirements = itemReq
		);

		// Sprite sheet converted locally from the CC0 tinyspeck/glitch-items
		// source (harvestable_resources/ice_knob/ice_knob.swf) via
		// tools/build-sprite-sheet.py; see content/source-manifest.json for
		// provenance and content/runtime-manifest.json for the route entry.
		// This replaces the previous hardcoded link to the retired
		// childrenofur.com asset host. The source exports 4 differently-shaped
		// "knob" variants (knob1..knob4), each independently a 5-frame
		// empty/small/big/bigger/ready fullness timeline matching this state's
		// depletion mechanic exactly; knob1 was used arbitrarily as the
		// representative variant (documented, not guessed), matching the
		// MetalRock/BerylRock precedent of picking one numbered sibling.
		states = {
			"1-2-3-4-5" : new Spritesheet("1-2-3-4-5", "files/sprites/generated/converted/ice_knob-1-2-3-4-5.png", 285, 83, 57, 83, 5, false),
		};
		setState('1-2-3-4-5');
		state = new Random().nextInt(currentState.numFrames);
		maxState = 4; //cuz 0-4 = 5
	}

	@override
	void update({bool simulateTick: false}) {
		if(respawn != null && new DateTime.now().isAfter(respawn)) {
			setActionEnabled("collect", true);
			state = maxState;
			respawn = null;
		}

		if(state < 1 && respawn == null) {
			setActionEnabled("collect", false);
			respawn = new DateTime.now().add(new Duration(minutes:2));
		}
	}

	Future<bool> collect ({WebSocket userSocket, String email}) async {
		if(state < 1) {
			say('Out of ice');
			return false;
		}
		state--;

		//make sure the player has a shovel that can scrape this ice
		Action digAction = actions.singleWhere((Action a) => a.actionName == 'collect');
		List<String> types = digAction.itemRequirements.any;
		bool success = await InventoryV2.decreaseDurability(email, types);
		if(!success) {
			return false;
		}

		success = await super.trySetMetabolics(email,energy:-4,imgMin:2,imgRange:2);
		if(!success) {
			return false;
		}

		int numToGive = 1;
		// 1 in 15 chance to get an extra
		if(new Random().nextInt(15) == 14) {
			numToGive = 2;
		}

		// Chance to get an ice cube
		// Chance to let it melt before you collect it
		if(new Random().nextInt(2) == 1) {
			await InventoryV2.addItemToUser(email, items['ice'].getMap(), numToGive, id);
			state--;

			StatManager.add(email, Stat.ice_scraped).then((int scraped) {
				if (scraped >= 1777) {
					Achievement.find("icebreaker").awardTo(email);
				} else if (scraped >= 877) {
					Achievement.find("cold_as_ice").awardTo(email);
				} else if (scraped >= 467) {
					Achievement.find("on_thin_ice").awardTo(email);
				} else if (scraped >= 227) {
					Achievement.find("ice_ice_baby").awardTo(email);
				} else if (scraped >= 67) {
					Achievement.find("ice_baby").awardTo(email);
				}
			});

			if(state < 1) {
				respawn = new DateTime.now().add(new Duration(minutes:2));
				return false;
			}
			return true;
		} else {
			await InventoryV2.addItemToUser(email, items['cup_of_water'].getMap(), 1, id);
			say("You have to grab it faster next time. It melted!");
			return false;
		}
	}
}

class IceKnob extends IceNubbin {
	IceKnob(String id, num x, num y, num z, num rotation, bool h_flip, String streetName) : super(id, x, y, z, rotation, h_flip, streetName);
}
