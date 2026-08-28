part of entity;

class Alph extends Shrine
{
	Alph(String id, num x, num y, num z, num rotation, bool h_flip, String streetName) : super(id,x,y, z, rotation, h_flip, streetName)
	{
		// Sprite sheets converted locally from the CC0 tinyspeck/glitch-items
		// source (shrines/npc_shrine_alph/npc_shrine_ix_alph/npc_shrine_ix_alph.swf)
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
				"close" : new Spritesheet("close","files/sprites/generated/converted/shrine_alph-close.png",3380,216,169,216,20,false),
				"open" : new Spritesheet("open","files/sprites/generated/converted/shrine_alph-open.png",4056,216,169,216,24,false),
				"still" : new Spritesheet("still","files/sprites/generated/converted/shrine_alph-open.png",4056,216,169,216,1,false)
			};
	 	setState('still');
	 	type = 'Alph';

	 	description = 'This is a shrine to Alph, the giant of creation. If you\'ve ever wondered "Why do Piggies make meat?" or "Which came first: the chicken or the egg plant?" chances are Alph has the answer.';
	}
}

class AlphFirebog extends Shrine {
	AlphFirebog(String id, num x, num y, num z, num rotation, bool h_flip, String streetName) : super(id, x, y, z, rotation, h_flip, streetName) {
		states = {
			"close" : new Spritesheet("close","https://childrenofur.com/assets/entityImages/npc_shrine_firebog_alph__x1_close_png_1354832766.png",984, 848, 164, 212, 23, false),
			"open" : new Spritesheet("open","https://childrenofur.com/assets/entityImages/npc_shrine_firebog_alph__x1_open_png_1354832764.png",984, 848, 164, 212, 22, false),
			"still" : new Spritesheet("still","https://childrenofur.com/assets/entityImages/npc_shrine_firebog_alph__x1_open_png_1354832764.png", 984, 848, 164, 212, 1, false)
		};
		setState('still');
		type = 'Alph';

		description = 'This is a shrine to Alph, the giant of creation. If you\'ve ever wondered "Why do Piggies make meat?" or "Which came first: the chicken or the egg plant?" chances are Alph has the answer.';
	}
}

class AlphIx extends Shrine {
	AlphIx(String id, num x, num y, num z, num rotation, bool h_flip, String streetName) : super(id, x, y, z, rotation, h_flip, streetName) {
		states = {
			"close" : new Spritesheet("close","https://childrenofur.com/assets/entityImages/npc_shrine_ix_alph__x1_close_png_1354831264.png",840,864,168,216,20, false),
			"open" : new Spritesheet("open","https://childrenofur.com/assets/entityImages/npc_shrine_ix_alph__x1_open_png_1354831261.png",840,1080,168,216,24, false),
			"still" : new Spritesheet("still","https://childrenofur.com/assets/entityImages/npc_shrine_ix_alph__x1_open_png_1354831261.png", 840,1080,168,216, 1, false)
		};
		setState('still');
		type = 'Alph';

		description = 'This is a shrine to Alph, the giant of creation. If you\'ve ever wondered "Why do Piggies make meat?" or "Which came first: the chicken or the egg plant?" chances are Alph has the answer.';
	}
}

class AlphUralia extends Shrine {
	AlphUralia(String id, num x, num y, num z, num rotation, bool h_flip, String streetName) : super(id, x, y, z, rotation, h_flip, streetName) {
		states = {
			"close" : new Spritesheet("close","https://childrenofur.com/assets/entityImages/npc_shrine_uralia_alph__x1_close_png_1354831862.png",756, 752, 126, 188, 23, false),
			"open" : new Spritesheet("open","https://childrenofur.com/assets/entityImages/npc_shrine_uralia_alph__x1_open_png_1354831859.png",756, 752, 128, 188, 22, false),
			"still" : new Spritesheet("still","https://childrenofur.com/assets/entityImages/npc_shrine_uralia_alph__x1_open_png_1354831859.png", 756, 752, 128, 188, 1, false)
		};
		setState('still');
		type = 'Alph';

		description = 'This is a shrine to Alph, the giant of creation. If you\'ve ever wondered "Why do Piggies make meat?" or "Which came first: the chicken or the egg plant?" chances are Alph has the answer.';
	}
}