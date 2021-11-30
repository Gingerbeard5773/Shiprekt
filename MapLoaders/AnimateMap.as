// animates the map

#include "CustomMap.as";

const int MAX_FRAMES = 3;
const int TICKS_PER_FRAME = 30;

void onInit( CRules@ this )
{
	this.set_u32("current frame", 0 );
	this.set_u32("frame direction", 1 );
	this.set_u32("last anim time", 0);
}

void onTick( CRules@ this )
{
	CMap@ map = getMap();
	const int mapWidth = map.tilemapwidth;
	const int mapHeight = map.tilemapheight;
	
	const u32 gametime = getGameTime();
	u32 lastAnimTime = this.get_u32("last anim time");
	int diff = gametime - (lastAnimTime + TICKS_PER_FRAME);
	
	int currFrame = this.get_u32("current frame");
	int frameDir = this.get_u32("frame direction");
	
	if ( diff > 0 )
	{
		for (uint xPos = 0; xPos < mapWidth; ++xPos)
		{
			for (uint yPos = 0; yPos < mapHeight; ++yPos)
			{
				TileType tile = map.getTileFromTileSpace(Vec2f(xPos, yPos)).type;
				Vec2f tilePos = map.getTileWorldPosition(Vec2f(xPos, yPos));
				uint tileOffset = map.getTileOffset(tilePos);
			
				//iterate tilemap
				if ( tile != CMap::sand_inland && tile != CMap::sand_inland+1 && tile != CMap::sand_inland+2 && tile != CMap::sand_inland+3 && tile != CMap::sand_inland+4 && tile != CMap::sand_inland+5
					&& tile != CMap::grass_inland && tile != CMap::grass_inland+1 && tile != CMap::grass_inland+2 && tile != CMap::grass_inland+3 && tile != CMap::grass_inland+4
					&& tile != CMap::water)
				{
					map.server_SetTile( tilePos, tile + frameDir );
					map.AddTileFlag( tileOffset, Tile::BACKGROUND );
					map.AddTileFlag( tileOffset, Tile::LIGHT_PASSES );
				}
			}
		}
		
		currFrame = currFrame + frameDir;
		
		if ( currFrame >= MAX_FRAMES )
			frameDir = -1;
		else if ( currFrame <= 0 )
			frameDir = 1;
			
		this.set_u32("frame direction", frameDir);
		this.set_u32("current frame", currFrame + frameDir);
		this.set_u32("last anim time", gametime);
	}
}