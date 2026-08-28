part of entity;

class CocktailShakerRespawningItem extends RespawningItem {
	CocktailShakerRespawningItem(String id, num x, num y, num z, num rotation, bool h_flip, String streetName)
	: super(id, x, y, z, rotation, h_flip, streetName) {
		type = 'Cocktail Shaker';
		itemType = 'cocktail_shaker';
		respawnTime = new Duration(minutes: 45);

		states = {
			'1': new Spritesheet('1',
				'files/sprites/generated/converted/cocktail_shaker-1.png',
				125, 125, 125, 125, 1, false)
		};

		setState('1');
		maxState = 1;
	}
}
