part of entity;

enum FoxDestinationType {
	HOME, BAIT
}

class Fox extends NPC {
	static final String
		BRUSH = 'fox_brush',
		FIBER = 'fiber';

	static final Duration SPAWN_TIME = new Duration(seconds: 3);

	static final int
		SPEED_STOP = 0,
		SPEED_SLOW = 40,
		SPEED_FAST = 80;

	Spritesheet lastState;

	bool despawning = false, waiting = false, brushing = false;

	Point<num> movingTo, home;
	FoxDestinationType destinationType;

	Fox(String id, num x, num y, num z, num rotation, bool h_flip, String streetName) : super(id, x, y, z, rotation, h_flip, streetName) {
		// Client rendering
		type = 'Fox';
		speed = 0; // px/sec

		//The fox spritesheet is facing left
		facingRight = false;

		home = new Point(x, y);

		// Actions
		actionTime = 1;
		ItemRequirements itemReq = new ItemRequirements()
			..any = [BRUSH];
		actions.add(
			new Action.withName('brush')
				..timeRequired = actionTime
				..actionWord = 'brushing'
				..energyRequirements = new EnergyRequirements(energyAmount: 3)
				..itemRequirements = itemReq
		);

		// Spritesheets converted locally from the CC0 tinyspeck/glitch-items
		// source (inhabitants/fox/npc_fox.swf, DefineSprite 151 "orangeFox")
		// via tools/build-sprite-sheet.py; see content/source-manifest.json
		// for provenance and content/runtime-manifest.json for the route
		// entry. These replace the previous hardcoded links to the retired
		// childrenofur.com asset host. Every resolved real frame count below
		// exactly matched the frame counts already hardcoded here from the
		// dead-URL era, which independently confirms both the source mapping
		// and the original numbers -- only pixel dimensions changed.
		const String base = 'files/sprites/generated/converted/fox-';
		states = {
			'brushed': new Spritesheet('brushed', '${base}brushed.png', 314, 141, 157, 141, 2, true),
			'eatEnd': new Spritesheet('eatEnd', '${base}eatEnd.png', 3140, 141, 157, 141, 20, false),
			'eatStart': new Spritesheet('eatStart', '${base}eatStart.png', 1570, 141, 157, 141, 10, false),
			'eat': new Spritesheet('eat', '${base}eat.png', 3140, 141, 157, 141, 20, true),
			'jump': new Spritesheet('jump', '${base}jump.png', 4396, 141, 157, 141, 28, false),
			'pause': new Spritesheet('pause', '${base}pause.png', 8792, 141, 157, 141, 56, false),
			'run': new Spritesheet('run', '${base}run.png', 1884, 141, 157, 141, 12, true),
			'taunt': new Spritesheet('taunt', '${base}taunt.png', 6280, 141, 157, 141, 40, false),
			'walk': new Spritesheet('walk', '${base}walk.png', 3768, 141, 157, 141, 24, true),
			'_hidden': NPC.TRANSPARENT_SPRITE
		};
		hide();
	}

	Future<bool> brush({WebSocket userSocket, String email}) async {
		if (rand.nextBool()) {
			brushing = true;

			if (!(await InventoryV2.decreaseDurability(email, BRUSH))) {
				// Could not use brush durability
				return false;
			}

			if ((await InventoryV2.addItemToUser(email, FIBER, 1)) != 1) {
				// Could not give user fiber
				return false;
			}

			toast('You got a $FIBER!', userSocket);

			brushing = false;

			return true;
		} else {
			toast('The fox got away!', userSocket);
			return false;
		}
	}

	FoxBait findNearestBait() {
		List<FoxBait> onStreet = FoxBait.placedBait[streetName] ?? [];

		FoxBait nearestBait;
		num nearestDist;
		onStreet.forEach((FoxBait bait) {
			num distX = (this.x - bait.x).abs();
			num distY = (this.y - bait.y).abs();
			num dist = sqrt(pow(distX, 2) + pow(distY, 2));

			if (nearestDist == null || dist < nearestDist) {
				nearestDist = dist;
				nearestBait = bait;
			}
		});

		return nearestBait;
	}

	void hide() {
		lastState = currentState;
		setActionEnabled('brush', false);
		setState('_hidden');
	}

	void show([String overrideState]) {
		String state = overrideState ?? lastState?.stateName;
		if (state != null) {
			setState(state);
		}
		setActionEnabled('brush', true);
		lastState = null;
	}

	@override
	void update({bool simulateTick: false}) {
		super.update();

		if (waiting) {
			return;
		}

		if (brushing) {
			speed = SPEED_STOP;
			setState('brushed');
			return;
		}

		if (movingTo == null) {
			// Find & target bait
			FoxBait nearestBait = findNearestBait();
			if (nearestBait != null && nearestBait.attractedFox == null) {
				// Claim an unclaimed piece of bait
				nearestBait.attractedFox = this;

				// Appear soon
				waiting = true;
				new Future.delayed(SPAWN_TIME).then((_) {
					speed = SPEED_SLOW;
					show('walk');
					movingTo = new Point(nearestBait.x, nearestBait.y);
					destinationType = FoxDestinationType.BAIT;
					waiting = false;
				});
			} else if (!despawning) {
				// Disappear soon
				despawning = true;
				new Future.delayed(SPAWN_TIME).then((_) {
					hide();
					despawning = false;
				});
			}
		} else {
			facingRight = (movingTo.x > this.x);

			if ((this.x - movingTo.x).abs() < 20) {
				// At target
				movingTo = null;

				if (destinationType == FoxDestinationType.BAIT) {
					// Eat bait
					speed = SPEED_STOP;
					setState('eat');
					waiting = true;
					findNearestBait().eat().then((_) {
						// Return to start position
						speed = SPEED_FAST;
						setState('run');
						movingTo = home;
						destinationType = FoxDestinationType.HOME;
					});
				} else if (destinationType == FoxDestinationType.HOME) {
					// Start over
					hide();
					new Future.delayed(SPAWN_TIME).then((_) {
						waiting = false;
					});
				}
			} else {
				// Move toward target
				if (destinationType == FoxDestinationType.HOME) {
					speed = SPEED_FAST;
					setState('run');
				} else if (destinationType == FoxDestinationType.BAIT) {
					speed = SPEED_SLOW;
					setState('walk');
				}
			}

			moveXY();
		}
	}
}

class SilverFox extends Fox {
	SilverFox(String id, num x, num y, num z, num rotation, bool h_flip, String streetName) : super(id, x, y, z, rotation, h_flip, streetName) {
		// Converted from the same source SWF's DefineSprite 80 ("silverFox"),
		// the color-variant sibling of orangeFox with an identical frame-label
		// layout -- see the comment on Fox's states map above.
		const String base = 'files/sprites/generated/converted/silverfox-';
		states = {
			'brushed': new Spritesheet('brushed', '${base}brushed.png', 314, 141, 157, 141, 2, true),
			'eatEnd': new Spritesheet('eatEnd', '${base}eatEnd.png', 3140, 141, 157, 141, 20, false),
			'eatStart': new Spritesheet('eatStart', '${base}eatStart.png', 1570, 141, 157, 141, 10, false),
			'eat': new Spritesheet('eat', '${base}eat.png', 3140, 141, 157, 141, 20, true),
			'jump': new Spritesheet('jump', '${base}jump.png', 4396, 141, 157, 141, 28, false),
			'pause': new Spritesheet('pause', '${base}pause.png', 8792, 141, 157, 141, 56, false),
			'run': new Spritesheet('run', '${base}run.png', 1884, 141, 157, 141, 12, true),
			'taunt': new Spritesheet('taunt', '${base}taunt.png', 6280, 141, 157, 141, 40, false),
			'walk': new Spritesheet('walk', '${base}walk.png', 3768, 141, 157, 141, 24, true),
			'_hidden': NPC.TRANSPARENT_SPRITE
		};
		hide();
	}
}

class FoxBait extends NPC {
	/// Maps street names to fox bait objects for locating by foxes
	static Map<String, List<FoxBait>> placedBait = {};

	static final Duration
		EAT_TIME = new Duration(seconds: 3),
		MAX_TIME = new Duration(minutes: 5);

	// 1 fox per bait
	Fox attractedFox = null;

	FoxBait(String id, num x, num y, num z, num rotation, bool h_flip, String streetName) : super(id, x, y, z, rotation, h_flip, streetName) {
		type = 'Fox Bait';
		speed = 0;

		// Mark bait as placed on this street
		if (placedBait[streetName] == null) {
			placedBait[streetName] = [];
		}
		placedBait[streetName].add(this);

		states = {
			'stink1': new Spritesheet('stink1',
				'https://childrenofur.com/assets/entityImages/fox_bait__x1_stink1_png_1354839629.png', 861, 288, 41, 144, 42, true),
			'stink2': new Spritesheet('stink1',
				'https://childrenofur.com/assets/entityImages/fox_bait__x1_stink2_png_1354839630.png', 902, 288, 41, 144, 43, true),
			'stink3': new Spritesheet('stink1',
				'https://childrenofur.com/assets/entityImages/fox_bait__x1_stink3_png_1354839632.png', 861, 288, 41, 144, 42, true),
			'_hidden': NPC.TRANSPARENT_SPRITE
		};
		setState('stink${rand.nextInt(3) + 1}');

		// Add to street
		StreetUpdateHandler.streets[streetName]?.npcs[this.id] = this;

		// Go away after a while if not eaten by a fox
		new Future.delayed(MAX_TIME).then((_) => eat());
	}

	@override
	void update({bool simulateTick: false}) {
		super.update();

		// Fall to platforms
		moveXY();
	}

	Future eat() async {
		await new Future.delayed(EAT_TIME);
		setState('_hidden');
		StreetUpdateHandler.streets[streetName].npcs.remove(id);
		attractedFox = null;
	}

	String toString() => 'FoxBait at ($x, $y)';
}
