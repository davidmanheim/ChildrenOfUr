part of entity;

class MealVendor extends Vendor {
	int openCount = 0;

	MealVendor(String id, String streetName, String tsid, num x, num y, num z, num rotation, bool h_flip) : super(id, streetName, tsid, x, y, z, rotation, h_flip) {
		type = 'Meal Vendor';
		itemsForSale = [
			items["earthshaker"].getMap(),
			items["face_smelter"].getMap(),
			items["flaming_humbaba"].getMap(),
			items["cheezy_sammich"].getMap(),
			items["potato_patty"].getMap(),
			items["basic_omelet"].getMap(),
			items["exotic_fruit_salad"].getMap(),
			items["scrumptious_frittata"].getMap(),
			items["pineapple_upside_down_pizza"].getMap(),
			items["super_veggie_kebabs"].getMap(),
			items["hash"].getMap(),
			items["divine_crepes"].getMap(),
			items["simple_bbq"].getMap(),
			items["obvious_panini"].getMap(),
			items["meat_gumbo"].getMap(),
			items["flummery"].getMap(),
			items["rich_tagine"].getMap(),
			items["chillybusting_chili"].getMap()
		];
		itemsPredefined = true;
		speed = 60;
		states = {
			"attract": new Spritesheet(
				"attract",
				"files/sprites/generated/converted/meal_vendor-attract.png",
				9800,
				238,
				196,
				238,
				50,
				false),
			"idle_stand": new Spritesheet(
				"idle_stand",
				"files/sprites/generated/converted/meal_vendor-idle_stand.png",
				76440,
				238,
				196,
				238,
				390,
				true),
			"talk": new Spritesheet(
				"talk",
				"files/sprites/generated/converted/meal_vendor-talk.png",
				7056,
				238,
				196,
				238,
				36,
				false),
			"walk_left": new Spritesheet(
				"walk_left",
				"files/sprites/generated/converted/meal_vendor-walk_left.png",
				4704,
				238,
				196,
				238,
				24,
				true),
			"walk": new Spritesheet(
				"walk_right",
				"files/sprites/generated/converted/meal_vendor-walk.png",
				3920,
				238,
				196,
				238,
				20,
				true)
		};
		facingRight = true;
		dontFlip = true;
		setState('idle_stand');
	}

	void update({bool simulateTick: false}) {
		super.update();

		//update x and y
		if (currentState.stateName.contains('walk')) {
			moveXY();
		}

		if (respawn != null && respawn.compareTo(new DateTime.now()) <= 0) {
			int roll = rand.nextInt(5);
			switch (roll) {
				case 0:
					// try to attract buyers
					setState('attract');
					break;
				case 1:
					// walk for 3 seconds
					Duration walkDuration = new Duration(seconds: 3);
					if (facingRight) {
						setState('walk', repeatFor: walkDuration);
					} else {
						setState('walk_left', repeatFor: walkDuration);
					}
					break;
				case 2:
				case 3:
				case 4:
					// do nothing
					setState('idle_stand');
					break;
			}
			return;
		}
	}

	void buy({WebSocket userSocket, String email}) {
		setState('talk');
		//don't go to another state until closed
		respawn = new DateTime.now().add(new Duration(days: 50));
		openCount++;

		super.buy(userSocket: userSocket, email: email);
	}

	void sell({WebSocket userSocket, String email}) {
		setState('talk');
		//don't go to another state until closed
		respawn = new DateTime.now().add(new Duration(days: 50));
		openCount++;

		super.sell(userSocket: userSocket, email: email);
	}

	void close({WebSocket userSocket, String email}) {
		openCount -= 1;
		//if no one else has them open
		if (openCount <= 0) {
			openCount = 0;
			setState('idle_stand');
		}
	}
}
