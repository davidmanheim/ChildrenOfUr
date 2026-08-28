part of entity;

class Helga extends Vendor {
	int openCount = 0;

	Helga(String id, String streetName, String tsid, num x, num y, num z, num rotation, bool h_flip) : super(id, streetName, tsid, x, y, z, rotation, h_flip) {
		type = "Helga";
		itemsPredefined = true;
		itemsForSale = [
			items["still"].getMap(),
			items["beer"].getMap(),
			items["carrot_margarita"].getMap(),
			items["coffee"].getMap(),
			items["creamy_martini"].getMap(),
			items["exotic_juice"].getMap(),
			items["mabbish_coffee"].getMap(),
			items["mega_healthy_veggie_juice"].getMap(),
			items["savory_smoothie"].getMap(),
			items["slow_gin_fizz"].getMap(),
			items["spicy_grog"].getMap(),
			items["tooberry_shake"].getMap()
		];
		speed = 40;

		states = {
			"idle_stand": new Spritesheet(
				"idle_stand",
				"files/sprites/generated/converted/helga-idle_stand.png",
				140800,
				196,
				440,
				196,
				320,
				true),
			"idle_stand_2": new Spritesheet(
				"idle_stand",
				"files/sprites/generated/converted/helga-idle_stand.png",
				140800,
				196,
				440,
				196,
				320,
				true),
			"impatient": new Spritesheet(
				"impatient",
				"files/sprites/generated/converted/helga-impatient.png",
				43120,
				196,
				440,
				196,
				98,
				true),
			"talk": new Spritesheet(
				"talk",
				"files/sprites/generated/converted/helga-talk.png",
				31680,
				196,
				440,
				196,
				72,
				true),
			"turn_left": new Spritesheet(
				"turn",
				"files/sprites/generated/converted/helga-turn_left.png",
				7920,
				196,
				440,
				196,
				18,
				false),
			"turn_right": new Spritesheet(
				"turn_right",
				"files/sprites/generated/converted/helga-turn_right.png",
				7040,
				196,
				440,
				196,
				16,
				false),
			"walk_end": new Spritesheet(
				"walk_end",
				"files/sprites/generated/converted/helga-walk_end.png",
				6600,
				196,
				440,
				196,
				15,
				false),
			"walk_left_end": new Spritesheet(
				"walk_left_end",
				"files/sprites/generated/converted/helga-walk_left_end.png",
				6600,
				196,
				440,
				196,
				15,
				false),
			"walk_left": new Spritesheet(
				"walk_left",
				"files/sprites/generated/converted/helga-walk_left.png",
				10120,
				196,
				440,
				196,
				23,
				true),
			"walk": new Spritesheet(
				"walk",
				"files/sprites/generated/converted/helga-walk.png",
				10120,
				196,
				440,
				196,
				23,
				true),
		};
		setState('idle_stand');
	}

	void update({bool simulateTick: false}) {
		super.update();

		//update x and y
		if (currentState.stateName == "walk") {
			moveXY(wallAction: (Wall wall) {
				if(facingRight) {
					setState('turn_left');
				} else {
					setState('turn_right');
				}
				facingRight = !facingRight;
			});
		}

		if (respawn.compareTo(new DateTime.now()) <= 0) {
			// if we just turned, we should say we're facing the other way, then we should start moving (that's why we turned around after all)
			if (currentState.stateName == 'turn_left') {
				// if we turned left, we are no longer facing right
				facingRight = false;
				// start walking left
				setState('walk', repeat: 3);
			} else if (currentState.stateName == 'turn_right') {
				// if we turned right, we are now facing right
				facingRight = true;
				// start walking right
				setState('walk');
			} else {
				// if we haven't just turned
				//1 in 10 that we turn around and start walking
				if(rand.nextInt(10) == 8) {
					if(facingRight) {
						setState('turn_left');
					} else {
						setState('turn_right');
					}
				} else if(rand.nextInt(2) == 1) {
					setState('walk', repeat: 5);
				} else {
					if (rand.nextInt(4) > 2) {
						// 50% chance of trying to attract buyers
						setState('impatient');
					} else if (rand.nextInt(2) == 1){
						// wait
						setState('idle_stand');
					}
				}
			}
		}
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