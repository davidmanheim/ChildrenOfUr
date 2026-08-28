part of entity;

class UncleFriendly extends Vendor {
	int openCount = 0;
	UncleFriendly(String id, String streetName, String tsid, num x, num y, num z, num rotation, bool h_flip) : super(id, streetName, tsid, x, y, z, rotation, h_flip) {
		type = "Uncle Friendly";
		itemsPredefined = true;
		itemsForSale = [
			items["honey"].getMap(),
			items["mushroom"].getMap(),
			items["mustard"].getMap(),
			items["oats"].getMap(),
			items["oily_dressing"].getMap(),
			items["olive_oil"].getMap(),
			items["sesame_oil"].getMap(),
			items["birch_syrup"].getMap(),
			items["coffee"].getMap(),
			items["beer"].getMap(),
			items["broccoli"].getMap(),
			items["cabbage"].getMap(),
			items["carrot"].getMap(),
			items["corn"].getMap(),
			items["cucumber"].getMap(),
			items["onion"].getMap(),
			items["potato"].getMap(),
			items["rice"].getMap(),
			items["spinach"].getMap(),
			items["tomato"].getMap(),
			items["zucchini"].getMap(),
			items["knife_and_board"].getMap(),
			items["frying_pan"].getMap(),
			items["blender"].getMap(),
			items["parsnip"].getMap()
		];
		speed = 40;

		states = {
			"idle_stand": new Spritesheet("idle_stand", "files/sprites/generated/converted/uncle_friendly-idle_stand.png", 149430, 260, 586, 260, 255, true),
			"idle_stand_2": new Spritesheet("idle_stand_2", "files/sprites/generated/converted/uncle_friendly-idle_stand.png", 149430, 260, 586, 260, 255, true),
			"impatient": new Spritesheet("impatient", "files/sprites/generated/converted/uncle_friendly-impatient.png", 50396, 260, 586, 260, 86, false),
			"talk": new Spritesheet("talk", "files/sprites/generated/converted/uncle_friendly-talk.png", 31058, 260, 586, 260, 53, true),
			"talk_end": new Spritesheet("talk_end","files/sprites/generated/converted/uncle_friendly-talk_end.png",8204,260,586,260,14,false),
			"turn": new Spritesheet("turn", "files/sprites/generated/converted/uncle_friendly-turn.png", 4102, 260, 586, 260, 7, false),
			"walk_end": new Spritesheet("walk_end", "files/sprites/generated/converted/uncle_friendly-walk_end.png", 5860, 260, 586, 260, 10, false),
			"walk": new Spritesheet("walk", "files/sprites/generated/converted/uncle_friendly-walk.png", 12892, 260, 586, 260, 22, true),
			"walk_reverse": new Spritesheet("walk_reverse","files/sprites/generated/converted/uncle_friendly-walk_reverse.png",9376,260,586,260,16,true)
		};
		setState('idle_stand');
	}

	void update({bool simulateTick: false}) {
		super.update();

		//update x and y
		if(currentState.stateName == "walk") {
			moveXY(wallAction: (Wall wall) {
				facingRight = !facingRight;
				setState('turn');
			});
		}

		if(respawn != null && respawn.compareTo(new DateTime.now()) <= 0) {
			// if we just turned, we should say we're facing the other way, then we should start moving (that's why we turned around after all)
			if(currentState.stateName == 'turn') {
				setState('walk', repeat: 3);
				return;
			} else {
				// if we haven't just turned
				if(rand.nextInt(2) == 1) {
					// 50% chance of walking around
					setState('walk', repeat: 8);
				} else if(rand.nextInt(2) == 1) {
					// attract customers?
					setState('impatient');
				} else {
					setState('idle_stand');
				}
				return;
			}
		}
	}

	void close({WebSocket userSocket, String email}) {
		openCount -= 1;
		//if no one else has them open
		if(openCount <= 0) {
			openCount = 0;
			setState('idle_stand');
		}
	}
}