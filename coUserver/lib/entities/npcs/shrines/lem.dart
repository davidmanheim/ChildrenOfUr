part of entity;

class Lem extends Shrine
{
	Lem(String id, num x, num y, num z, num rotation, bool h_flip, String streetName) : super(id, x, y, z, rotation, h_flip, streetName)
	{
		// Sprite sheets converted locally from the CC0 tinyspeck/glitch-items
		// source (shrines/npc_shrine_lem/npc_shrine_ix_lem/npc_shrine_ix_lem.swf)
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
				"close" : new Spritesheet("close","files/sprites/generated/converted/shrine_lem-close.png",3380,216,169,216,20,false),
				"open" : new Spritesheet("open","files/sprites/generated/converted/shrine_lem-open.png",4056,216,169,216,24,false),
				"still" : new Spritesheet("still","files/sprites/generated/converted/shrine_lem-open.png",4056,216,169,216,1,false)
			};
	 	setState('still');
	 	type = 'Lem';

	 	description = 'This is a shrine to Lem, the giant of travel and navigation. If you\'ve ever found yourself somewhere you didn\'t plan to be, chances are it was a Lemish practical joke, for which he is utterly unrepentant.';
	}
}

class LemFirebog extends Shrine
{
	LemFirebog(String id, num x, num y, num z, num rotation, bool h_flip, String streetName) : super(id, x, y, z, rotation, h_flip, streetName)
	{
		states =
		{
			"close" : new Spritesheet("close","https://childrenofur.com/assets/entityImages/npc_shrine_firebog_lem__x1_close_png_1354832823.png",984,848,164,212,23,false),
			"open" : new Spritesheet("open","https://childrenofur.com/assets/entityImages/npc_shrine_firebog_lem__x1_open_png_1354832820.png",984,848,164,212,22,false),
			"still" : new Spritesheet("still","https://childrenofur.com/assets/entityImages/npc_shrine_firebog_lem__x1_open_png_1354832820.png",984,848,164,212,1,false)
		};
		setState('still');
		type = 'Lem';

		description = 'This is a shrine to Lem, the giant of travel and navigation. If you\'ve ever found yourself somewhere you didn\'t plan to be, chances are it was a Lemish practical joke, for which he is utterly unrepentant.';
	}
}

class LemIx extends Shrine
{
	LemIx(String id, num x, num y, num z, num rotation, bool h_flip, String streetName) : super(id, x, y, z, rotation, h_flip, streetName)
	{
		states =
		{
			"close" : new Spritesheet("close","https://childrenofur.com/assets/entityImages/npc_shrine_ix_lem__x1_close_png_1354831289.png",840,864,168,216,20,false),
			"open" : new Spritesheet("open","https://childrenofur.com/assets/entityImages/npc_shrine_ix_lem__x1_open_png_1354831287.png",840,1080,168,216,24,false),
			"still" : new Spritesheet("still","https://childrenofur.com/assets/entityImages/npc_shrine_ix_lem__x1_open_png_1354831287.png",840,1080,168,216,1,false)
		};
		setState('still');
		type = 'Lem';

		description = 'This is a shrine to Lem, the giant of travel and navigation. If you\'ve ever found yourself somewhere you didn\'t plan to be, chances are it was a Lemish practical joke, for which he is utterly unrepentant.';
	}
}

class LemUralia extends Shrine
{
	LemUralia(String id, num x, num y, num z, num rotation, bool h_flip, String streetName) : super(id, x, y, z, rotation, h_flip, streetName)
	{
		states =
		{
			"close" : new Spritesheet("close","https://childrenofur.com/assets/entityImages/npc_shrine_uralia_lem__x1_close_png_1354831897.png",756,752,126,188,23,false),
			"open" : new Spritesheet("open","https://childrenofur.com/assets/entityImages/npc_shrine_uralia_lem__x1_open_png_1354831895.png",756,752,126,188,22,false),
			"still" : new Spritesheet("still","https://childrenofur.com/assets/entityImages/npc_shrine_uralia_lem__x1_open_png_1354831895.png",756,752,126,188,1,false)
		};
		setState('still');
		type = 'Lem';

		description = 'This is a shrine to Lem, the giant of travel and navigation. If you\'ve ever found yourself somewhere you didn\'t plan to be, chances are it was a Lemish practical joke, for which he is utterly unrepentant.';
	}
}