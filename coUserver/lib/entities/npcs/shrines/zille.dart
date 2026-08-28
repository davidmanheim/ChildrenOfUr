part of entity;

class Zille extends Shrine
{
	Zille(String id, num x, num y, num z, num rotation, bool h_flip, String streetName) : super(id, x, y, z, rotation, h_flip, streetName)
	{
		// Sprite sheets converted locally from the CC0 tinyspeck/glitch-items
		// source (shrines/npc_shrine_zille/npc_shrine_ix_zille/npc_shrine_ix_zille.swf)
		// via tools/build-sprite-sheet.py; see content/source-manifest.json for
		// provenance and content/runtime-manifest.json for the route entry.
		// No unsuffixed "base" source SWF exists in the fetched archive for any
		// giant shrine -- only the 3 regional reskins (Firebog/Ix/Uralia) do.
		// The Ix variant was used for this base class (an arbitrary but
		// consistent choice made identically across all 11 giants, documented
		// rather than guessed at random); the Firebog/Ix/Uralia subclasses below
		// remain on their original dead links, deferred to a future pass.
		states =
			{
				"close" : new Spritesheet("close","files/sprites/generated/converted/shrine_zille-close.png",3380,216,169,216,20,false),
				"open" : new Spritesheet("open","files/sprites/generated/converted/shrine_zille-open.png",4056,216,169,216,24,false),
				"still" : new Spritesheet("still","files/sprites/generated/converted/shrine_zille-open.png",4056,216,169,216,1,false)
			};
	 	setState('still');
	 	type = 'Zille';

	 	description = 'This is a shrine to Zille, the giant whose domain is the mountains. Hills, too. Also hillocks, pingos, drumlins and buttes. It\'s safe to consider that any bump in the ground is Zille\'s turf. She takes no responsibility, however, for volcanoes.';
	}
}

class ZilleFirebog extends Shrine
{
	ZilleFirebog(String id, num x, num y, num z, num rotation, bool h_flip, String streetName) : super(id, x, y, z, rotation, h_flip, streetName)
	{
		states =
		{
			"close" : new Spritesheet("close","https://childrenofur.com/assets/entityImages/npc_shrine_firebog_zille__x1_close_png_1354832857.png",984, 848, 164, 212, 23, false),
			"open" : new Spritesheet("open","https://childrenofur.com/assets/entityImages/npc_shrine_firebog_zille__x1_open_png_1354832855.png",984, 848, 164, 212, 22, false),
			"still" : new Spritesheet("still","https://childrenofur.com/assets/entityImages/npc_shrine_firebog_zille__x1_open_png_1354832855.png",984, 848, 164, 212, 1, false)
		};
		setState('still');
		type = 'Zille';

		description = 'This is a shrine to Zille, the giant whose domain is the mountains. Hills, too. Also hillocks, pingos, drumlins and buttes. It\'s safe to consider that any bump in the ground is Zille\'s turf. She takes no responsibility, however, for volcanoes.';
	}
}

class ZilleIx extends Shrine
{
	ZilleIx(String id, num x, num y, num z, num rotation, bool h_flip, String streetName) : super(id, x, y, z, rotation, h_flip, streetName)
	{
		states =
		{
			"close" : new Spritesheet("close","https://childrenofur.com/assets/entityImages/npc_shrine_ix_zille__x1_close_png_1354831310.png",840,864,168,216,20, false),
			"open" : new Spritesheet("open","https://childrenofur.com/assets/entityImages/npc_shrine_ix_zille__x1_open_png_1354831308.png",840,864,168,216,24, false),
			"still" : new Spritesheet("still","https://childrenofur.com/assets/entityImages/npc_shrine_ix_zille__x1_open_png_1354831308.png",840,864,168,216,1, false),
		};
		setState('still');
		type = 'Zille';

		description = 'This is a shrine to Zille, the giant whose domain is the mountains. Hills, too. Also hillocks, pingos, drumlins and buttes. It\'s safe to consider that any bump in the ground is Zille\'s turf. She takes no responsibility, however, for volcanoes.';
	}
}

class ZilleUralia extends Shrine
{
	ZilleUralia(String id, num x, num y, num z, num rotation, bool h_flip, String streetName) : super(id, x, y, z, rotation, h_flip, streetName)
	{
		states =
		{
			"close" : new Spritesheet("close","https://childrenofur.com/assets/entityImages/npc_shrine_uralia_zille__x1_close_png_1354831931.png",756, 752, 126, 188, 23, false),
			"open" : new Spritesheet("open","https://childrenofur.com/assets/entityImages/npc_shrine_uralia_zille__x1_open_png_1354831929.png",756, 752, 126, 188, 22, false),
			"still" : new Spritesheet("still","https://childrenofur.com/assets/entityImages/npc_shrine_uralia_zille__x1_open_png_1354831929.png",756, 752, 126, 188, 1, false),
		};
		setState('still');
		type = 'Zille';

		description = 'This is a shrine to Zille, the giant whose domain is the mountains. Hills, too. Also hillocks, pingos, drumlins and buttes. It\'s safe to consider that any bump in the ground is Zille\'s turf. She takes no responsibility, however, for volcanoes.';
	}
}