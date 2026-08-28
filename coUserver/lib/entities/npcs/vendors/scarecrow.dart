part of entity;

class GardeningGoodsVendor extends Vendor implements EventHandler<PlayerPosition> {
	// `List<Map>`, not `List<Map<String, dynamic>>`: Item.getMap() (item.dart)
	// is declared `Map getMap() => {...}`, which Dart infers as
	// `Map<dynamic, dynamic>` from the untyped return type, not
	// `Map<String, dynamic>` -- the stricter generic here threw
	// "type '_InternalLinkedHashMap<dynamic, dynamic>' is not a subtype of
	// type 'Map<String, dynamic>'" the moment this class was actually
	// constructed (dart:mirrors reflective construction via street.dart's
	// putEntitiesInMemory), confirmed live 2026-08-28 during this class's
	// first-ever placement pass -- never triggered before since the class
	// was never placed anywhere. Vendor's own `itemsForSale` field
	// (vendor.dart) is untyped `List<Map>` for the same reason. No gameplay
	// behavior changes; this is a type-annotation-only fix.
	static final List<Map> SELL_ITEMS = [
		items['hoe'].getMap(),
		items['watering_can'].getMap(),
		items['broccoli_seed'].getMap(),
		items['cabbage_seed'].getMap(),
		items['carrot_seed'].getMap(),
		items['corn_seed'].getMap(),
		items['cucumber_seed'].getMap(),
		items['onion_seed'].getMap(),
		items['parsnip_seed'].getMap(),
		items['potato_seed'].getMap(),
		items['pumpkin_seed'].getMap(),
		items['rice_seed'].getMap(),
		items['spinach_seed'].getMap(),
		items['tomato_seed'].getMap(),
		items['zucchini_seed'].getMap()
	];

	static final Map<String, Spritesheet> SPRITESHEETS = {
		'attract': new Spritesheet('attract',
			'files/sprites/generated/converted/scarecrow-attract.png', 5610, 209, 187, 209, 30, true),
		'idle_stand': new Spritesheet('idle_stand',
			'files/sprites/generated/converted/scarecrow-idle_stand.png', 48620, 209, 187, 209, 260, true),
		'talk': new Spritesheet('talk',
			'files/sprites/generated/converted/scarecrow-talk.png', 4862, 209, 187, 209, 26, false),
		'walk_end': new Spritesheet('walk_end',
			'files/sprites/generated/converted/scarecrow-walk_end.png', 2431, 209, 187, 209, 13, false),
		'walk': new Spritesheet('walk',
			'files/sprites/generated/converted/scarecrow-walk.png', 3927, 209, 187, 209, 21, true),
		'turn_left': new Spritesheet('walk',
			'files/sprites/generated/converted/scarecrow-walk.png', 3927, 209, 187, 209, 21, true),
		'turn_right': new Spritesheet('walk',
			'files/sprites/generated/converted/scarecrow-walk.png', 3927, 209, 187, 209, 21, true),
	};

	int openCount = 0;

	GardeningGoodsVendor(String id, String streetName, String tsid, num x, num y, num z, num rotation, bool h_flip)
	: super(id, streetName, tsid, x, y, z, rotation, h_flip) {
		type = 'Gardening Goods Vendor';
		speed = 0;

		states = SPRITESHEETS;
		setState('idle_stand');

		itemsPredefined = true;
		itemsForSale = SELL_ITEMS;

		// See chicken.dart's identical fix: whereFunc must match message_bus's
		// `bool Function(dynamic)` typedef exactly, or this throws when the
		// class is constructed reflectively (dart:mirrors) via street.dart's
		// entity factory.
		messageBus.subscribe(PlayerPosition, this, whereFunc: (dynamic position) {
			return position is PlayerPosition && position.streetName == streetName;
		});
	}


	@override
	Map<String, dynamic> headers;

	@override
	void handleEvent(PlayerPosition event) {
		if(event.email == specialScarecrowEmail && _approx(x,event.x) && _approx(y,event.y)) {
			setState('walk', repeat: 10, thenState: currentState.stateName);
		}
	}

	bool _approx(num compare, num to) {
		return (compare - to).abs() < 150;
	}

	void update({bool simulateTick: false}) {
		super.update();

		// update x and y
		if (currentState.stateName == 'walk') {
			moveXY(
				wallAction: (Wall wall) {
					// Don't turn around
					return;
				},
				ledgeAction: () {
					// Float, don't fall
					return;
				}
			);
		}

		if (respawn != null && new DateTime.now().isAfter(respawn)) {
			if (rand.nextInt(4) > 2) {
				// 50% chance of trying to attract buyers for 5 seconds
				setState('attract', repeatFor: new Duration(seconds: 5));
			} else {
				// Wait for 20 seconds
				setState('idle_stand', repeatFor: new Duration(seconds: 20));
			}
		}
	}

	void buy({WebSocket userSocket, String email}) {
		setState('idle_stand');
		// don't go to another state until closed
		respawn = new DateTime.now().add(new Duration(days:50));
		openCount++;

		super.buy(userSocket:userSocket, email:email);
	}

	void sell({WebSocket userSocket, String email}) {
		setState('talk');
		// don't go to another state until closed
		respawn = new DateTime.now().add(new Duration(days:50));
		openCount++;

		super.sell(userSocket:userSocket, email:email);
	}

	void close({WebSocket userSocket, String email}) {
		openCount -= 1;
		// if no one else has them open
		if (openCount <= 0) {
			openCount = 0;
			setState('idle_stand');
		}
	}
}
