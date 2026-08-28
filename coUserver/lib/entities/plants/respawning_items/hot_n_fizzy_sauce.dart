part of entity;

class HotNFizzySauceRespawningItem extends RespawningItem {
	HotNFizzySauceRespawningItem(String id, num x, num y, num z, num rotation, bool h_flip, String streetName)
		: super(id, x, y, z, rotation, h_flip, streetName) {
		type = "Hot 'n' Fizzy Sauce";
		itemType = 'hot_n_fizzy_sauce';
		respawnTime = new Duration(minutes: 6);

		states = {
			'1-2-3-4': new Spritesheet('1-2-3-4',
				'files/sprites/generated/converted/hot_n_fizzy_sauce-1-2-3-4.png',
				164, 44, 41, 44, 4, false)
		};

		setState('1-2-3-4');
		maxState = 3;
	}
}
