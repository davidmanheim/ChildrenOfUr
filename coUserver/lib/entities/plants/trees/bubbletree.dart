part of entity;

class BubbleTree extends Tree {
	BubbleTree(String id, num x, num y, num z, num rotation, bool h_flip, String streetName) : super(id, x, y, z, rotation, h_flip, streetName) {
		type = "Bubble Tree";
		rewardItemType = "plain_bubble";

		responses =
		{
			"harvest": [
				"…know the power you hold in your hands…",
				"Bubbles. Precious bubbles. Just for you. Pop-pop!",
				"…which is why harvesting is crucial to… Oh! Shh.",
				"Wait, my tin hat didn't fall in with that haul, right?",
				"…Again? You're up to something, I sense it.",
			],
			"pet": [
				"Wait! Shh. Did you hear that? Never mind. Pretend you didn't.",
				"...a nice BLT: a batterfly, lettuce and tomato sandwich, and...",
				"... big difference between mostly dead and all dead. And...",
				"...shh! Can't talk now! Tin foil hat compromised! More later!…",
				"...went pop! Pop pop pop!  Until it was all dark, and then...",
			],
			"water": [
				"…what's that? Wet? Huh?",
				"Huh? Something for nothing, eh?",
				"I don't trust watering cans. But you're ok.",
				"…all in it together. SHHH! Someone's listening…",
				"…in the caves. But it only LOOKED like an accident…",
			]
		};

		// Sprite sheets converted locally from the CC0 tinyspeck/glitch-items
		// source (harvestable_resources/bubble_tree/trant_bubble.swf) via
		// tools/build-sprite-sheet.py; see content/source-manifest.json for
		// provenance and content/runtime-manifest.json for the route entry.
		// These replace the previous hardcoded links to the retired
		// childrenofur.com asset host.
		//
		// Same more-elaborate-than-wood_tree structure as BeanTree (see the
		// comment there): trant_bubble.as defines 10 maturity-stage clips
		// (bt_grow1..grow10, matched here by their exported symbol names),
		// each itself a genuine 10-frame health timeline
		// (`tree.gotoAndPlay(health)` in the source AS3), which lines up
		// exactly with Tree's existing state/maxState harvest mechanic --
		// every maturity_N sheet below has the true numFrames=10 rather than
		// the old dead-URL era's guessed, inconsistent per-stage counts (9,
		// 10, 44, 61, 62, 72 x3, 76). Per-bubble (bubble_1..bubble_N)
		// visibility is separately AS3-driven from "fruit_amt" inside each
		// growN clip and isn't representable by this single-image-per-state
		// architecture; each converted frame shows that stage/health
		// combination's default authored bubble visibility.
		const String base = "files/sprites/generated/converted/bubble_tree-";
		states =
		{
			"maturity_1" : new Spritesheet("maturity_1", "${base}maturity_1.png", 420, 91, 42, 91, 10, false),
			"maturity_2" : new Spritesheet("maturity_2", "${base}maturity_2.png", 450, 122, 45, 122, 10, false),
			"maturity_3" : new Spritesheet("maturity_3", "${base}maturity_3.png", 530, 144, 53, 144, 10, false),
			"maturity_4" : new Spritesheet("maturity_4", "${base}maturity_4.png", 630, 160, 63, 160, 10, false),
			"maturity_5" : new Spritesheet("maturity_5", "${base}maturity_5.png", 770, 184, 77, 184, 10, false),
			"maturity_6" : new Spritesheet("maturity_6", "${base}maturity_6.png", 900, 190, 90, 190, 10, false),
			"maturity_7" : new Spritesheet("maturity_7", "${base}maturity_7.png", 1230, 205, 123, 205, 10, false),
			"maturity_8" : new Spritesheet("maturity_8", "${base}maturity_8.png", 1300, 213, 130, 213, 10, false),
			"maturity_9" : new Spritesheet("maturity_9", "${base}maturity_9.png", 1550, 250, 155, 250, 10, false),
			"maturity_10" : new Spritesheet("maturity_10", "${base}maturity_10.png", 1710, 277, 171, 277, 10, false)
		};
		maturity = new Random().nextInt(states.length) + 1;
		setState('maturity_$maturity');
		state = new Random().nextInt(currentState.numFrames);
		maxState = currentState.numFrames - 1;
	}

	Future<bool> harvest({WebSocket userSocket, String email}) async {
		bool success = await super.harvest(userSocket:userSocket,email:email);

		if(success) {
			StatManager.add(email, Stat.bubbles_harvested).then((int harvested) {
				if (harvested >= 5003) {
					Achievement.find("firstbest_bubble_farmer").awardTo(email);
				} else if (harvested >= 1009) {
					Achievement.find("secondbest_bubble_farmer").awardTo(email);
				} else if (harvested >= 503) {
					Achievement.find("better_bubble_farmer").awardTo(email);
				} else if (harvested >= 101) {
					Achievement.find("good_bubble_farmer").awardTo(email);
				}
			});
		}

		return success;
	}

	Future<bool> pet({WebSocket userSocket, String email}) async {
		bool success = await super.pet(userSocket: userSocket, email: email);

		if (success) {
			StatManager.add(email, Stat.bubble_trees_petted).then((int stat) {
				if (stat >= 127) {
					Achievement.find("chief_bubble_tree_cuddler").awardTo(email);
				} else if (stat >= 41) {
					Achievement.find("midlevel_bubble_tree_cuddler").awardTo(email);
				} else if (stat >= 11) {
					Achievement.find("rookie_bubble_tree_cuddler").awardTo(email);
				}
			});
		}

		return success;
	}

	Future<bool> water({WebSocket userSocket, String email}) async {
		bool success = await super.water(userSocket: userSocket, email: email);

		if (success) {
			StatManager.add(email, Stat.bubble_trees_watered).then((int stat) {
				if (stat >= 41) {
					Achievement.find("senor_sprinkles").awardTo(email);
				}
			});
		}

		return success;
	}
}
