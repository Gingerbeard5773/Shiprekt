#include "IslandsCommon.as";

void onTick(CRules@ this)
{
	if (getGameTime() % 200 > 0)
		return;
	
	/*Vec2f dim = getMap().getMapDimensions();
	
	CBlob@[] cores;
	getBlobsByTag("mothership", @cores);
	for (uint i = 0; i < cores.length; ++i)
	{
		//keep motherships within bounds
		CBlob@ core = cores[i];
		Island@ island = getIsland(core.getShape().getVars().customData);
		if (island is null) continue;
		
		Vec2f pos = core.getPosition();
		const bool rightBorder = dim.x <= pos.x;
		const bool leftBorder = pos.x <= 0.0f;
		const bool bottomBorder = dim.y <= pos.y;
		const bool topBorder = pos.y <= 0.0f;
		
		if (topBorder) island.pos.Set(island.pos.x, 20.0f);
		else if (bottomBorder) island.pos.Set(island.pos.x, dim.y - 20.0f);
		else if (rightBorder) island.pos.Set(dim.x - 20.0f, island.pos.y);
		else if (leftBorder) island.pos.Set(20.0f, island.pos.y);
	}*/
	
	//warp islands to other border
	/*Island[]@ islands;
	if (!this.get("islands", @islands))
		return;
		
	CMap@ map = getMap();
	const f32 mapwidth = map.tilesize*map.tilemapwidth;
	const f32 mapheight = map.tilesize*map.tilemapheight;	
	for (uint i = 0; i < islands.length; ++i)
	{
		Island @isle = islands[i];
		if (isle.vel.x > 0.0f && isle.pos.x > mapwidth)
		{
			isle.old_pos.x = isle.pos.x;
			isle.old_pos.x -= isle.vel.x;
			isle.pos.x -= mapwidth;			
		}
		if (isle.vel.y > 0.0f && isle.pos.y > mapheight)
		{
			isle.old_pos.y = isle.pos.y;
			isle.old_pos.y -= isle.vel.y;
			isle.pos.y -= mapheight;
		}
		if (isle.vel.x < 0.0f && isle.pos.x < 0)
		{
			isle.old_pos.x = isle.pos.x;
			isle.old_pos.x -= isle.vel.x;
			isle.pos.x += mapwidth;			
		}
		if (isle.vel.y < 0.0f && isle.pos.y < 0)
		{
			isle.old_pos.y = isle.pos.y;
			isle.old_pos.y -= isle.vel.y;
			isle.pos.y += mapheight;		
		}
	}*/
}