#include "CustomTiles.as";
//Show custom image on server-browsing where the map is shown

CFileImage@ map_image = CFileImage("Whirlpool.png");

void onInit(CMap@ this)
{
    this.legacyTileMinimap = false;
	this.MakeMiniMap();
}

void CalculateMinimapColour(CMap@ this, u32 offset, TileType type, SColor &out col)
{
	//Draw image
	
	if (type == CMap::tile_empty)
	{
		col = SColor(255, 41, 100, 176);
		return;
	}
	else if (type >= CMap::sand_inland && type <= CMap::grass_sand_border_diagonal_L1)
	{
		col = SColor(255, 236, 213, 144);
		return;
	}
	else if (type >= CMap::rock_inland && type <= CMap::rock_shoal_border_diagonal_L1)
	{
		col = SColor(255, 161, 161, 161);
		return;
	}
	else if (type >= CMap::shoal_inland && type <= CMap::sand_shoal_border_diagonal_L1)
	{
		col = SColor(255, 100, 170, 180);
		return;
	}
	/*map_image.setPixelOffset(offset);
	SColor col_temp = map_image.readPixel();
	if (col_temp.getAlpha() >= 255) col = col_temp;
	else col = SColor(255, 41, 100, 176); //water color
	return;*/
	
	/*const int w = this.tilemapwidth;
	const int x = offset % w;
	const int y = offset / w;

	//stolen from pirate-rob >:)
	int imageX = (w - map_image.getWidth())/2;
	int imageY = 10;
	if (x >= imageX && x < imageX + map_image.getWidth())
	{
		if (y >= imageY && y < imageY + map_image.getHeight())
		{
			map_image.setPixelPosition(Vec2f(x - imageX,y-imageY));
			SColor col_temp = map_image.readPixel();
			if (col_temp.getAlpha() >= 255)
			{
				col = col_temp;
				return;
			}
		}
	}
	col = SColor(255, 41, 100, 176); //anything else is colored water*/
}
