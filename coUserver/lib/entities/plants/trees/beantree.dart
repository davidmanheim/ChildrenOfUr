part of entity;

class BeanTree extends Tree {
	BeanTree(String id, num x, num y, num z, num rotation, bool h_flip, String streetName) : super(id, x, y, z, rotation, h_flip, streetName) {
		type = "Bean Tree";
		rewardItemType = "bean";

		responses =
		{
			"harvest": [
				"Is that what you've bean looking for?",
				"Cool. Beans. Cool beans!",
				"Two bean, or not two bean?…",
				"You favored us. Now, we fava you. Ha ha. Like \"fava bean\".",
				"Wassssss-sap! Ha ha ha. Oh just take bean then.",
				"Have you seen Jack? I think I gave him the wrong seeds…",
				"I've bean watching you."
			],
			"pet": [
				"The petting is unbeleafable. Ha ha. Tree made joke. Laugh.",
				"Tiny Urling is very poplar with us. Ha ha.",
				"Your petting's never bean better. Hee!",
				"I wooden have thought you'd be so good. Now laugh.",
				"Tree arbors strong feelings to you. Chuckle now, please.",
				"Well it’s bean fun! See you later.",
				"We've all bean here before"
			],
			"water": [
				"Water nice thing to do. Ha! Ha ha?",
				"Trunk you very much. Ha ha. We made joke. Laugh.",
				"Thought you'd never pull the twigger. Joke.",
				"Cheers, bud.",
				"How kind you're bean. Ha ha. \"Bean\".",
				"Where have you bean all my life?"
			]
		};

		// Sprite sheets converted locally from the CC0 tinyspeck/glitch-items
		// source (harvestable_resources/bean_tree/trant_bean.swf) via
		// tools/build-sprite-sheet.py; see content/source-manifest.json for
		// provenance and content/runtime-manifest.json for the route entry.
		// These replace the previous hardcoded links to the retired
		// childrenofur.com asset host.
		//
		// This tree's source structure is genuinely more elaborate than
		// wood_tree's: the FLA/AS3 (trant_bean.as) defines 10 separate
		// maturity-stage MovieClips (beanTree_grow1..grow10, one per
		// maturity_N state below, matched by their exported symbol names),
		// and *each* of those is itself a 10-frame timeline where the frame
		// number is the tree's "health" (1-10, set via tree.setHealth(...)
		// in the original AS3) -- i.e. two combined discrete dimensions
		// (growth stage x health), not one. coUserver's Tree base class
		// already models exactly this: `state` (0..maxState, maxState =
		// currentState.numFrames-1) is incremented by water() and
		// decremented by harvest(), and directly indexes the sprite sheet
		// frame -- so real 10-frame-per-stage sheets slot into the existing
		// mechanic precisely, and every maturity_N sheet below has the true
		// numFrames=10 rather than the old dead-URL era's guessed,
		// inconsistent per-stage frame counts (9, 41, 51, 57, 59, 65, 66,
		// 68). The AS3 also independently toggles per-pod (bean_1..bean_N)
		// visibility from a separate "fruit_amt" value nested inside each
		// growN clip; that finer layer isn't representable by this
		// single-image-per-state sprite architecture and isn't modeled here
		// (each converted frame shows that growth/health combination's
		// default/authored pod visibility).
		const String base = "files/sprites/generated/converted/bean_tree-";
		states =
		{
			"maturity_1" : new Spritesheet("maturity_1", "${base}maturity_1.png", 520, 50, 52, 50, 10, false),
			"maturity_2" : new Spritesheet("maturity_2", "${base}maturity_2.png", 630, 61, 63, 61, 10, false),
			"maturity_3" : new Spritesheet("maturity_3", "${base}maturity_3.png", 800, 81, 80, 81, 10, false),
			"maturity_4" : new Spritesheet("maturity_4", "${base}maturity_4.png", 1020, 105, 102, 105, 10, false),
			"maturity_5" : new Spritesheet("maturity_5", "${base}maturity_5.png", 1180, 126, 118, 126, 10, false),
			"maturity_6" : new Spritesheet("maturity_6", "${base}maturity_6.png", 1320, 154, 132, 154, 10, false),
			"maturity_7" : new Spritesheet("maturity_7", "${base}maturity_7.png", 1600, 179, 160, 179, 10, false),
			"maturity_8" : new Spritesheet("maturity_8", "${base}maturity_8.png", 1740, 203, 174, 203, 10, false),
			"maturity_9" : new Spritesheet("maturity_9", "${base}maturity_9.png", 1850, 232, 185, 232, 10, false),
			"maturity_10" : new Spritesheet("maturity_10", "${base}maturity_10.png", 2000, 271, 200, 271, 10, false)
		};
		maturity = new Random().nextInt(states.length) + 1;
		setState('maturity_$maturity');
		state = new Random().nextInt(currentState.numFrames);
		maxState = currentState.numFrames - 1;
	}

	Future<bool> harvest({WebSocket userSocket, String email}) async {
		bool success = await super.harvest(userSocket:userSocket,email:email);

		if(success) {
			StatManager.add(email, Stat.beans_harvested).then((int harvested) {
				if (harvested >= 5003) {
					Achievement.find("master_bean_counter").awardTo(email);
				} else if (harvested >= 1009) {
					Achievement.find("bean_counter_pro").awardTo(email);
				} else if (harvested >= 503) {
					Achievement.find("bean_counter").awardTo(email);
				} else if (harvested >= 101) {
					Achievement.find("participant_award_bean_division").awardTo(email);
				}
			});
		}

		return success;
	}

	Future<bool> pet({WebSocket userSocket, String email}) async {
		bool success = await super.pet(userSocket: userSocket, email: email);

		if (success) {
			StatManager.add(email, Stat.bean_trees_petted).then((int stat) {
				if (stat >= 127) {
					Achievement.find("professional_bean_tree_fondler").awardTo(email);
				} else if (stat >= 41) {
					Achievement.find("notquitepro_bean_tree_fondler").awardTo(email);
				} else if (stat >= 11) {
					Achievement.find("amateur_bean_tree_fondler").awardTo(email);
				}
			});
		}

		return success;
	}

	Future<bool> water({WebSocket userSocket, String email}) async {
		bool success = await super.water(userSocket: userSocket, email: email);

		if (success) {
			StatManager.add(email, Stat.bean_trees_watered).then((int stat) {
				if (stat >= 41) {
					Achievement.find("betterthanlousy_douser").awardTo(email);
				}
			});
		}

		return success;
	}
}
