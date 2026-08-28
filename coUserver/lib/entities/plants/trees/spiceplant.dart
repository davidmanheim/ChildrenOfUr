part of entity;

class SpicePlant extends Tree {
	SpicePlant(String id, num x, num y, num z, num rotation, bool h_flip, String streetName) : super(id, x, y, z, rotation, h_flip, streetName) {
		type = "Spice Plant";
		rewardItemType = "allspice";

		responses =
		{
			"harvest": [
				"Ahhh, spicy, spicy, spicy…",
				"My my, you can't get enough of ol' Spicy, can you?",
				"You can harvest me whenever you like, poppet.",
				"Here, my pretty. Spice up your life.",
				"As they say, spice is the spice of… no, that's not right.",
			],
			"pet": [
				"Eh? What? How nice…",
				"My, my: such soft hands.",
				"Oh my! This is unexpectedly satisfying…",
				"Well I never...",
				"Nice job, kid, but could be spicier. Know whaddai mean?",
			],
			"water": [
				"Oh! No, carry on, I like it.",
				"Goodness, sneak up on an old tree, why don't you?",
				"Water? Well, I suppose I might partake…",
				"Well well! That's a pleasant surprise.",
				"Ahhhh, you flatter me with this sprinkling.",
			]
		};

		// Sprite sheets converted locally from the CC0 tinyspeck/glitch-items
		// source (harvestable_resources/spice_plant/trant_spice.swf) via
		// tools/build-sprite-sheet.py; see content/source-manifest.json for
		// provenance and content/runtime-manifest.json for the route entry.
		// These replace the previous hardcoded links to the retired
		// childrenofur.com asset host.
		//
		// Same combinatorial growth-stage x health design as BeanTree/
		// BubbleTree/EggPlant/GasPlant (see their entity files):
		// trant_spice.as defines 10 exported spiceTree_growN clips (named via
		// SymbolClass, like BeanTree), each a real 10-frame health timeline.
		const String base = "files/sprites/generated/converted/spice_plant-";
		states =
		{
			"maturity_1" : new Spritesheet("maturity_1", "${base}maturity_1.png", 1260, 125, 126, 125, 10, false),
			"maturity_2" : new Spritesheet("maturity_2", "${base}maturity_2.png", 1500, 145, 150, 145, 10, false),
			"maturity_3" : new Spritesheet("maturity_3", "${base}maturity_3.png", 1660, 166, 166, 166, 10, false),
			"maturity_4" : new Spritesheet("maturity_4", "${base}maturity_4.png", 1680, 174, 168, 174, 10, false),
			"maturity_5" : new Spritesheet("maturity_5", "${base}maturity_5.png", 1910, 184, 191, 184, 10, false),
			"maturity_6" : new Spritesheet("maturity_6", "${base}maturity_6.png", 2230, 199, 223, 199, 10, false),
			"maturity_7" : new Spritesheet("maturity_7", "${base}maturity_7.png", 2530, 217, 253, 217, 10, false),
			"maturity_8" : new Spritesheet("maturity_8", "${base}maturity_8.png", 2810, 239, 281, 239, 10, false),
			"maturity_9" : new Spritesheet("maturity_9", "${base}maturity_9.png", 2930, 257, 293, 257, 10, false),
			"maturity_10" : new Spritesheet("maturity_10", "${base}maturity_10.png", 3250, 271, 325, 271, 10, false)
		};
		maturity = new Random().nextInt(states.length) + 1;
		setState('maturity_$maturity');
		state = new Random().nextInt(currentState.numFrames);
		maxState = currentState.numFrames - 1;
	}

	Future<bool> harvest({WebSocket userSocket, String email}) async {
		bool success = await super.harvest(userSocket:userSocket,email:email);

		if(success) {
			StatManager.add(email, Stat.spice_harvested).then((int harvested) {
				if (harvested >= 5003) {
					Achievement.find("master_overlord_of_the_spice_dominion").awardTo(email);
				} else if (harvested >= 1009) {
					Achievement.find("advanced_spice_collector").awardTo(email);
				} else if (harvested >= 503) {
					Achievement.find("intermediate_spice_collector").awardTo(email);
				} else if (harvested >= 101) {
					Achievement.find("novice_spice_collector").awardTo(email);
				}
			});
		}

		return success;
	}

	Future<bool> pet({WebSocket userSocket, String email}) async {
		bool success = await super.pet(userSocket: userSocket, email: email);

		if (success) {
			StatManager.add(email, Stat.spice_plants_petted).then((int stat) {
				if (stat >= 127) {
					Achievement.find("heavy_petter").awardTo(email);
				} else if (stat >= 41) {
					Achievement.find("confident_petter").awardTo(email);
				} else if (stat >= 11) {
					Achievement.find("tentative_petter").awardTo(email);
				}
			});
		}

		return success;
	}

	Future<bool> water({WebSocket userSocket, String email}) async {
		bool success = await super.water(userSocket: userSocket, email: email);

		if (success) {
			StatManager.add(email, Stat.spice_plants_watered).then((int stat) {
				if (stat >= 41) {
					Achievement.find("big_splasher").awardTo(email);
				} else if (stat >= 11) {
					Achievement.find("beginner_drizzler").awardTo(email);
				}
			});
		}

		return success;
	}
}
