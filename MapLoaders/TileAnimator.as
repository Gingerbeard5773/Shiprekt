// TileAnimator.as
 
#define SERVER_ONLY

#include "CustomMap.as";

void onInit( CRules@ this )
{
	onRestart( this );
}

void onRestart( CRules@ this )
{
	TileAnimator animator(getMap());
	this.set("tile animator", animator);
}
 
void onTick(CRules@ this)
{
	if(!this.exists("tile animator"))
	{
			TileAnimator animator(getMap());
			this.set("tile animator", animator);
			return;
	}
	// temporary, end

	TileAnimator@ animator;
	if(!this.get("tile animator", @animator)) return;

	CMap@ map = getMap();
	if(map is null) return;

	const uint time = getGameTime();

	animator.update(getMap(), getGameTime());
}
 
shared class TileAnimator
{
        array<AnimatedTile> tiles;                  // array of animated tiles
 
        TileAnimator(CMap@ map)
        {
                // temporary constructor, should give the map loader access to the TileAnimator
                // then push_back AnimatedTiles as needed
                uint width = map.tilemapwidth;
                uint height = map.tilemapheight;
                uint count = width * height;
 
                for(uint i = 0; i < count; i++)
                {
                        TileType type = map.getTile(i).type;
                        if( type == CMap::sand_inland || type == CMap::sand_inland+1 || type == CMap::sand_inland+2 || type == CMap::sand_inland+3 
								|| type == CMap::sand_inland+4 || type == CMap::sand_inland+5
								|| type == CMap::grass_inland || type == CMap::grass_inland+1 || type == CMap::grass_inland+2 || type == CMap::grass_inland+3 || type == CMap::grass_inland+4
								|| type == CMap::water) 
						{
							continue;
						}
 
                        Vec2f position = map.getTileWorldPosition(i);
 
                        array<u16> frame = { type, type+1, type+2, type+1};
 
                        AnimatedTile tile(map, position.x, position.y, 30, @frame);
                        tiles.push_back(tile);
                }
        }
 
        void update(CMap@ map, const uint time)
        {
                for(uint i = 0; i < tiles.length; i++)
                {
                        tiles[i].update(map, time);
                }
        }
};
 
shared class AnimatedTile
{
        uint x, y;                                  // position of tile
 
        u8 speed;                                   // animation speed
        u16[] frame;                                // animation frames and animation length
        u8 index;                                   // current index of frame
 
        AnimatedTile(CMap@ map, uint _x, uint _y, u8 _speed, array<u16>@ _frame)
        {
                x = _x;
                y = _y;
 
                speed = _speed;
                frame = _frame;
 
                index = 0;
				
				uint tileOffset = map.getTileOffset(Vec2f(x, y));
                map.server_SetTile(Vec2f(x, y), frame[0]);
				map.AddTileFlag( tileOffset, Tile::BACKGROUND );
				map.AddTileFlag( tileOffset, Tile::LIGHT_SOURCE );
        }
 
        void update(CMap@ map, const uint time)
        {
                if(time % speed != 0) return;
				
                index = index < frame.length - 1? index + 1 : 0;
 
				uint tileOffset = map.getTileOffset(Vec2f(x, y));
                map.server_SetTile(Vec2f(x, y), frame[index]);
				map.AddTileFlag( tileOffset, Tile::BACKGROUND );
				map.AddTileFlag( tileOffset, Tile::LIGHT_SOURCE );
        }
};