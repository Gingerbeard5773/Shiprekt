#include "ShipsCommon.as";

void onTick(CRules@ this)
{
	if (getGameTime() % 200 > 0)
		return;
	
	/*Vec2f dim = getMap().getMapDimensions();
	
	CBlob@[] cores;
	getBlobsByTag("mothership", @cores);
	const u8 coresLength = cores.length;
	for (u8 i = 0; i < coresLength; ++i)
	{
		//keep motherships within bounds
		CBlob@ core = cores[i];
		Ship@ ship = getShip(core.getShape().getVars().customData);
		if (ship is null) continue;
		
		Vec2f pos = core.getPosition();
		const bool rightBorder = dim.x <= pos.x;
		const bool leftBorder = pos.x <= 0.0f;
		const bool bottomBorder = dim.y <= pos.y;
		const bool topBorder = pos.y <= 0.0f;
		
		if (topBorder) ship.pos.Set(ship.pos.x, 20.0f);
		else if (bottomBorder) ship.pos.Set(ship.pos.x, dim.y - 20.0f);
		else if (rightBorder) ship.pos.Set(dim.x - 20.0f, ship.pos.y);
		else if (leftBorder) ship.pos.Set(20.0f, ship.pos.y);
	}*/
	
	//warp ships to other border
	/*Ship[]@ ships;
	if (!this.get("ships", @ships))
		return;
		
	CMap@ map = getMap();
	const f32 mapwidth = map.tilesize*map.tilemapwidth;
	const f32 mapheight = map.tilesize*map.tilemapheight;
	const u16 shipsLength = ships.length;
	for (u16 i = 0; i < shipsLength; ++i)
	{
		Ship @ship = ships[i];
		if (ship.vel.x > 0.0f && ship.pos.x > mapwidth)
		{
			ship.old_pos.x = ship.pos.x;
			ship.old_pos.x -= ship.vel.x;
			ship.pos.x -= mapwidth;			
		}
		if (ship.vel.y > 0.0f && ship.pos.y > mapheight)
		{
			ship.old_pos.y = ship.pos.y;
			ship.old_pos.y -= ship.vel.y;
			ship.pos.y -= mapheight;
		}
		if (ship.vel.x < 0.0f && ship.pos.x < 0)
		{
			ship.old_pos.x = ship.pos.x;
			ship.old_pos.x -= ship.vel.x;
			ship.pos.x += mapwidth;			
		}
		if (ship.vel.y < 0.0f && ship.pos.y < 0)
		{
			ship.old_pos.y = ship.pos.y;
			ship.old_pos.y -= ship.vel.y;
			ship.pos.y += mapheight;		
		}
	}*/
}