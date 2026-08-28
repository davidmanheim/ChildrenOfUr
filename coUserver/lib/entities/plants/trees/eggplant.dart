part of entity;

class EggPlant extends Tree {
	EggPlant(String id, num x, num y, num z, num rotation, bool h_flip, String streetName) : super(id, x, y, z, rotation, h_flip, streetName) {
		type = "Egg Plant";
		rewardItemType = "egg";

		responses =
		{
			"harvest": [
				"This. For you.",
				"We grew this. You take.",
				"This harvest good. Have it.",
				"Ooooof. Take harvest. Heavy.",
				"We made this. You can have.",
			],
			"pet": [
				"Petting approved.",
				"Think petting good. Builds brain.",
				"Much gooder. Egg Plant grows in body and brain.",
				"Egg plant grows stronger. Cleverer. And eggier.",
				"Yes. Petting makes brain and eggs biggerer.",
			],
			"water": [
				"Ahhhhh. Better.",
				"Water good. We feel gratitude.",
				"Glug. Thanks.",
				"Yes. Liquid helps make harvests. Good.",
				"Good watering. But we still like petting too, comprende?",
			]
		};

		// Sprite sheets converted locally from the CC0 tinyspeck/glitch-items
		// source (harvestable_resources/egg_plant/trant_egg.swf) via
		// tools/build-sprite-sheet.py; see content/source-manifest.json for
		// provenance and content/runtime-manifest.json for the route entry.
		// These replace the previous hardcoded links to the retired
		// childrenofur.com asset host.
		//
		// Like BeanTree/BubbleTree (see their entity files), trant_egg.as
		// defines 10 discrete maturity-stage clips (maturity0..maturity9,
		// exported with SymbolClass names) each independently a real 10-frame
		// timeline where the frame number is the tree's "health"
		// (tree.gotoAndStop(health) in the source AS3) -- a clean
		// growth-stage x health design, matching Tree's existing
		// state/maxState mechanic directly. A separate per-egg (egg_N)
		// visibility dimension, driven from a "fruit_amt" value, is NOT
		// representable by this single-image-per-frame sprite architecture
		// and is not modeled; each converted frame shows that growth/health
		// combination's default authored egg visibility.
		const String base = "files/sprites/generated/converted/egg_plant-";
		states =
		{
			"maturity_1" : new Spritesheet("maturity_1", "${base}maturity_1.png", 580, 78, 58, 78, 10, false),
			"maturity_2" : new Spritesheet("maturity_2", "${base}maturity_2.png", 680, 93, 68, 93, 10, false),
			"maturity_3" : new Spritesheet("maturity_3", "${base}maturity_3.png", 720, 107, 72, 107, 10, false),
			"maturity_4" : new Spritesheet("maturity_4", "${base}maturity_4.png", 1340, 154, 134, 154, 10, false),
			"maturity_5" : new Spritesheet("maturity_5", "${base}maturity_5.png", 1600, 174, 160, 174, 10, false),
			"maturity_6" : new Spritesheet("maturity_6", "${base}maturity_6.png", 1880, 189, 188, 189, 10, false),
			"maturity_7" : new Spritesheet("maturity_7", "${base}maturity_7.png", 2200, 181, 220, 181, 10, false),
			"maturity_8" : new Spritesheet("maturity_8", "${base}maturity_8.png", 1980, 201, 198, 201, 10, false),
			"maturity_9" : new Spritesheet("maturity_9", "${base}maturity_9.png", 2240, 228, 224, 228, 10, false),
			"maturity_10" : new Spritesheet("maturity_10", "${base}maturity_10.png", 2960, 280, 296, 280, 10, false)
		};
		maturity = new Random().nextInt(states.length) + 1;
		setState('maturity_$maturity');
		state = new Random().nextInt(currentState.numFrames);
		maxState = currentState.numFrames - 1;
	}

	Future<bool> harvest({WebSocket userSocket, String email}) async {
		bool success = await super.harvest(userSocket:userSocket,email:email);

		if(success) {
			StatManager.add(email, Stat.eggs_harveted).then((int harvested) {
				if (harvested >= 5003) {
					Achievement.find("egg_freak").awardTo(email);
				} else if (harvested >= 1009) {
					Achievement.find("egg_aficianado").awardTo(email);
				} else if (harvested >= 503) {
					Achievement.find("egg_poacher").awardTo(email);
				} else if (harvested >= 101) {
					Achievement.find("egg_enthusiast").awardTo(email);
				}
			});
		}

		return success;
	}

	Future<bool> pet({WebSocket userSocket, String email}) async {
		bool success = await super.pet(userSocket: userSocket, email: email);

		if (success) {
			StatManager.add(email, Stat.egg_plants_petted).then((int stat) {
				if (stat >= 127) {
					Achievement.find("super_supreme_egg_plant_coddler").awardTo(email);
				} else if (stat >= 41) {
					Achievement.find("supreme_egg_plant_coddler").awardTo(email);
				} else if (stat >= 11) {
					Achievement.find("egg_plant_coddler").awardTo(email);
				}
			});
		}

		return success;
	}

	Future<bool> water({WebSocket userSocket, String email}) async {
		bool success = await super.water(userSocket: userSocket, email: email);

		if (success) {
			StatManager.add(email, Stat.egg_plants_watered).then((int stat) {
				if (stat >= 41) {
					Achievement.find("about_average_irrigationist").awardTo(email);
				}
			});
		}

		return success;
	}
}
