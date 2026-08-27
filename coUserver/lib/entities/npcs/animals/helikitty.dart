part of entity;

class HeliKitty extends NPC {
	int age;
    static final String SKILL = 'animal_kinship';

	HeliKitty(String id, num x, num y, num z, num rotation, bool h_flip, String streetName) : super(id, x, y, z, rotation, h_flip, streetName) {
		type = "Heli Kitty";
		actions.add(
			new Action.withName('pet')
				..timeRequired = actionTime
				..actionWord = 'petting'
				..energyRequirements = new EnergyRequirements(energyAmount: 5)
		);
		speed = 75; //pixels per second
		renameable = true;
		age = 3; //TODO: make them get older
		// Sprite sheets converted locally from the CC0 tinyspeck/glitch-items
		// source (inhabitants/heli_kitty/npc_kitty_chicken.swf, DefineSprite
		// 115 "kitty" -- the single combined timeline holding all three age
		// variations back-to-back via "1"/"2"/"3"-prefixed frame labels,
		// matching this class's own naming) via tools/build-sprite-sheet.py;
		// see content/source-manifest.json for provenance and
		// content/runtime-manifest.json for the route entry. These replace
		// the previous hardcoded links to the retired childrenofur.com asset
		// host. Real resolved frame counts matched every prior hardcoded
		// value except 2blink (was guessed 20, really 5) and 2sleep (was
		// guessed 26, really 57); those two now use the source-derived
		// values. The old data also pointed both "2fly" and "3fly" at the
		// same file (a copy/paste artifact) -- they are now two genuinely
		// distinct converted sprites (frames 160-179 vs 303-322).
		const String base = "files/sprites/generated/converted/helikitty-";
		states = {
			// newborn (variation 1)
			"1blink": new Spritesheet("1blink", "${base}1blink.png", 620, 102, 124, 102, 5, false),
			"1jumpAntic": new Spritesheet("1jumpAntic", "${base}1jumpAntic.png", 992, 102, 124, 102, 8, false),
			"1jump": new Spritesheet("1jump", "${base}1jump.png", 1984, 102, 124, 102, 16, true),
			"1rollStart": new Spritesheet("1rollStart", "${base}1rollStart.png", 248, 102, 124, 102, 2, false),
			"1roll": new Spritesheet("1roll", "${base}1roll.png", 1488, 102, 124, 102, 12, true),
			"1sleepStart": new Spritesheet("1sleepStart", "${base}1sleepStart.png", 3224, 102, 124, 102, 26, false),
			"1sleep": new Spritesheet("1sleep", "${base}1sleep.png", 7068, 102, 124, 102, 57, true),
			// kitten (variation 2)
			"2blink": new Spritesheet("2blink", "${base}2blink.png", 620, 102, 124, 102, 5, true),
			"2fly": new Spritesheet("2fly", "${base}2fly.png", 2480, 102, 124, 102, 20, true),
			"2hitBall": new Spritesheet("2hitBall", "${base}2hitBall.png", 1116, 102, 124, 102, 9, false),
			"2jumpAntic": new Spritesheet("2jumpAntic", "${base}2jumpAntic.png", 992, 102, 124, 102, 8, false),
			"2jump": new Spritesheet("2jump", "${base}2jump.png", 1984, 102, 124, 102, 16, true),
			"2sleepStart": new Spritesheet("2sleepStart", "${base}2sleepStart.png", 3224, 102, 124, 102, 26, false),
			"2sleep": new Spritesheet("2sleep", "${base}2sleep.png", 7068, 102, 124, 102, 57, true),
			// adult (variation 3)
			"3appear": new Spritesheet("3appear", "${base}3appear.png", 5828, 102, 124, 102, 47, false),
			"3blink": new Spritesheet("3blink", "${base}3blink.png", 620, 102, 124, 102, 5, false),
			"3chew": new Spritesheet("3chew", "${base}3chew.png", 1860, 102, 124, 102, 15, true),
			"3disappear": new Spritesheet("3disappear", "${base}3disappear.png", 3348, 102, 124, 102, 27, false),
			"3fly": new Spritesheet("3fly", "${base}3fly.png", 2480, 102, 124, 102, 20, true),
			"3happy": new Spritesheet("3happy", "${base}3happy.png", 4712, 102, 124, 102, 38, false),
			"3hitBall": new Spritesheet("3hitBall", "${base}3hitBall.png", 1116, 102, 124, 102, 9, false),
			"3jumpAntic": new Spritesheet("3jumpAntic", "${base}3jumpAntic.png", 992, 102, 124, 102, 8, false),
			"3jump": new Spritesheet("3jump", "${base}3jump.png", 1984, 102, 124, 102, 16, true),
			"3sad": new Spritesheet("3sad", "${base}3sad.png", 2108, 102, 124, 102, 17, false),
			"3sleepStart": new Spritesheet("3sleepStart", "${base}3sleepStart.png", 3224, 102, 124, 102, 26, false),
			"3sleep": new Spritesheet("3sleep", "${base}3sleep.png", 7068, 102, 124, 102, 57, true)
		};
		setState(sheetName("fly"));
		responses = {
			"pet": [":3"]
		};
	}

	Future<bool> pet({WebSocket userSocket, String email}) async {
		bool success = await super.trySetMetabolics(email, energy:-5, mood:20, imgMin:10, imgRange:4);
		if(!success) {
			return false;
		}
		setState(sheetName("hitBall"));
		StatManager.add(email, Stat.heli_kitties_petted);
        SkillManager.learn(SKILL, email);
		playSound('purr', userSocket);
		say(responses['pet'].elementAt(rand.nextInt(responses['pet'].length)));
		return true;
	}

	update({bool simulateTick: false}) {
		super.update();

		if (currentState.stateName.contains("fly")) {
			moveXY(yAction: () {}, ledgeAction: () {});
		}

		// If respawn is in the past, it is time to choose a new animation
		if(respawn != null && new DateTime.now().compareTo(respawn) > 0) {
			setState(sheetName("fly"));
			respawn = null;
			// 50% chance to change direction
			if(rand.nextInt(2) == 1) {
				facingRight = !facingRight;
			}
		}
	}

	String sheetName(String sheet) {
		// Returns the correct sprite sheet for the heli kitty's age
		// Use only for sheets that exist in all three ages
		return age.toString() + sheet;
	}
}
