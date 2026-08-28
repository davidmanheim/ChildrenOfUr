part of entity;

class RacingCubimal extends EntityItem {
	static final Map<String, Spritesheet> SPRITESHEETS = {
		'race_batterfly': new Spritesheet('race',
			'files/sprites/generated/converted/cubimal_race-batterfly.png',
			2280, 42, 38, 42, 60, true),
		'race_bureaucrat': new Spritesheet('race',
			'files/sprites/generated/converted/cubimal_race-bureaucrat.png',
			2220, 29, 37, 29, 60, true),
		'race_butler': new Spritesheet('race',
			'files/sprites/generated/converted/cubimal_race-butler.png',
			2280, 28, 38, 28, 60, true),
		'race_butterfly': new Spritesheet('race',
			'files/sprites/generated/converted/cubimal_race-butterfly.png',
			2400, 38, 40, 38, 60, true),
		'race_cactus': new Spritesheet('race',
			'files/sprites/generated/converted/cubimal_race-cactus.png',
			2220, 28, 37, 28, 60, true),
		'race_chick': new Spritesheet('race',
			'files/sprites/generated/converted/cubimal_race-chick.png',
			2280, 34, 38, 34, 60, true),
		'race_crab': new Spritesheet('race',
			'files/sprites/generated/converted/cubimal_race-crab.png',
			2400, 33, 40, 33, 60, true),
		'race_craftybot': new Spritesheet('race',
			'files/sprites/generated/converted/cubimal_race-craftybot.png',
			2280, 28, 38, 28, 60, true),
		'race_deimaginator': new Spritesheet('race',
			'files/sprites/generated/converted/cubimal_race-deimaginator.png',
			2220, 32, 37, 32, 60, true),
		'race_dustbunny': new Spritesheet('race',
			'files/sprites/generated/converted/cubimal_race-dustbunny.png',
			2340, 26, 39, 26, 60, true),
		'race_emobear': new Spritesheet('race',
			'files/sprites/generated/converted/cubimal_race-emobear.png',
			2460, 29, 41, 29, 60, true),
		'race_factorydefect_chick': new Spritesheet('race',
			'files/sprites/generated/converted/cubimal_race-factorydefect_chick.png',
			3304, 39, 56, 39, 59, true),
		'race_firebogstreetspirit': new Spritesheet('race',
			'files/sprites/generated/converted/cubimal_race-firebogstreetspirit.png',
			2280, 31, 38, 31, 60, true),
		'race_firefly': new Spritesheet('race',
			'files/sprites/generated/converted/cubimal_race-firefly.png',
			2280, 37, 38, 37, 60, true),
		'race_fox': new Spritesheet('race',
			'files/sprites/generated/converted/cubimal_race-fox.png',
			2340, 30, 39, 30, 60, true),
		'race_foxranger': new Spritesheet('race',
			'files/sprites/generated/converted/cubimal_race-foxranger.png',
			2280, 28, 38, 28, 60, true),
		'race_frog': new Spritesheet('race',
			'files/sprites/generated/converted/cubimal_race-frog.png',
			2400, 32, 40, 32, 60, true),
		'race_gardeningtoolsvendor': new Spritesheet('race',
			'files/sprites/generated/converted/cubimal_race-gardeningtoolsvendor.png',
			2400, 34, 40, 34, 60, true),
		'race_gnome': new Spritesheet('race',
			'files/sprites/generated/converted/cubimal_race-gnome.png',
			2400, 33, 40, 33, 60, true),
		'race_greeterbot': new Spritesheet('race',
			'files/sprites/generated/converted/cubimal_race-greeterbot.png',
			2220, 30, 37, 30, 60, true),
		'race_groddlestreetspirit': new Spritesheet('race',
			'files/sprites/generated/converted/cubimal_race-groddlestreetspirit.png',
			2400, 36, 40, 36, 60, true),
		'race_gwendolyn': new Spritesheet('race',
			'files/sprites/generated/converted/cubimal_race-gwendolyn.png',
			2280, 28, 38, 28, 60, true),
		'race_helga': new Spritesheet('race',
			'files/sprites/generated/converted/cubimal_race-helga.png',
			2340, 33, 39, 33, 60, true),
		'race_hellbartender': new Spritesheet('race',
			'files/sprites/generated/converted/cubimal_race-hellbartender.png',
			3180, 65, 53, 65, 60, true),
		'race_ilmenskiejones': new Spritesheet('race',
			'files/sprites/generated/converted/cubimal_race-ilmenskiejones.png',
			2340, 35, 39, 35, 60, true),
		'race_juju': new Spritesheet('race',
			'files/sprites/generated/converted/cubimal_race-juju.png',
			2280, 29, 38, 29, 60, true),
		'race_magicrock': new Spritesheet('race',
			'files/sprites/generated/converted/cubimal_race-magicrock.png',
			2220, 26, 37, 26, 60, true),
		'race_maintenancebot': new Spritesheet('race',
			'files/sprites/generated/converted/cubimal_race-maintenancebot.png',
			2280, 30, 38, 30, 60, true),
		'race_mealvendor': new Spritesheet('race',
			'files/sprites/generated/converted/cubimal_race-mealvendor.png',
			2400, 32, 40, 32, 60, true),
		'race_phantom': new Spritesheet('race',
			'files/sprites/generated/converted/cubimal_race-phantom.png',
			2280, 35, 38, 35, 60, true),
		'race_piggy': new Spritesheet('race',
			'files/sprites/generated/converted/cubimal_race-piggy.png',
			2280, 30, 38, 30, 60, true),
		'race_rook': new Spritesheet('race',
			'files/sprites/generated/converted/cubimal_race-rook.png',
			2460, 31, 41, 31, 60, true),
		'race_rube': new Spritesheet('race',
			'files/sprites/generated/converted/cubimal_race-rube.png',
			2340, 28, 39, 28, 60, true),
		'race_scionofpurple': new Spritesheet('race',
			'files/sprites/generated/converted/cubimal_race-scionofpurple.png',
			2460, 37, 41, 37, 60, true),
		'race_senorfunpickle': new Spritesheet('race',
			'files/sprites/generated/converted/cubimal_race-senorfunpickle.png',
			2640, 35, 44, 35, 60, true),
		'race_sloth': new Spritesheet('race',
			'files/sprites/generated/converted/cubimal_race-sloth.png',
			2280, 31, 38, 31, 60, true),
		'race_smuggler': new Spritesheet('race',
			'files/sprites/generated/converted/cubimal_race-smuggler.png',
			2340, 29, 39, 29, 60, true),
		'race_snoconevendor': new Spritesheet('race',
			'files/sprites/generated/converted/cubimal_race-snoconevendor.png',
			2220, 30, 37, 30, 60, true),
		'race_squid': new Spritesheet('race',
			'files/sprites/generated/converted/cubimal_race-squid.png',
			2400, 30, 40, 30, 60, true),
		'race_toolvendor': new Spritesheet('race',
			'files/sprites/generated/converted/cubimal_race-toolvendor.png',
			2280, 30, 38, 30, 60, true),
		'race_trisor': new Spritesheet('race',
			'files/sprites/generated/converted/cubimal_race-trisor.png',
			2280, 26, 38, 26, 60, true),
		'race_unclefriendly': new Spritesheet('race',
			'files/sprites/generated/converted/cubimal_race-unclefriendly.png',
			2340, 32, 39, 32, 60, true),
		'race_uraliastreetspirit': new Spritesheet('race',
			'files/sprites/generated/converted/cubimal_race-uraliastreetspirit.png',
			2400, 33, 40, 33, 60, true),
		'race_yeti': new Spritesheet('race',
			'files/sprites/generated/converted/cubimal_race-yeti.png',
			2400, 32, 40, 32, 60, true),
	};

	String username;
	String email;

	RacingCubimal(String id, num x, num y, num z, num rotation, bool h_flip, String streetName)
	: super(id, x, y, z, rotation, h_flip, streetName) {
		type = 'Cubimal';
		states = SPRITESHEETS;
		actions = [];
		speed = 0;

		try {
			_init();
		} catch (e, st) {
			Log.error('Could not race cubimal $id', e, st);
		}
	}

	Future _init() async {
		// Fill in missing info
		username = await User.getUsernameFromId(ownerId);
		email = await User.getEmailFromId(ownerId);

		// Race
		String result = await race();

		// Notify everyone
		StreetUpdateHandler.streets[streetName].occupants.values.forEach((WebSocket userSocket) {
			toast(result, userSocket);
		});

		// Return item
		InventoryV2.addItemToUser(email, itemType, 1);
	}

	@override
	Future<bool> pickUp({WebSocket userSocket, String email}) async {
		toast('Wait for me to finish!', userSocket);
		return false;
	}

	Future<String> race() async {
		// How far to go, from 00.01 to 99.99 planks
		num key = rand.nextDouble() * 9 + 1;
		num value = pow(key, 2);

		// Round to 2 decimal places for display
		String str = value.toString();
		if (!str.contains('.')) {
			str += '.00';
		}
		str = str.substring(0, str.indexOf('.') + 3);
		num distance = num.parse(str);

		// Sit for 1 second
		speed = 0;
		await new Future.delayed(new Duration(seconds: 1));

		// Move at 5 planks per second
		speed = rand.nextInt(70) + 15;
		await new Future.delayed(new Duration(seconds: distance ~/ 5));

		// Stop and sit for 1 second
		speed = 0;
		await new Future.delayed(new Duration(seconds: 1));

		// Disappear
		await StreetEntities.deleteEntity(id);

		return "$username's $type travelled $distance planks before stopping";
	}
}

class RacingCubimal_batterfly extends RacingCubimal {
	RacingCubimal_batterfly(String id, num x, num y, num z, num rotation, bool h_flip, String streetName)
	: super (id, x, y, z, rotation, h_flip, streetName) {
		type = 'Batterfly Cubimal';
		setState('race_batterfly');
	}
}

class RacingCubimal_bureaucrat extends RacingCubimal {
	RacingCubimal_bureaucrat(String id, num x, num y, num z, num rotation, bool h_flip, String streetName)
	: super (id, x, y, z, rotation, h_flip, streetName) {
		type = 'Bureaucrat Cubimal';
		setState('race_bureaucrat');
	}
}

class RacingCubimal_butler extends RacingCubimal {
	RacingCubimal_butler(String id, num x, num y, num z, num rotation, bool h_flip, String streetName)
	: super (id, x, y, z, rotation, h_flip, streetName) {
		type = 'Butler Cubimal';
		setState('race_butler');
	}
}

class RacingCubimal_butterfly extends RacingCubimal {
	RacingCubimal_butterfly(String id, num x, num y, num z, num rotation, bool h_flip, String streetName)
	: super (id, x, y, z, rotation, h_flip, streetName) {
		type = 'Butterfly Cubimal';
		setState('race_butterfly');
	}
}

class RacingCubimal_cactus extends RacingCubimal {
	RacingCubimal_cactus(String id, num x, num y, num z, num rotation, bool h_flip, String streetName)
	: super (id, x, y, z, rotation, h_flip, streetName) {
		type = 'Cactus Cubimal';
		setState('race_cactus');
	}
}

class RacingCubimal_chick extends RacingCubimal {
	RacingCubimal_chick(String id, num x, num y, num z, num rotation, bool h_flip, String streetName)
	: super (id, x, y, z, rotation, h_flip, streetName) {
		type = 'Chick Cubimal';
		setState('race_chick');
	}
}

class RacingCubimal_crab extends RacingCubimal {
	RacingCubimal_crab(String id, num x, num y, num z, num rotation, bool h_flip, String streetName)
	: super (id, x, y, z, rotation, h_flip, streetName) {
		type = 'Crab Cubimal';
		setState('race_crab');
	}
}

class RacingCubimal_craftybot extends RacingCubimal {
	RacingCubimal_craftybot(String id, num x, num y, num z, num rotation, bool h_flip, String streetName)
	: super (id, x, y, z, rotation, h_flip, streetName) {
		type = 'Craftybot Cubimal';
		setState('race_craftybot');
	}
}

class RacingCubimal_deimaginator extends RacingCubimal {
	RacingCubimal_deimaginator(String id, num x, num y, num z, num rotation, bool h_flip, String streetName)
	: super (id, x, y, z, rotation, h_flip, streetName) {
		type = 'Deimaginator Cubimal';
		setState('race_deimaginator');
	}
}

class RacingCubimal_dustbunny extends RacingCubimal {
	RacingCubimal_dustbunny(String id, num x, num y, num z, num rotation, bool h_flip, String streetName)
	: super (id, x, y, z, rotation, h_flip, streetName) {
		type = 'Dustbunny Cubimal';
		setState('race_dustbunny');
	}
}

class RacingCubimal_emobear extends RacingCubimal {
	RacingCubimal_emobear(String id, num x, num y, num z, num rotation, bool h_flip, String streetName)
	: super (id, x, y, z, rotation, h_flip, streetName) {
		type = 'Emobear Cubimal';
		setState('race_emobear');
	}
}

class RacingCubimal_factorydefect_chick extends RacingCubimal {
	RacingCubimal_factorydefect_chick(String id, num x, num y, num z, num rotation, bool h_flip, String streetName)
	: super (id, x, y, z, rotation, h_flip, streetName) {
		type = 'Factory Defect Chick Cubimal';
		setState('race_factorydefect_chick');
	}

	@override
	Future<String> race() async {
		// How far to go, from 00.01 to 49.99 planks
		num distance = double.parse('${rand.nextInt(50)}.${rand.nextInt(99) + 1}');

		// Sit for 2 seconds
		speed = 0;
		await new Future.delayed(new Duration(seconds: 2));

		// Move at -10 planks per second
		speed = -(rand.nextInt(100) + 10);
		await new Future.delayed(new Duration(seconds: distance ~/ 10));

		// Stop and sit for 1 second
		speed = 0;
		await new Future.delayed(new Duration(seconds: 1));

		// Disappear
		await StreetEntities.deleteEntity(id);

		return "$username's $type travelled -$distance planks, and broke";
	}
}

class RacingCubimal_firebogstreetspirit extends RacingCubimal {
	RacingCubimal_firebogstreetspirit(String id, num x, num y, num z, num rotation, bool h_flip, String streetName)
	: super (id, x, y, z, rotation, h_flip, streetName) {
		type = 'Firebog Street Spirit Cubimal';
		setState('race_firebogstreetspirit');
	}
}

class RacingCubimal_firefly extends RacingCubimal {
	RacingCubimal_firefly(String id, num x, num y, num z, num rotation, bool h_flip, String streetName)
	: super (id, x, y, z, rotation, h_flip, streetName) {
		type = 'Firefly Cubimal';
		setState('race_firefly');
	}
}

class RacingCubimal_fox extends RacingCubimal {
	RacingCubimal_fox(String id, num x, num y, num z, num rotation, bool h_flip, String streetName)
	: super (id, x, y, z, rotation, h_flip, streetName) {
		type = 'Fox Cubimal';
		setState('race_fox');
	}
}

class RacingCubimal_foxranger extends RacingCubimal {
	RacingCubimal_foxranger(String id, num x, num y, num z, num rotation, bool h_flip, String streetName)
	: super (id, x, y, z, rotation, h_flip, streetName) {
		type = 'Fox Ranger Cubimal';
		setState('race_foxranger');
	}
}

class RacingCubimal_frog extends RacingCubimal {
	RacingCubimal_frog(String id, num x, num y, num z, num rotation, bool h_flip, String streetName)
	: super (id, x, y, z, rotation, h_flip, streetName) {
		type = 'Frog Cubimal';
		setState('race_frog');
	}
}

class RacingCubimal_gardeningtoolsvendor extends RacingCubimal {
	RacingCubimal_gardeningtoolsvendor(String id, num x, num y, num z, num rotation, bool h_flip, String streetName)
	: super (id, x, y, z, rotation, h_flip, streetName) {
		type = 'Gardening Tools Vendor Cubimal';
		setState('race_gardeningtoolsvendor');
	}
}

class RacingCubimal_gnome extends RacingCubimal {
	RacingCubimal_gnome(String id, num x, num y, num z, num rotation, bool h_flip, String streetName)
	: super (id, x, y, z, rotation, h_flip, streetName) {
		type = 'Gnome Cubimal';
		setState('race_gnome');
	}
}

class RacingCubimal_greeterbot extends RacingCubimal {
	RacingCubimal_greeterbot(String id, num x, num y, num z, num rotation, bool h_flip, String streetName)
	: super (id, x, y, z, rotation, h_flip, streetName) {
		type = 'Greeterbot Cubimal';
		setState('race_greeterbot');
	}
}

class RacingCubimal_groddlestreetspirit extends RacingCubimal {
	RacingCubimal_groddlestreetspirit(String id, num x, num y, num z, num rotation, bool h_flip, String streetName)
	: super (id, x, y, z, rotation, h_flip, streetName) {
		type = 'Groddle Street Spirit Cubimal';
		setState('race_groddlestreetspirit');
	}
}

class RacingCubimal_gwendolyn extends RacingCubimal {
	RacingCubimal_gwendolyn(String id, num x, num y, num z, num rotation, bool h_flip, String streetName)
	: super (id, x, y, z, rotation, h_flip, streetName) {
		type = 'Gwendolyn Cubimal';
		setState('race_gwendolyn');
	}
}

class RacingCubimal_helga extends RacingCubimal {
	RacingCubimal_helga(String id, num x, num y, num z, num rotation, bool h_flip, String streetName)
	: super (id, x, y, z, rotation, h_flip, streetName) {
		type = 'Helga Cubimal';
		setState('race_helga');
	}
}

class RacingCubimal_hellbartender extends RacingCubimal {
	RacingCubimal_hellbartender(String id, num x, num y, num z, num rotation, bool h_flip, String streetName)
	: super (id, x, y, z, rotation, h_flip, streetName) {
		type = 'Hell Bartender Cubimal';
		setState('race_hellbartender');
	}
}

class RacingCubimal_ilmenskiejones extends RacingCubimal {
	RacingCubimal_ilmenskiejones(String id, num x, num y, num z, num rotation, bool h_flip, String streetName)
	: super (id, x, y, z, rotation, h_flip, streetName) {
		type = 'Ilmenskie Jones Cubimal';
		setState('race_ilmenskiejones');
	}
}

class RacingCubimal_juju extends RacingCubimal {
	RacingCubimal_juju(String id, num x, num y, num z, num rotation, bool h_flip, String streetName)
	: super (id, x, y, z, rotation, h_flip, streetName) {
		type = 'Juju Cubimal';
		setState('race_juju');
	}
}

class RacingCubimal_magicrock extends RacingCubimal {
	RacingCubimal_magicrock(String id, num x, num y, num z, num rotation, bool h_flip, String streetName)
	: super (id, x, y, z, rotation, h_flip, streetName) {
		type = 'Magic Rock Cubimal';
		setState('race_magicrock');
	}
}

class RacingCubimal_maintenancebot extends RacingCubimal {
	RacingCubimal_maintenancebot(String id, num x, num y, num z, num rotation, bool h_flip, String streetName)
	: super (id, x, y, z, rotation, h_flip, streetName) {
		type = 'Maintenance Bot Cubimal';
		setState('race_maintenancebot');
	}
}

class RacingCubimal_mealvendor extends RacingCubimal {
	RacingCubimal_mealvendor(String id, num x, num y, num z, num rotation, bool h_flip, String streetName)
	: super (id, x, y, z, rotation, h_flip, streetName) {
		type = 'Meal Vendor Cubimal';
		setState('race_mealvendor');
	}
}

class RacingCubimal_phantom extends RacingCubimal {
	RacingCubimal_phantom(String id, num x, num y, num z, num rotation, bool h_flip, String streetName)
	: super (id, x, y, z, rotation, h_flip, streetName) {
		type = 'Phantom Cubimal';
		setState('race_phantom');
	}
}

class RacingCubimal_piggy extends RacingCubimal {
	RacingCubimal_piggy(String id, num x, num y, num z, num rotation, bool h_flip, String streetName)
	: super (id, x, y, z, rotation, h_flip, streetName) {
		type = 'Piggy Cubimal';
		setState('race_piggy');
	}
}

class RacingCubimal_rook extends RacingCubimal {
	RacingCubimal_rook(String id, num x, num y, num z, num rotation, bool h_flip, String streetName)
	: super (id, x, y, z, rotation, h_flip, streetName) {
		type = 'Rook Cubimal';
		setState('race_rook');
	}
}

class RacingCubimal_rube extends RacingCubimal {
	RacingCubimal_rube(String id, num x, num y, num z, num rotation, bool h_flip, String streetName)
	: super (id, x, y, z, rotation, h_flip, streetName) {
		type = 'Rube Cubimal';
		setState('race_rube');
	}
}

class RacingCubimal_scionofpurple extends RacingCubimal {
	RacingCubimal_scionofpurple(String id, num x, num y, num z, num rotation, bool h_flip, String streetName)
	: super (id, x, y, z, rotation, h_flip, streetName) {
		type = 'Scionofpurple Cubimal';
		setState('race_scionofpurple');
	}
}

class RacingCubimal_senorfunpickle extends RacingCubimal {
	RacingCubimal_senorfunpickle(String id, num x, num y, num z, num rotation, bool h_flip, String streetName)
	: super (id, x, y, z, rotation, h_flip, streetName) {
		type = 'Señor Funpickle Cubimal';
		setState('race_senorfunpickle');
	}
}

class RacingCubimal_sloth extends RacingCubimal {
	RacingCubimal_sloth(String id, num x, num y, num z, num rotation, bool h_flip, String streetName)
	: super (id, x, y, z, rotation, h_flip, streetName) {
		type = 'Sloth Cubimal';
		setState('race_sloth');
	}
}

class RacingCubimal_smuggler extends RacingCubimal {
	RacingCubimal_smuggler(String id, num x, num y, num z, num rotation, bool h_flip, String streetName)
	: super (id, x, y, z, rotation, h_flip, streetName) {
		type = 'Smuggler Cubimal';
		setState('race_smuggler');
	}
}

class RacingCubimal_snoconevendor extends RacingCubimal {
	RacingCubimal_snoconevendor(String id, num x, num y, num z, num rotation, bool h_flip, String streetName)
	: super (id, x, y, z, rotation, h_flip, streetName) {
		type = 'Sno Cone Vendor Cubimal';
		setState('race_snoconevendor');
	}
}

class RacingCubimal_squid extends RacingCubimal {
	RacingCubimal_squid(String id, num x, num y, num z, num rotation, bool h_flip, String streetName)
	: super (id, x, y, z, rotation, h_flip, streetName) {
		type = 'Squid Cubimal';
		setState('race_squid');
	}
}

class RacingCubimal_toolvendor extends RacingCubimal {
	RacingCubimal_toolvendor(String id, num x, num y, num z, num rotation, bool h_flip, String streetName)
	: super (id, x, y, z, rotation, h_flip, streetName) {
		type = 'Tool Vendor Cubimal';
		setState('race_toolvendor');
	}
}

class RacingCubimal_trisor extends RacingCubimal {
	RacingCubimal_trisor(String id, num x, num y, num z, num rotation, bool h_flip, String streetName)
	: super (id, x, y, z, rotation, h_flip, streetName) {
		type = 'Trisor Cubimal';
		setState('race_trisor');
	}
}

class RacingCubimal_unclefriendly extends RacingCubimal {
	RacingCubimal_unclefriendly(String id, num x, num y, num z, num rotation, bool h_flip, String streetName)
	: super (id, x, y, z, rotation, h_flip, streetName) {
		type = 'Uncle Friendly Cubimal';
		setState('race_unclefriendly');
	}
}

class RacingCubimal_uraliastreetspirit extends RacingCubimal {
	RacingCubimal_uraliastreetspirit(String id, num x, num y, num z, num rotation, bool h_flip, String streetName)
	: super (id, x, y, z, rotation, h_flip, streetName) {
		type = 'Uralia Street Spirit Cubimal';
		setState('race_uraliastreetspirit');
	}
}

class RacingCubimal_yeti extends RacingCubimal {
	RacingCubimal_yeti(String id, num x, num y, num z, num rotation, bool h_flip, String streetName)
	: super (id, x, y, z, rotation, h_flip, streetName) {
		type = 'Yeti Cubimal';
		setState('race_yeti');
	}
}