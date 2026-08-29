part of entity;

class MortarBarnacle extends Plant {
	MortarBarnacle(String id, num x, num y, num z, num rotation, bool h_flip, String streetName) : super(id, x, y, z, rotation, h_flip, streetName) {
		actionTime = 2000;
		type = "Mortar Barnacle";

		ItemRequirements itemReq = new ItemRequirements()
			..any = ['scraper', 'super_scraper']
			..error = "You don't want to use your hands; you'll break a nail!";
		actions.add(
			new Action.withName('scrape')
				..actionWord = 'scraping'
				..timeRequired = actionTime
				..energyRequirements = new EnergyRequirements(energyAmount: 9)
				..itemRequirements = itemReq
			);

		// Sprite sheet converted locally from the CC0 tinyspeck/glitch-items
		// source (harvestable_resources/mortar_barnacle/mortar_barnacle.swf) via
		// tools/build-sprite-sheet.py; see content/source-manifest.json for
		// provenance and content/runtime-manifest.json for the route entry.
		// This replaces the previous hardcoded link to the retired
		// childrenofur.com asset host. The source exports 6 differently-shaped
		// "blister" variants (blister1..6, more than this entity's 5-frame
		// state name implies), each independently a 5-frame
		// empty/small/big/bigger/ready fullness timeline; blister1 was used
		// arbitrarily as the representative variant (documented, not guessed).
		// Frame dimensions (60x70) match the previously hardcoded values
		// exactly, confirming the source mapping.
		states = {
			"1-2-3-4-5" : new Spritesheet("1-2-3-4-5", "files/sprites/generated/converted/mortar_barnacle-1-2-3-4-5.png", 300, 70, 60, 70, 5, false),
		};
		setState('1-2-3-4-5');
		state = new Random().nextInt(currentState.numFrames);
		maxState = 4; //cuz 0-4 = 5
	}

	@override
	void update({bool simulateTick: false}) {
		if(respawn != null && new DateTime.now().isAfter(respawn)) {
			setActionEnabled("scrape", true);
			state = maxState;
			respawn = null;
		}

		if(state < 1 && respawn == null) {
			setActionEnabled("scrape", false);
			respawn = new DateTime.now().add(new Duration(minutes:2));
		}
	}

	Future<bool> scrape({WebSocket userSocket, String email}) async {
		if(state < 1) {
			say('No more barnacles');
			return false;
		}
		state--;

		//make sure the player has a shovel that can scrape this rock
		Action digAction = actions.singleWhere((Action a) => a.actionName == 'scrape');
		// See icenubbin.dart's comment on this same fix -- itemRequirements.any
		// is an untyped List, so the legacy mapper decodes raw List<dynamic>;
		// direct assignment to List<String> threw on every use.
		List<String> types = List<String>.from(digAction.itemRequirements.any);
		bool success = await InventoryV2.decreaseDurability(email, types);
		if(!success) {
			return false;
		}

		success = await super.trySetMetabolics(email,energy:-9,imgMin:10,imgRange:5);
		if(!success) {
			return false;
		}

		int numToGive = 1;
		// 1 in 15 chance to get an extra
		if(new Random().nextInt(15) == 14) {
			numToGive = 2;
		}

		StatManager.add(email, Stat.barnacles_scraped).then((int scraped) {
			if (scraped >= 1009) {
				Achievement.find("bigger_league_decrustifier").awardTo(email);
			} else if (scraped >= 503) {
				Achievement.find("big_league_decrustifier").awardTo(email);
			} else if (scraped >= 283) {
				Achievement.find("semi_pro_decrustifier").awardTo(email);
			} else if (scraped >= 127) {
				Achievement.find("decrustifying_enthusiast").awardTo(email);
			} else if (scraped >= 41) {
				Achievement.find("amateur_decrustifier").awardTo(email);
			}
		});

		await InventoryV2.addItemToUser(email, items['barnacle'].getMap(), numToGive, id);

		say();

		return true;
	}
}
