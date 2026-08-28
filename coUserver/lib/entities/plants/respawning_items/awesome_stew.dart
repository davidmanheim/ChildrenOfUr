part of entity;

class AwesomeStewRespawningItem extends RespawningItem {
	AwesomeStewRespawningItem(String id, num x, num y, num z, num rotation, bool h_flip, String streetName)
	: super(id, x, y, z, rotation, h_flip, streetName) {
		type = 'Awesome Stew';
		itemType = 'awesome_stew';
		respawnTime = new Duration(hours: 2);

		states = {
			'1-2-3-4': new Spritesheet('1-2-3-4',
				'files/sprites/generated/converted/awesome_stew-1-2-3-4.png',
				176, 41, 44, 41, 4, false)
		};

		setState('1-2-3-4');
		maxState = 3;
	}
}
