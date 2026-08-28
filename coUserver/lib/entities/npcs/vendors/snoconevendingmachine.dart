part of entity;

class SnoConeVendingMachine extends Vendor {
	int openCount = 0;

	// Should always be facingRight to prevent seeing SNO becoming ONS,
	// so this is used for walking direction tracking.
	bool facingRightInSpirit;

	SnoConeVendingMachine(String id, String streetName, String tsid, num x, num y, num z, num rotation, bool h_flip) : super(id, streetName, tsid, x, y, z, rotation, h_flip) {
		type = 'Sno Cone Vending Machine';
		itemsForSale = [
			items["snocone_blue"].getMap(),
			items["snocone_green"].getMap(),
			items["snocone_orange"].getMap(),
			items["snocone_red"].getMap(),
			items["snocone_purple"].getMap()
		];
		itemsPredefined = true;
		speed = 40;
		states = {
			"attract": new Spritesheet(
				"attract",
				"files/sprites/generated/converted/sno_cone-attract.png",
				6528,
				228,
				192,
				228,
				34,
				true),
			"idle_stand": new Spritesheet(
				"idle_stand",
				"files/sprites/generated/converted/sno_cone-idle_stand.png",
				11904,
				228,
				192,
				228,
				62,
				true),
			"talk": new Spritesheet(
				"talk",
				"files/sprites/generated/converted/sno_cone-talk.png",
				3840,
				228,
				192,
				228,
				20,
				false),
			"walk_end": new Spritesheet(
				"walk_end",
				"files/sprites/generated/converted/sno_cone-walk_end.png",
				2688,
				228,
				192,
				228,
				14,
				false),
			"walk_left": new Spritesheet(
				"walk_left",
				"files/sprites/generated/converted/sno_cone-walk_left.png",
				2688,
				228,
				192,
				228,
				14,
				true),
			"walk_right": new Spritesheet(
				"walk_right",
				"files/sprites/generated/converted/sno_cone-walk_right.png",
				2688,
				228,
				192,
				228,
				14,
				true)
		};
		facingRight = true;
		setState('idle_stand');
	}

	void update({bool simulateTick: false}) {
		super.update();

		//update x and y
		if (currentState.stateName == "walk_left" || currentState.stateName == "walk_right") {
			moveXY(wallAction: (Wall wall) {
				setState('walk_end');
				facingRightInSpirit = !facingRightInSpirit;
			});
		}

		if (respawn != null && respawn.compareTo(new DateTime.now()) <= 0) {
			int roll = rand.nextInt(5);
			switch (roll) {
				case 0:
					// try to attract buyers
					setState('attract');
					break;

				case 1:
					if(!facingRightInSpirit) {
						setState('walk_right', repeat: rand.nextInt(5) + 5);
						speed = 40;
					} else {
						setState('walk_left', repeat: rand.nextInt(5) + 5);
						speed = -40;
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
