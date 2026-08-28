part of entity;

class Crab extends NPC {
	static final Map HEADPHONES = items["crabpod_headphones"].getMap();
	static final Map CRABATO = items["crabato_juice"].getMap();
	static final Map JUKEBOX = items["musicblock_bag"].getMap();

	static final String ERROR_NO_MUSIC = "You're musicblock-broke, yo.";
	static final String ERROR_BUSY = "Go away, I'm busy right now!";
	static final String WARN_HEADPHONES = "You stole my headphones! No juice for you!";

	static final List<String> MUSICBLOCK_TYPES = [
		"musicblock_bb_1",  "musicblock_bb_2",  "musicblock_bb_3",  "musicblock_bb_4",  "musicblock_bb_5",
		"musicblock_db_1",  "musicblock_db_2",  "musicblock_db_3",  "musicblock_db_4",  "musicblock_db_5",
		"musicblock_dg_1",  "musicblock_dg2",   "musicblock_dg3",   "musicblock_dg4",   "musicblock_dg5",
		"musicblock_dr_1",  "musicblock_dr_2",  "musicblock_dr_3",  "musicblock_dr_4",  "musicblock_dr_5",
		"musicblock_xs_1",  "musicblock_xs_2",  "musicblock_xs_3",  "musicblock_xs_4",  "musicblock_xs_5"
	];

	static final List<String> MUSICBLOCK_RARES = [
		"musicblock_gng", "musicblock_stoot", "musicblock_trumpets"
	];

	static List<String> get ALL_MUSICBLOCK_TYPES => new List()
		..addAll(MUSICBLOCK_TYPES)
		..addAll(MUSICBLOCK_RARES);

	/// Get a random music block itemType. Will not include rare types.
	static String randomMusicblock() {
		return MUSICBLOCK_TYPES[rand.nextInt(MUSICBLOCK_TYPES.length)];
	}

	/// Choose a random type of crab (there are different styles)
	final int IDLE_TYPE = rand.nextInt(3);

	/// Track user interaction
	String busyWithEmail = "";
	bool get busy => (busyWithEmail.length > 0);

	/// Most recently heard songs, with more recent items at higher indices
	List<String> listenHistory = new List();

	Crab(String id, num x, num y, num z, num rotation, bool h_flip, String streetName) : super(id, x, y, z, rotation, h_flip, streetName) {
		type = "Crab";
		speed = 60; // pixels per second

		actionTime = 0;
		ItemRequirements itemReq = new ItemRequirements()
			..any = ALL_MUSICBLOCK_TYPES
			..error = ERROR_NO_MUSIC;
		actions.addAll([
			new Action.withName('play for')
				..actionWord = 'crabbing'
				..itemRequirements = itemReq,
			new Action.withName('buy crabpack')
				..description = 'A 3,000-currant bag for 18 musicblocks'
				..actionWord = 'buying'
		]);

		states = {
			"dislike_off": new Spritesheet(
				"dislike_off", "files/sprites/generated/converted/crab-dislike_off.png",
				4256, 137, 133, 137, 32, true),
			"dislike_on": new Spritesheet(
				"dislike_on", "files/sprites/generated/converted/crab-dislike_on.png",
				4256, 137, 133, 137, 32, true),
			"idle0": new Spritesheet(
				"idle0", "files/sprites/generated/converted/crab-idle0.png",
				3990, 137, 133, 137, 30, true),
			"idle1": new Spritesheet(
				"idle1", "files/sprites/generated/converted/crab-idle1.png",
				3990, 137, 133, 137, 30, true),
			"idle2": new Spritesheet(
				"idle2", "files/sprites/generated/converted/crab-idle2.png",
				3990, 137, 133, 137, 30, true),
			"like_off": new Spritesheet(
				"like_off", "files/sprites/generated/converted/crab-like_off.png",
				4522, 137, 133, 137, 34, true),
			"like_on": new Spritesheet(
				"like_on", "files/sprites/generated/converted/crab-like_on.png",
				4522, 137, 133, 137, 34, true),
			"listen": new Spritesheet(
				"listen", "files/sprites/generated/converted/crab-listen.png",
				4522, 137, 133, 137, 34, true),
			"talk": new Spritesheet(
				"talk", "files/sprites/generated/converted/crab-talk.png",
				7714, 137, 133, 137, 58, false),
			"walk": new Spritesheet(
				"walk", "files/sprites/generated/converted/crab-walk.png",
				3192, 137, 133, 137, 24, true)
		};

		goIdle();
	}

	/// Switch to this crab's idle state
	void goIdle() => setState("idle$IDLE_TYPE");

	/// Walk around the street
	void update({bool simulateTick: false}) {
		if (!busy) {
			super.update();
			bool walking = (currentState.stateName == "walk");

			if (walking) {
				moveXY();
			}

			if (respawn != null && new DateTime.now().compareTo(respawn) > 0) {
				// 1 in 8 chance to change direction
				if (rand.nextInt(8) == 1) {
					facingRight = !facingRight;
				}

				int chance = rand.nextInt(5);
				if (chance > 3 || (chance > 2 && walking)) {
					setState("walk");
				} else {
					goIdle();
				}
			}
		}
	}

	/// Called from the client menu
	void playFor({WebSocket userSocket, String email}) {
		userSocket.add(jsonEncode({
			"action": "playMusic",
			"id": id,
			"openWindow": "itemChooser",
			"filter": "itemType=${ALL_MUSICBLOCK_TYPES.join('|')}",
			"windowTitle": "Play what for Crab?"
		}));
	}

	Future buyCrabpack({WebSocket userSocket, String email}) async {
		Metabolics metabolics = await getMetabolics(email: email);
		if (metabolics.currants >= JUKEBOX['price']) {
			metabolics.currants -= JUKEBOX['price'];
			await setMetabolics(metabolics);
			await InventoryV2.addItemToUser(email, JUKEBOX, 1, id);
		} else {
			toast("You can't afford to do that", userSocket);
		}
	}

	/// Adds a song to the history of the crab.
	/// If it is already in the list, it is moved to the end.
	void addToHistory(String music) {
		listenHistory
			..remove(music) // Remove from where it was before (if it was at all)
			..add(music); // Add to end of list
	}

	/// A crab likes a song if it is in the first half of the list (sorted oldest to newest)
	bool likesSong(String music) => listenHistory.indexOf(music) < listenHistory.length ~/ 2;

	/// How long the song plays for
	Duration randSongLength() => new Duration(seconds: rand.nextInt(11) + 5);

	/// How long the crab animates
	Duration randReactLength() => randSongLength() ~/ 2;

	Duration untilRespawn() => respawn.difference(new DateTime.now());

	/// Make the crab hear this noise
	Future playMusic({WebSocket userSocket, String email, String itemType, int count, int slot, int subSlot}) async {
		if (!busy) {
			// Allow interaction
			busyWithEmail = email;
		} else {
			// Only 1 player at a time
			say(ERROR_BUSY);
		}

		assert (userSocket != null);
		assert (email != null);
		assert (itemType != null && MUSICBLOCK_TYPES.contains(itemType));

		Future _takeMusicblock() => InventoryV2.takeItemFromUser(email, slot, subSlot, 1);
		Future _giveMusicblock() => InventoryV2.addItemToUser(email, items[itemType].getMap(), 1);
		Future _giveHeadphones() => InventoryV2.addItemToUser(email, HEADPHONES, 1, id);
		Future _takeHeadphones() => InventoryV2.takeAnyItemsFromUser(email, HEADPHONES["itemType"], 1);

		bool isRare = MUSICBLOCK_RARES.contains(itemType);

		if ((await _takeMusicblock()) == null) {
			// Could not take musicblock from player
			say(ERROR_NO_MUSIC);
			return;
		}

		await _giveHeadphones();

		setState("listen");
		await new Future.delayed(randSongLength() + untilRespawn());

		// Reward player
		if (likesSong(itemType)) {
			// Dance for a bit

			setState("like_on");
			await new Future.delayed(randReactLength() + untilRespawn());

			setState("like_off");
			await _giveMusicblock();

			if (await _takeHeadphones() < 1) {
				// Headphones are gone (collectible)
				say(WARN_HEADPHONES);
			} else {
				// Headphones returned, award crabato juice
				await InventoryV2.addItemToUser(email, CRABATO, 1, id);
			}
		} else {
			// Be crabby

			setState("dislike_on");
			await new Future.delayed(randReactLength() + untilRespawn());

			setState("like_off");
			await _giveMusicblock();
			await _takeHeadphones();
		}

		await trySetMetabolics(email, energy: -1, mood: 1, imgMin: (isRare ? 5 : 1), imgRange: 2);

		// Affect future listens
		addToHistory(itemType);
		busyWithEmail = "";
	}
}