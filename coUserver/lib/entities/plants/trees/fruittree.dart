part of entity;

class FruitTree extends Tree {
	FruitTree(String id, num x, num y, num z, num rotation, bool h_flip, String streetName) : super(id, x, y, z, rotation, h_flip, streetName) {
		type = "Fruit Tree";
		rewardItemType = "cherry";

		responses =
		{
			"harvest": [
				"Fruity!",
				"Ta-daaaaaaa…",
				"Yaaaaaay!",
				"Frooooot!",
				"C'est la!",
				"Oof. Take this. Heavy."
			],
			"pet": [
				"Huh?",
				"Oh.",
				"Whu?",
				"Ah.",
				"Pff.",
				"Together we make a great pear"
			],
			"water": [
				"Hm?",
				"Ahh.",
				"Glug.",
				"Mm?",
				"Shhhlrp.",
			]
		};

		// Sprite sheets converted locally from the CC0 tinyspeck/glitch-items
		// source (harvestable_resources/fruit_tree/trant_fruit.swf) via
		// tools/build-sprite-sheet.py; see content/source-manifest.json for
		// provenance and content/runtime-manifest.json for the route entry.
		// These replace the previous hardcoded links to the retired
		// childrenofur.com asset host.
		//
		// This tree's real source structure is the most elaborate of the
		// four converted in this pass, and differs from BeanTree/BubbleTree
		// in an important way: trant_fruit.as's 10 maturity-stage clips
		// (grow_1..grow_10, resolved here by parsing the root timeline's
		// PlaceObject2 instance names directly, since -- unlike the bean and
		// bubble trees -- these clips are not separately exported/named
		// symbols) are each confirmed (by ffdec frame count) to hold only a
		// SINGLE frame at the top level. The AS3's 10-level "health" and
		// fruit-count visuals are driven entirely by separately toggling
		// dozens of nested per-leaf (fol_1..fol_maxfla) and per-cherry
		// (cherry_1..cherry_maxcherry) child clip frames/visibility -- a
		// genuinely combinatorial per-instance system with no single
		// equivalent top-level animation frame range to extract, and not
		// representable by this single-image-per-state sprite architecture
		// (which, like every other converted entity in this pass, composites
		// one whole rasterized frame per state rather than layering
		// sub-parts). Each maturity_N sheet below is therefore built by
		// duplicating that one real, correctly-converted default-health
		// snapshot across all 10 columns (see content/source-manifest.json,
		// "note" field) rather than inventing frames that were never in the
		// source. This is a deliberate, documented simplification: it keeps
		// numFrames=10 and therefore maxState=9, preserving the existing
		// water()/harvest() 10-level state mechanic inherited from Tree
		// (frame lookups use `%` in the client, so any state value renders
		// safely -- it just always shows the one real image for that
		// maturity stage instead of animating through health levels).
		const String base = "files/sprites/generated/converted/fruit_tree-";
		states =
		{
			"maturity_1" : new Spritesheet("maturity_1", "${base}maturity_1.png", 940, 100, 94, 100, 10, false),
			"maturity_2" : new Spritesheet("maturity_2", "${base}maturity_2.png", 1160, 111, 116, 111, 10, false),
			"maturity_3" : new Spritesheet("maturity_3", "${base}maturity_3.png", 1400, 122, 140, 122, 10, false),
			"maturity_4" : new Spritesheet("maturity_4", "${base}maturity_4.png", 1440, 143, 144, 143, 10, false),
			"maturity_5" : new Spritesheet("maturity_5", "${base}maturity_5.png", 1700, 154, 170, 154, 10, false),
			"maturity_6" : new Spritesheet("maturity_6", "${base}maturity_6.png", 1900, 180, 190, 180, 10, false),
			"maturity_7" : new Spritesheet("maturity_7", "${base}maturity_7.png", 1950, 195, 195, 195, 10, false),
			"maturity_8" : new Spritesheet("maturity_8", "${base}maturity_8.png", 2280, 221, 228, 221, 10, false),
			"maturity_9" : new Spritesheet("maturity_9", "${base}maturity_9.png", 2620, 245, 262, 245, 10, false),
			"maturity_10" : new Spritesheet("maturity_10", "${base}maturity_10.png", 2880, 250, 288, 250, 10, false)
		};
		maturity = new Random().nextInt(states.length) + 1;
		setState('maturity_$maturity');
		state = new Random().nextInt(currentState.numFrames);
		maxState = currentState.numFrames - 1;
	}

	Future<bool> harvest({WebSocket userSocket, String email}) async {
		bool success = await super.harvest(userSocket:userSocket,email:email);

		if(success) {
			StatManager.add(email, Stat.cherries_harvested).then((int harvested) {
				if (harvested >= 5003) {
					Achievement.find("president_and_ceo_of_fruit_tree_harvesting_inc").awardTo(email);
				} else if (harvested >= 1009) {
					Achievement.find("overpaid_executive_fruit_tree_harvester").awardTo(email);
				} else if (harvested >= 503) {
					Achievement.find("midmanagement_fruit_tree_harvester").awardTo(email);
				} else if (harvested >= 101) {
					Achievement.find("entrylevel_fruit_tree_harvester").awardTo(email);
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
					Achievement.find("masterful_fruit_tree_pettifier").awardTo(email);
				} else if (stat >= 41) {
					Achievement.find("betterthanmediocre_fruit_tree_pettifier").awardTo(email);
				} else if (stat >= 11) {
					Achievement.find("newbie_fruit_tree_pettifier").awardTo(email);
				}
			});
		}

		return success;
	}

	Future<bool> water({WebSocket userSocket, String email}) async {
		bool success = await super.water(userSocket: userSocket, email: email);

		if (success) {
			StatManager.add(email, Stat.egg_plants_watered).then((int stat) {
				if (stat >= 127) {
					Achievement.find("super_duper_soaker").awardTo(email);
				} else if (stat >= 41) {
					Achievement.find("super_soaker").awardTo(email);
				} else if (stat >= 11) {
					Achievement.find("ok_soaker").awardTo(email);
				}
			});
		}

		return success;
	}
}
