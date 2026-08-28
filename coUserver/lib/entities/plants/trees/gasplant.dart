part of entity;

class GasPlant extends Tree {
	GasPlant(String id, num x, num y, num z, num rotation, bool h_flip, String streetName) : super(id, x, y, z, rotation, h_flip, streetName) {
		type = "Gas Plant";
		rewardItemType = "general_vapour";

		responses =
		{
			"harvest": [
				"You want gas? Dude, sure.",
				"Always happy to share, friend.",
				"Yeah, harvest away. Gas is a social thing, friend.",
				"Gas? For you? Yeah, man.",
				"You sure that's enough? Come back for a re-up anytime.",
			],
			"pet": [
				"Awwww yeah.",
				"Hey, do you remember that time when... oh, no, wait, that was Eggy",
				"Petting gives me a sweet, sweet buzz, friend",
				"Good times, man, good times.",
				"Such good energy, man",
				"Oops, pardon me"
			],
			"water": [
				"Woah. That's wet.",
				"Cool, man. Cool.",
				"Sweet can-tipping, friend.",
				"Ahhhh, that's the stuff, kid.",
				"Woah, man! Water! Like, TOTALLY unexpected.",
			]
		};

		// Sprite sheets converted locally from the CC0 tinyspeck/glitch-items
		// source (harvestable_resources/gas_plant/trant_gas.swf) via
		// tools/build-sprite-sheet.py; see content/source-manifest.json for
		// provenance and content/runtime-manifest.json for the route entry.
		// These replace the previous hardcoded links to the retired
		// childrenofur.com asset host.
		//
		// Like BeanTree/BubbleTree/EggPlant, trant_gas.as defines 10 discrete
		// maturity-stage clips, each independently a real 10-frame timeline
		// where the frame number is the tree's "health"
		// (tree.gotoAndStop(11 - health) in the source AS3). Unlike EggPlant,
		// this SWF's 10 maturity clips (treem1..treem10) are placed as
		// instance-named children directly on the root timeline rather than
		// exported via SymbolClass -- resolved here by parsing the root
		// timeline's PlaceObject2 records directly for the "treem1".."treem10"
		// instance names, the same technique used for Batterfly's root symbol
		// (see content/source-manifest.json). A separate per-flask (flask_N)
		// visibility dimension, driven from a "fruit_amt" value, is NOT
		// representable by this single-image-per-frame sprite architecture
		// and is not modeled; each converted frame shows that growth/health
		// combination's default authored flask visibility.
		const String base = "files/sprites/generated/converted/gas_plant-";
		states =
		{
			"maturity_1" : new Spritesheet("maturity_1", "${base}maturity_1.png", 580, 71, 58, 71, 10, false),
			"maturity_2" : new Spritesheet("maturity_2", "${base}maturity_2.png", 720, 83, 72, 83, 10, false),
			"maturity_3" : new Spritesheet("maturity_3", "${base}maturity_3.png", 890, 102, 89, 102, 10, false),
			"maturity_4" : new Spritesheet("maturity_4", "${base}maturity_4.png", 1020, 124, 102, 124, 10, false),
			"maturity_5" : new Spritesheet("maturity_5", "${base}maturity_5.png", 1520, 152, 152, 152, 10, false),
			"maturity_6" : new Spritesheet("maturity_6", "${base}maturity_6.png", 1760, 186, 176, 186, 10, false),
			"maturity_7" : new Spritesheet("maturity_7", "${base}maturity_7.png", 2060, 210, 206, 210, 10, false),
			"maturity_8" : new Spritesheet("maturity_8", "${base}maturity_8.png", 2490, 239, 249, 239, 10, false),
			"maturity_9" : new Spritesheet("maturity_9", "${base}maturity_9.png", 2580, 250, 258, 250, 10, false),
			"maturity_10" : new Spritesheet("maturity_10", "${base}maturity_10.png", 2780, 259, 278, 259, 10, false)
		};
		maturity = new Random().nextInt(states.length) + 1;
		setState('maturity_$maturity');
		state = new Random().nextInt(currentState.numFrames);
		maxState = currentState.numFrames - 1;
	}

	Future<bool> harvest({WebSocket userSocket, String email}) async {
		bool success = await super.harvest(userSocket:userSocket,email:email);

		if(success) {
			StatManager.add(email, Stat.gas_harvested).then((int harvested) {
				if (harvested >= 5003) {
					Achievement.find("obsessive_gas_fancier").awardTo(email);
				} else if (harvested >= 1009) {
					Achievement.find("dedicated_gas_fancier").awardTo(email);
				} else if (harvested >= 503) {
					Achievement.find("hobbyist_gas_fancier").awardTo(email);
				} else if (harvested >= 101) {
					Achievement.find("occasional_gas_fancier").awardTo(email);
				}
			});
		}

		return success;
	}

	Future<bool> pet({WebSocket userSocket, String email}) async {
		bool success = await super.pet(userSocket: userSocket, email: email);

		if (success) {
			StatManager.add(email, Stat.gas_plants_petted).then((int stat) {
				if (stat >= 41) {
					Achievement.find("bush_whacker").awardTo(email);
				}
			});
		}

		return success;
	}

	Future<bool> water({WebSocket userSocket, String email}) async {
		bool success = await super.water(userSocket: userSocket, email: email);

		if (success) {
			StatManager.add(email, Stat.gas_plants_watered).then((int stat) {
				if (stat >= 127) {
					Achievement.find("mayor_of_sprayerville").awardTo(email);
				} else if (stat >= 11) {
					Achievement.find("little_squirt").awardTo(email);
				}
			});
		}

		return success;
	}
}
