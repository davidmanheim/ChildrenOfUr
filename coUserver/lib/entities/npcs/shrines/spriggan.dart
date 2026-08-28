part of entity;

class Spriggan extends Shrine
{
	Spriggan(String id, num x, num y, num z, num rotation, bool h_flip, String streetName) : super(id, x, y, z, rotation, h_flip, streetName)
	{
		// Sprite sheets converted locally from the CC0 tinyspeck/glitch-items
		// source (shrines/npc_shrine_spriggan/npc_shrine_ix_spriggan/npc_shrine_ix_spriggan.swf)
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
			"close" : new Spritesheet("close","files/sprites/generated/converted/shrine_spriggan-close.png",3380,216,169,216,20,false),
			"open" : new Spritesheet("open","files/sprites/generated/converted/shrine_spriggan-open.png",4056,216,169,216,24,false),
			"still" : new Spritesheet("still","files/sprites/generated/converted/shrine_spriggan-open.png",4056,216,169,216,1,false)
		};
		setState('still');
		type = 'Spriggan';

		description = 'This is a shrine to Spriggan. Sure, Spriggan is the most taciturn and humorless of all the giants. You would be, too, if you had sole dominion over the trees. Trees are serious business, you know.';
	}
}

class SprigganFirebog extends Shrine
{
	SprigganFirebog(String id, num x, num y, num z, num rotation, bool h_flip, String streetName) : super(id, x, y, z, rotation, h_flip, streetName)
	{
		states =
		{
			"close" : new Spritesheet("close","https://childrenofur.com/assets/entityImages/npc_shrine_firebog_spriggan__x1_close_png_1354832843.png",984, 848, 164, 212, 23, false),
			"open" : new Spritesheet("open","https://childrenofur.com/assets/entityImages/npc_shrine_firebog_spriggan__x1_open_png_1354832841.png",984, 848, 164, 212, 22, false),
			"still" : new Spritesheet("still","https://childrenofur.com/assets/entityImages/npc_shrine_firebog_spriggan__x1_open_png_1354832841.png",984, 848, 164, 212, 1, false)
		};
		setState('still');
		type = 'Spriggan';

		description = 'This is a shrine to Spriggan. Sure, Spriggan is the most taciturn and humorless of all the giants. You would be, too, if you had sole dominion over the trees. Trees are serious business, you know.';
	}
}

class SprigganIx extends Shrine
{
	SprigganIx(String id, num x, num y, num z, num rotation, bool h_flip, String streetName) : super(id, x, y, z, rotation, h_flip, streetName)
	{
		states =
		{
			"close" : new Spritesheet("close","https://childrenofur.com/assets/entityImages/npc_shrine_ix_spriggan__x1_close_png_1354831304.png",840,864,168,216,20, false),
			"open" : new Spritesheet("open","https://childrenofur.com/assets/entityImages/npc_shrine_ix_spriggan__x1_open_png_1354831303.png",840,864,168,216,24, false),
			"still" : new Spritesheet("still","https://childrenofur.com/assets/entityImages/npc_shrine_ix_spriggan__x1_open_png_1354831303.png",840,864,168,216,1, false)
		};
		setState('still');
		type = 'Spriggan';

		description = 'This is a shrine to Spriggan. Sure, Spriggan is the most taciturn and humorless of all the giants. You would be, too, if you had sole dominion over the trees. Trees are serious business, you know.';
	}
}

class SprigganUralia extends Shrine
{
	SprigganUralia(String id, num x, num y, num z, num rotation, bool h_flip, String streetName) : super(id, x, y, z, rotation, h_flip, streetName)
	{
		states =
		{
			"close" : new Spritesheet("close","https://childrenofur.com/assets/entityImages/npc_shrine_uralia_spriggan__x1_close_png_1354831918.png",756, 752, 126, 188, 23, false),
			"open" : new Spritesheet("open","https://childrenofur.com/assets/entityImages/npc_shrine_uralia_spriggan__x1_open_png_1354831915.png",756, 752, 126, 188, 22, false),
			"still" : new Spritesheet("still","https://childrenofur.com/assets/entityImages/npc_shrine_uralia_spriggan__x1_open_png_1354831915.png",756, 752, 126, 188, 1, false),
		};
		setState('still');
		type = 'Spriggan';

		description = 'This is a shrine to Spriggan. Sure, Spriggan is the most taciturn and humorless of all the giants. You would be, too, if you had sole dominion over the trees. Trees are serious business, you know.';
	}
}