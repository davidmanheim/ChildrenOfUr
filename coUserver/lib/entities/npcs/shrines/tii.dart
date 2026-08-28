part of entity;

class Tii extends Shrine
{
	Tii(String id, num x, num y, num z, num rotation, bool h_flip, String streetName) : super(id, x, y, z, rotation, h_flip, streetName)
	{
		// Sprite sheets converted locally from the CC0 tinyspeck/glitch-items
		// source (shrines/npc_shrine_ti/npc_shrine_ix_ti/npc_shrine_ix_ti.swf) via
		// tools/build-sprite-sheet.py; see content/source-manifest.json for
		// provenance and content/runtime-manifest.json for the route entry.
		// No unsuffixed "base" source SWF exists in the fetched archive for any
		// giant shrine -- only the 3 regional reskins (Firebog/Ix/Uralia) do.
		// The Ix variant was used for this base class (an arbitrary but
		// consistent choice made identically across all 11 giants, documented
		// rather than guessed at random); the Firebog/Ix/Uralia subclasses below
		// remain on their original dead links, deferred to a future pass.
		states =
			{
				"close" : new Spritesheet("close","files/sprites/generated/converted/shrine_ti-close.png",3380,216,169,216,20,false),
				"open" : new Spritesheet("open","files/sprites/generated/converted/shrine_ti-open.png",4056,216,169,216,24,false),
				"still" : new Spritesheet("still","files/sprites/generated/converted/shrine_ti-open.png",4056,216,169,216,1,false)
			};
	 	setState('still');
	 	type = 'Tii';

	 	description = 'This is a shrine to Tii, the overseer of elements, and the giant who manipulates all matters alchemical. Unlike the other giants, Tii is neither male nor female. Or both male and female. It\'s either really simple or really confusing, depending how you look at it. Some reckon this is why Tii seems cold and distant. They are incorrect. Tii is merely calculating and combining. It\'s distracting.';
	}
}

class TiiFirebog extends Shrine
{
	TiiFirebog(String id, num x, num y, num z, num rotation, bool h_flip, String streetName) : super(id, x, y, z, rotation, h_flip, streetName)
	{
		states =
		{
			"close" : new Spritesheet("close","https://childrenofur.com/assets/entityImages/npc_shrine_firebog_tii__x1_close_png_1354832850.png",984, 848, 164, 212, 23, false),
			"open" : new Spritesheet("open","https://childrenofur.com/assets/entityImages/npc_shrine_firebog_tii__x1_open_png_1354832848.png",984, 848, 164, 212, 22, false),
			"still" : new Spritesheet("still","https://childrenofur.com/assets/entityImages/npc_shrine_firebog_tii__x1_open_png_1354832848.png",984, 848, 164, 212, 1, false)
		};
		setState('still');
		type = 'Tii';

		description = 'This is a shrine to Tii, the overseer of elements, and the giant who manipulates all matters alchemical. Unlike the other giants, Tii is neither male nor female. Or both male and female. It\'s either really simple or really confusing, depending how you look at it. Some reckon this is why Tii seems cold and distant. They are incorrect. Tii is merely calculating and combining. It\'s distracting.';
	}
}

class TiiIx extends Shrine
{
	TiiIx(String id, num x, num y, num z, num rotation, bool h_flip, String streetName) : super(id, x, y, z, rotation, h_flip, streetName)
	{
		states =
		{
			"close" : new Spritesheet("close","https://childrenofur.com/assets/entityImages/npc_shrine_ix_ti__x1_close_png_1354831314.png",840,864,168,216,20, false),
			"open" : new Spritesheet("open","https://childrenofur.com/assets/entityImages/npc_shrine_ix_ti__x1_open_png_1354831313.png",840,864,168,216,24, false),
			"still" : new Spritesheet("still","https://childrenofur.com/assets/entityImages/npc_shrine_ix_ti__x1_open_png_1354831313.png",840,864,168,216,20, false),
		};
		setState('still');
		type = 'Tii';

		description = 'This is a shrine to Tii, the overseer of elements, and the giant who manipulates all matters alchemical. Unlike the other giants, Tii is neither male nor female. Or both male and female. It\'s either really simple or really confusing, depending how you look at it. Some reckon this is why Tii seems cold and distant. They are incorrect. Tii is merely calculating and combining. It\'s distracting.';
	}
}

class TiiUralia extends Shrine
{
	TiiUralia(String id, num x, num y, num z, num rotation, bool h_flip, String streetName) : super(id, x, y, z, rotation, h_flip, streetName)
	{
		states =
		{
			"close" : new Spritesheet("close","https://childrenofur.com/assets/entityImages/npc_shrine_uralia_ti__x1_close_png_1354831924.png",756, 752, 126, 188, 23, false),
			"open" : new Spritesheet("open","https://childrenofur.com/assets/entityImages/npc_shrine_uralia_ti__x1_open_png_1354831922.png",756, 752, 126, 188, 22, false),
			"still" : new Spritesheet("still","https://childrenofur.com/assets/entityImages/npc_shrine_uralia_ti__x1_open_png_1354831922.png",756, 752, 126, 188, 1, false),
		};
		setState('still');
		type = 'Tii';

		description = 'This is a shrine to Tii, the overseer of elements, and the giant who manipulates all matters alchemical. Unlike the other giants, Tii is neither male nor female. Or both male and female. It\'s either really simple or really confusing, depending how you look at it. Some reckon this is why Tii seems cold and distant. They are incorrect. Tii is merely calculating and combining. It\'s distracting.';
	}
}