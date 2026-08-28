part of entity;

class Cosma extends Shrine
{
	Cosma(String id, num x, num y, num z, num rotation, bool h_flip, String streetName) : super(id, x, y, z, rotation, h_flip, streetName)
	{
		// Sprite sheets converted locally from the CC0 tinyspeck/glitch-items
		// source (shrines/npc_shrine_cosma/npc_shrine_ix_cosma/npc_shrine_ix_cosma.swf)
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
				"close" : new Spritesheet("close","files/sprites/generated/converted/shrine_cosma-close.png",3380,216,169,216,20,false),
				"open" : new Spritesheet("open","files/sprites/generated/converted/shrine_cosma-open.png",4056,216,169,216,24,false),
				"still" : new Spritesheet("still","files/sprites/generated/converted/shrine_cosma-open.png",4056,216,169,216,1,false)
			};
	 	setState('still');
	 	type = 'Cosma';

	 	description = 'This is a shrine to Cosma. As the giant who governs the sky, Cosma is also the giant of levity and meditation. She is, also, the only giant capable of herding butterflies.';
	}
}

class CosmaFirebog extends Shrine
{
	CosmaFirebog(String id, num x, num y, num z, num rotation, bool h_flip, String streetName) : super(id, x, y, z, rotation, h_flip, streetName)
	{
		states =
		{
			"close" : new Spritesheet("close","https://childrenofur.com/assets/entityImages/npc_shrine_firebog_cosma__x1_close_png_1354832774.png",984,848,164,212,23,false),
			"open" : new Spritesheet("open","https://childrenofur.com/assets/entityImages/npc_shrine_firebog_cosma__x1_open_png_1354832771.png",984,848,164,212,22,false),
			"still" : new Spritesheet("still","https://childrenofur.com/assets/entityImages/npc_shrine_firebog_cosma__x1_open_png_1354832771.png",984,848,164,212,1,false)
		};
		setState('still');
		type = 'Cosma';

		description = 'This is a shrine to Cosma. As the giant who governs the sky, Cosma is also the giant of levity and meditation. She is, also, the only giant capable of herding butterflies.';
	}
}

class CosmaIx extends Shrine
{
	CosmaIx(String id, num x, num y, num z, num rotation, bool h_flip, String streetName) : super(id, x, y, z, rotation, h_flip, streetName)
	{
		states =
		{
			"close" : new Spritesheet("close","https://childrenofur.com/assets/entityImages/npc_shrine_ix_cosma__x1_close_png_1354831269.png",840,864,168,216,20,false),
			"open" : new Spritesheet("open","https://childrenofur.com/assets/entityImages/npc_shrine_ix_cosma__x1_open_png_1354831267.png",840,1080,168,216,24,false),
			"still" : new Spritesheet("still","https://childrenofur.com/assets/entityImages/npc_shrine_ix_cosma__x1_open_png_1354831267.png",840,1080,168,216,1,false)
		};
		setState('still');
		type = 'Cosma';

		description = 'This is a shrine to Cosma. As the giant who governs the sky, Cosma is also the giant of levity and meditation. She is, also, the only giant capable of herding butterflies.';
	}
}

class CosmaUralia extends Shrine
{
	CosmaUralia(String id, num x, num y, num z, num rotation, bool h_flip, String streetName) : super(id, x, y, z, rotation, h_flip, streetName)
	{
		states =
		{
			"close" : new Spritesheet("close","https://childrenofur.com/assets/entityImages/npc_shrine_uralia_cosma__x1_close_png_1354831869.png",756,752,126,188,23,false),
			"open" : new Spritesheet("open","https://childrenofur.com/assets/entityImages/npc_shrine_uralia_cosma__x1_open_png_1354831867.png",756,752,126,188,22,false),
			"still" : new Spritesheet("still","https://childrenofur.com/assets/entityImages/npc_shrine_uralia_cosma__x1_open_png_1354831867.png",756,752,126,188,1,false)
		};
		setState('still');
		type = 'Cosma';

		description = 'This is a shrine to Cosma. As the giant who governs the sky, Cosma is also the giant of levity and meditation. She is, also, the only giant capable of herding butterflies.';
	}
}