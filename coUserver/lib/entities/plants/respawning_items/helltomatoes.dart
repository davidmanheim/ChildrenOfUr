part of entity;

class HellTomato extends RespawningItem {
	HellTomato(String id, num x, num y, num z, num rotation, bool h_flip, String streetName)
	: super(id, x, y, z, rotation, h_flip, streetName) {
		type = 'Tomato';
		itemType = 'tomato';

		states = {
			'1-2-3-4': new Spritesheet('1-2-3-4',
				'files/sprites/generated/converted/hell_tomato-1-2-3-4.png',
				176, 40, 44, 40, 4, false)
		};

		setState('1-2-3-4');
		maxState = 3;
	}
}
