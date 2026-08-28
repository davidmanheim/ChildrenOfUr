part of entity;

class Friendly extends Shrine
{
	Friendly(String id, num x, num y, num z, num rotation, bool h_flip, String streetName) : super(id, x, y, z, rotation, h_flip, streetName)
	{
		// Sprite sheets converted locally from the CC0 tinyspeck/glitch-items
		// source (shrines/npc_shrine_friendly/npc_shrine_ix_friendly/npc_shrine_ix_friendly.swf)
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
				"close" : new Spritesheet("close","files/sprites/generated/converted/shrine_friendly-close.png",3380,216,169,216,20,false),
				"open" : new Spritesheet("open","files/sprites/generated/converted/shrine_friendly-open.png",4056,216,169,216,24,false),
				"still" : new Spritesheet("still","files/sprites/generated/converted/shrine_friendly-open.png",4056,216,169,216,1,false)
			};
	 	setState('still');
	 	type = 'Friendly';

	 	description = 'This is a shrine to Friendly, the giant who oversees all things celestial, nocturnal, lunar, stygian and murky. Despite this, he is, as his name implies, considered by many to be the nicest of the giants and the one most likely to loan you twenty currants till payday.';
	}
}

class FriendlyFirebog extends Shrine
{
	FriendlyFirebog(String id, num x, num y, num z, num rotation, bool h_flip, String streetName) : super(id, x, y, z, rotation, h_flip, streetName)
	{
		states =
		{
			"close" : new Spritesheet("close","https://childrenofur.com/assets/entityImages/npc_shrine_firebog_friendly__x1_close_png_1354832801.png",984,848,164,212,23,false),
			"open" : new Spritesheet("open","https://childrenofur.com/assets/entityImages/npc_shrine_firebog_friendly__x1_open_png_1354832798.png",984,848,164,212,22,false),
			"still" : new Spritesheet("still","https://childrenofur.com/assets/entityImages/npc_shrine_firebog_friendly__x1_open_png_1354832798.png",984,848,164,212,1,false)
		};
		setState('still');
		type = 'Friendly';

		description = 'This is a shrine to Friendly, the giant who oversees all things celestial, nocturnal, lunar, stygian and murky. Despite this, he is, as his name implies, considered by many to be the nicest of the giants and the one most likely to loan you twenty currants till payday.';
	}
}

class FriendlyIx extends Shrine
{
	FriendlyIx(String id, num x, num y, num z, num rotation, bool h_flip, String streetName) : super(id, x, y, z, rotation, h_flip, streetName)
	{
		states =
		{
			"close" : new Spritesheet("close","https://childrenofur.com/assets/entityImages/npc_shrine_ix_friendly__x1_close_png_1354831273.png",840,864,168,216,20,false),
			"open" : new Spritesheet("open","https://childrenofur.com/assets/entityImages/npc_shrine_ix_friendly__x1_open_png_1354831272.png",840,1080,168,216,24,false),
			"still" : new Spritesheet("still","https://childrenofur.com/assets/entityImages/npc_shrine_ix_friendly__x1_open_png_1354831272.png",840,1080,168,216,1,false)
		};
		setState('still');
		type = 'Friendly';

		description = 'This is a shrine to Friendly, the giant who oversees all things celestial, nocturnal, lunar, stygian and murky. Despite this, he is, as his name implies, considered by many to be the nicest of the giants and the one most likely to loan you twenty currants till payday.';
	}
}

class FriendlyUralia extends Shrine
{
	FriendlyUralia(String id, num x, num y, num z, num rotation, bool h_flip, String streetName) : super(id, x, y, z, rotation, h_flip, streetName)
	{
		states =
		{
			"close" : new Spritesheet("close","https://childrenofur.com/assets/entityImages/npc_shrine_uralia_friendly__x1_close_png_1354831876.png",756,752,126,188,23,false),
			"open" : new Spritesheet("open","https://childrenofur.com/assets/entityImages/npc_shrine_uralia_friendly__x1_open_png_1354831874.png",756,752,126,188,22,false),
			"still" : new Spritesheet("still","https://childrenofur.com/assets/entityImages/npc_shrine_uralia_friendly__x1_open_png_1354831874.png",756,752,126,188,1,false)
		};
		setState('still');
		type = 'Friendly';

		description = 'This is a shrine to Friendly, the giant who oversees all things celestial, nocturnal, lunar, stygian and murky. Despite this, he is, as his name implies, considered by many to be the nicest of the giants and the one most likely to loan you twenty currants till payday.';
	}
}