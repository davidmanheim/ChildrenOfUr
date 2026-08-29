part of entity;

class PeatBog extends Plant {
	PeatBog(String id, num x, num y, num z, num rotation, bool h_flip, String streetName) : super(id, x, y, z, rotation, h_flip, streetName) {
		actionTime = 5000;
		type = "Peat Bog";

		ItemRequirements itemReq = new ItemRequirements()
			..any = ['shovel', 'ace_of_spades']
			..error = "You can't grip this stuff without a tool.";
		actions.add(
			new Action.withName('dig')
				..actionWord = 'digging'
				..timeRequired = actionTime
				..energyRequirements = new EnergyRequirements(energyAmount: 10)
				..itemRequirements = itemReq
			);

		// Sprite sheet converted locally from the CC0 tinyspeck/glitch-items
		// source (harvestable_resources/peat_base/peat_1/peat_1.swf) via
		// tools/build-sprite-sheet.py; see content/source-manifest.json for
		// provenance and content/runtime-manifest.json for the route entry.
		// This replaces the previous hardcoded link to the retired
		// childrenofur.com asset host. peat_1 of the 3 sibling numbered variant
		// folders was used arbitrarily as the representative source, matching
		// the MetalRock precedent; the other two were not converted in this
		// pass. Frame dimensions (210x53) closely match the previously
		// hardcoded values (211x52), confirming the source mapping.
		states = {
			"5-4-3-2-1" : new Spritesheet("5-4-3-2-1", "files/sprites/generated/converted/peat_base-5-4-3-2-1.png", 1050, 53, 210, 53, 5, false),
		};
		setState('5-4-3-2-1');
		state = new Random().nextInt(currentState.numFrames);
		maxState = 0;
	}

	@override
	void update({bool simulateTick: false}) {
		if(state >= currentState.numFrames) {
			setActionEnabled("dig", false);
		}

		if(respawn != null && new DateTime.now().compareTo(respawn) >= 0) {
			state = 0;
			setActionEnabled("dig", true);
			respawn = null;
		}

		if(state < maxState) {
			state = maxState;
		}
	}

	Future<bool> dig({WebSocket userSocket, String email}) async {
		//make sure the player has a shovel that can dig this peat
		Action digAction = actions.singleWhere((Action a) => a.actionName == 'dig');
		// See icenubbin.dart's comment on this same fix -- itemRequirements.any
		// is an untyped List, so the legacy mapper decodes raw List<dynamic>;
		// direct assignment to List<String> threw on every use.
		List<String> types = List<String>.from(digAction.itemRequirements.any);
		bool success = await InventoryV2.decreaseDurability(email, types);
		if(!success) {
			return false;
		}

		success = await super.trySetMetabolics(email,energy:-10,imgMin:10,imgRange:5);
		if(!success) {
			return false;
		}

		state++;
		if(state >= currentState.numFrames) {
			respawn = new DateTime.now().add(new Duration(minutes:2));
		}

		StatManager.add(email, Stat.peat_harvested).then((int harvested) {
			if (harvested >= 5003) {
				Achievement.find("saint_peater").awardTo(email);
			} else if (harvested >= 1009) {
				Achievement.find("feat_of_peat_excellence").awardTo(email);
			} else if (harvested >= 503) {
				Achievement.find("obsessive_compulsive_re_peater").awardTo(email);
			} else if (harvested >= 283) {
				Achievement.find("compulsive_re_peater").awardTo(email);
			} else if (harvested >= 41) {
				Achievement.find("re_peater").awardTo(email);
			}
		});

		//give the player the 'fruits' of their labor
		await InventoryV2.addItemToUser(email, items['peat'].getMap(), 1, id);

		return true;
	}
}
