Random map_random(1569815698);

#include "LoadMapUtils.as";
#include "CustomTiles.as";

namespace CMap
{
	// tiles
	const SColor color_water(255, 77, 133, 188);
	// custom land tiles
	const SColor color_sand(255, 236, 213, 144);
	const SColor color_grass(255, 100, 155, 13);
	const SColor color_rock(255, 161, 161, 161);
	const SColor color_shoal(255, 100, 170, 180);
	
	// objects
	enum color
	{
		color_main_spawn = 0xff00ffff,
		color_station = 0xffff0000,
		color_ministation = 0xffff8C00,
		color_palmtree = 0xff009600
	};
	
	//
	void SetupMap(CMap@ map, int width, int height)
	{
		map.CreateTileMap(width, height, 8.0f, "LandTiles.png");
		map.CreateSky(SColor(255, 41, 100, 176));
		map.topBorder = map.bottomBorder = map.rightBorder = map.leftBorder = true;
	}
	
	SColor pixel_R = color_water;
	SColor pixel_RU = color_water;
	SColor pixel_U = color_water;
	SColor pixel_LU = color_water;
	SColor pixel_L = color_water;
	SColor pixel_LD = color_water;
	SColor pixel_D = color_water;
	SColor pixel_RD = color_water;

	//
	void handlePixel(CMap@ map, CFileImage@ image, SColor pixel, int offset, Vec2f pixelPos)
	{	
		if (pixel == color_water)
		{
			//map.AddTileFlag(offset, Tile::BACKGROUND);
			//map.AddTileFlag(offset, Tile::LIGHT_PASSES);
			return;
		}
		
		// ** NON-TILES **
		
		switch (pixel.color)
		{
			case color_main_spawn:
			{
				AddMarker(map, offset, "spawn");
				return;
			}
			case color_station:
			{
				CBlob@ stationBlob = spawnBlob(map, "station", offset, 255, false);	
				stationBlob.getSprite().SetFrame(0);
				
				map.SetTile(offset, CMap::sand_inland);	
				map.AddTileFlag(offset, Tile::BACKGROUND);
				map.AddTileFlag(offset, Tile::LIGHT_PASSES);
				return;
			}
			case color_ministation:
			{
				CBlob@ ministationBlob = spawnBlob(map, "ministation", offset, 255, false);	
				ministationBlob.getSprite().SetFrame(1);
				
				map.SetTile(offset, CMap::sand_inland);	
				map.AddTileFlag(offset, Tile::BACKGROUND);
				map.AddTileFlag(offset, Tile::LIGHT_PASSES);
				return;
			}
			case color_palmtree:
			{
				CBlob@ palmtreeBlob = spawnBlob(map, "palmtree", offset, 255, false);	
			
				map.SetTile(offset, CMap::grass_inland + map_random.NextRanged(5));
				map.AddTileFlag(offset, Tile::BACKGROUND);
				map.AddTileFlag(offset, Tile::LIGHT_PASSES);
				return;
			}
		}
		
		// ** TILES **
		
		//declare nearby pixels
		if (image !is null && image.isLoaded())
		{
			image.setPixelPosition(pixelPos + Vec2f(1, 0));
			if (image.canRead())
				pixel_R = image.readPixel();
			
			if (image.getPixelPosition().y > 0)
			{
				image.setPixelPosition(pixelPos + Vec2f(1, -1));
				if (image.canRead())
					pixel_RU = image.readPixel();

				image.setPixelPosition(pixelPos + Vec2f(0, -1));
				if (image.canRead())
					pixel_U = image.readPixel();
				
				image.setPixelPosition(pixelPos + Vec2f(-1, -1));
				if (image.canRead())
					pixel_LU = image.readPixel();
			}
			
			image.setPixelPosition(pixelPos + Vec2f(-1, 0));
			if (image.canRead())
				pixel_L = image.readPixel();
			
			image.setPixelPosition(pixelPos + Vec2f(-1, 1));
			if (image.canRead())
				pixel_LD = image.readPixel();
			
			image.setPixelPosition(pixelPos + Vec2f(0, 1));
			if (image.canRead())
				pixel_D = image.readPixel();
			
			image.setPixelPosition(pixelPos + Vec2f(1, 1));
			if (image.canRead())
				pixel_RD = image.readPixel();
				
			image.setPixelOffset(offset);
		}
		
		if (pixel == color_sand) 
		{
			//SAND AND SHOAL BORDERS
			//completely surrrounded ship
			if (pixel_R == color_shoal && pixel_U == color_shoal && pixel_L == color_shoal && pixel_D == color_shoal)
				map.SetTile(offset, CMap::sand_shoal_border_ship1);
				
			//four way crossing
			else if (pixel_RU == color_shoal && pixel_LU == color_shoal && pixel_LD == color_shoal && pixel_RD == color_shoal
						&& pixel_R != color_shoal && pixel_U != color_shoal && pixel_L != color_shoal && pixel_D != color_shoal)
				map.SetTile(offset, CMap::sand_shoal_border_cross1);		
		
			//peninsula shorelines
			else if (pixel_R == color_shoal && pixel_U == color_shoal && pixel_D == color_shoal)
				map.SetTile(offset, CMap::sand_shoal_border_peninsula_R1);
			else if (pixel_R == color_shoal && pixel_U == color_shoal && pixel_L == color_shoal)
				map.SetTile(offset, CMap::sand_shoal_border_peninsula_U1);
			else if (pixel_U == color_shoal && pixel_L == color_shoal && pixel_D == color_shoal)
				map.SetTile(offset, CMap::sand_shoal_border_peninsula_L1);
			else if (pixel_L == color_shoal && pixel_D == color_shoal && pixel_R == color_shoal)
				map.SetTile(offset, CMap::sand_shoal_border_peninsula_D1);
				
			//three way T crossings
			else if (pixel_R == color_shoal && pixel_LU == color_shoal && pixel_LD == color_shoal
						&& pixel_U != color_shoal && pixel_L != color_shoal && pixel_D != color_shoal)
				map.SetTile(offset, CMap::sand_shoal_border_T_R1);
			else if (pixel_U == color_shoal && pixel_RD == color_shoal && pixel_LD == color_shoal
						&& pixel_R != color_shoal && pixel_L != color_shoal && pixel_D != color_shoal)
				map.SetTile(offset, CMap::sand_shoal_border_T_U1);
			else if (pixel_RU == color_shoal && pixel_L == color_shoal && pixel_RD == color_shoal
						&& pixel_R != color_shoal && pixel_U != color_shoal && pixel_D != color_shoal)
				map.SetTile(offset, CMap::sand_shoal_border_T_L1);
			else if (pixel_RU == color_shoal && pixel_LU == color_shoal && pixel_D == color_shoal
						&& pixel_R != color_shoal && pixel_U != color_shoal && pixel_L != color_shoal)
				map.SetTile(offset, CMap::sand_shoal_border_T_D1);
				
			//left handed panhandle
			else if (pixel_R == color_shoal && pixel_LU == color_shoal
						&& pixel_U != color_shoal && pixel_L != color_shoal && pixel_LD != color_shoal && pixel_D != color_shoal)
				map.SetTile(offset, CMap::sand_shoal_border_panhandleL_R1);
			else if (pixel_U == color_shoal && pixel_LD == color_shoal 
						&& pixel_R != color_shoal && pixel_L != color_shoal && pixel_D != color_shoal && pixel_RD != color_shoal)
				map.SetTile(offset, CMap::sand_shoal_border_panhandleL_U1);
			else if (pixel_L == color_shoal && pixel_RD == color_shoal 
						&& pixel_R != color_shoal && pixel_RU != color_shoal && pixel_U != color_shoal && pixel_D != color_shoal)
				map.SetTile(offset, CMap::sand_shoal_border_panhandleL_L1);
			else if (pixel_RU == color_shoal && pixel_D == color_shoal
						&& pixel_R != color_shoal && pixel_U != color_shoal && pixel_LU != color_shoal && pixel_L != color_shoal)
				map.SetTile(offset, CMap::sand_shoal_border_panhandleL_D1);
				
			//right handed panhandle
			else if (pixel_R == color_shoal && pixel_LD == color_shoal 
						&& pixel_U != color_shoal && pixel_LU != color_shoal && pixel_L != color_shoal && pixel_D != color_shoal)
				map.SetTile(offset, CMap::sand_shoal_border_panhandleR_R1);
			else if (pixel_U == color_shoal && pixel_RD == color_shoal
						&& pixel_R != color_shoal && pixel_L != color_shoal && pixel_LD != color_shoal && pixel_D != color_shoal)
				map.SetTile(offset, CMap::sand_shoal_border_panhandleR_U1);
			else if (pixel_RU == color_shoal && pixel_L == color_shoal
						&& pixel_R != color_shoal && pixel_U != color_shoal && pixel_D != color_shoal && pixel_RD != color_shoal)
				map.SetTile(offset, CMap::sand_shoal_border_panhandleR_L1);
			else if (pixel_LU == color_shoal && pixel_D == color_shoal 
						&& pixel_R != color_shoal && pixel_RU != color_shoal && pixel_U != color_shoal && pixel_L != color_shoal)
				map.SetTile(offset, CMap::sand_shoal_border_panhandleR_D1);
				
			//splitting strips
			else if (pixel_RU == color_shoal && pixel_LU == color_shoal && pixel_RD == color_shoal
						&& pixel_R != color_shoal && pixel_U != color_shoal && pixel_L != color_shoal && pixel_LD != color_shoal && pixel_D != color_shoal)
				map.SetTile(offset, CMap::sand_shoal_border_split_RU1);
			else if (pixel_RU == color_shoal && pixel_LU == color_shoal && pixel_LD == color_shoal 
						&& pixel_R != color_shoal && pixel_U != color_shoal && pixel_L != color_shoal && pixel_D != color_shoal && pixel_RD != color_shoal)
				map.SetTile(offset, CMap::sand_shoal_border_split_LU1);
			else if (pixel_LU == color_shoal && pixel_LD == color_shoal && pixel_RD == color_shoal 
						&& pixel_R != color_shoal && pixel_RU != color_shoal && pixel_U != color_shoal && pixel_L != color_shoal && pixel_D != color_shoal)
				map.SetTile(offset, CMap::sand_shoal_border_split_LD1);
			else if (pixel_RU == color_shoal && pixel_LD == color_shoal && pixel_RD == color_shoal 
						&& pixel_R != color_shoal && pixel_U != color_shoal && pixel_LU != color_shoal && pixel_L != color_shoal && pixel_D != color_shoal)
				map.SetTile(offset, CMap::sand_shoal_border_split_RD1);
				
			//choke points
			else if (pixel_RU == color_shoal && pixel_RD == color_shoal 
						&& pixel_R != color_shoal && pixel_U != color_shoal && pixel_LU != color_shoal && pixel_L != color_shoal && pixel_LD != color_shoal && pixel_D != color_shoal)
				map.SetTile(offset, CMap::sand_shoal_border_choke_R1);
			else if (pixel_RU == color_shoal && pixel_LU == color_shoal 
						&& pixel_R != color_shoal && pixel_U != color_shoal && pixel_L != color_shoal && pixel_LD != color_shoal && pixel_D != color_shoal && pixel_RD != color_shoal)
				map.SetTile(offset, CMap::sand_shoal_border_choke_U1);
			else if (pixel_LU == color_shoal && pixel_LD == color_shoal 
						&& pixel_R != color_shoal && pixel_RU != color_shoal && pixel_U != color_shoal && pixel_L != color_shoal && pixel_D != color_shoal && pixel_RD != color_shoal)
				map.SetTile(offset, CMap::sand_shoal_border_choke_L1);
			else if (pixel_LD == color_shoal && pixel_RD == color_shoal 
						&& pixel_R != color_shoal && pixel_RU != color_shoal && pixel_U != color_shoal && pixel_LU != color_shoal && pixel_L != color_shoal && pixel_D != color_shoal)
				map.SetTile(offset, CMap::sand_shoal_border_choke_D1);
				
			//strip shorelines
			else if (pixel_U == color_shoal && pixel_D == color_shoal)
				map.SetTile(offset, CMap::sand_shoal_border_strip_H1);
			else if (pixel_R == color_shoal && pixel_L == color_shoal)
				map.SetTile(offset, CMap::sand_shoal_border_strip_V1);	

			//bend shorelines
			else if (pixel_R == color_shoal && pixel_RU == color_shoal && pixel_U == color_shoal && pixel_LD == color_shoal)
				map.SetTile(offset, CMap::sand_shoal_border_bend_RU1);
			else if (pixel_L == color_shoal && pixel_LU == color_shoal && pixel_U == color_shoal && pixel_RD == color_shoal)
				map.SetTile(offset, CMap::sand_shoal_border_bend_LU1);
			else if (pixel_L == color_shoal && pixel_LD == color_shoal && pixel_D == color_shoal && pixel_RU == color_shoal)
				map.SetTile(offset, CMap::sand_shoal_border_bend_LD1);
			else if (pixel_R == color_shoal && pixel_RD == color_shoal && pixel_D == color_shoal && pixel_LU == color_shoal)
				map.SetTile(offset, CMap::sand_shoal_border_bend_RD1);		

			//diagonal choke points
			else if (pixel_RU == color_shoal && pixel_LD == color_shoal
						&& pixel_R != color_shoal && pixel_U != color_shoal && pixel_LU != color_shoal && pixel_L != color_shoal && pixel_D != color_shoal && pixel_RD != color_shoal)
				map.SetTile(offset, CMap::sand_shoal_border_diagonal_R1);	
			else if (pixel_LU == color_shoal && pixel_RD == color_shoal
						&& pixel_R != color_shoal && pixel_RU != color_shoal && pixel_U != color_shoal && pixel_L != color_shoal && pixel_LD != color_shoal && pixel_D != color_shoal)
				map.SetTile(offset, CMap::sand_shoal_border_diagonal_L1);				

			//straight edge shorelines
			else if (pixel_R == color_shoal 
						&& pixel_U != color_shoal && pixel_LU != color_shoal && pixel_L != color_shoal && pixel_LD != color_shoal && pixel_D != color_shoal)
				map.SetTile(offset, CMap::sand_shoal_border_straight_R1);	
			else if (pixel_U == color_shoal
						&& pixel_R != color_shoal && pixel_L != color_shoal && pixel_LD != color_shoal && pixel_D != color_shoal && pixel_RD != color_shoal)
				map.SetTile(offset, CMap::sand_shoal_border_straight_U1);	
			else if (pixel_L == color_shoal
						&& pixel_R != color_shoal && pixel_RU != color_shoal && pixel_U != color_shoal && pixel_D != color_shoal && pixel_RD != color_shoal)
				map.SetTile(offset, CMap::sand_shoal_border_straight_L1);	
			else if (pixel_D == color_shoal
						&& pixel_R != color_shoal && pixel_RU != color_shoal && pixel_U != color_shoal && pixel_LU != color_shoal && pixel_L != color_shoal)
				map.SetTile(offset, CMap::sand_shoal_border_straight_D1);	
				
			//convex shorelines
			else if (pixel_R == color_shoal && pixel_U == color_shoal)
				map.SetTile(offset, CMap::sand_shoal_border_convex_RU1);
			else if (pixel_L == color_shoal && pixel_U == color_shoal)
				map.SetTile(offset, CMap::sand_shoal_border_convex_LU1);
			else if (pixel_L == color_shoal && pixel_D == color_shoal)
				map.SetTile(offset, CMap::sand_shoal_border_convex_LD1);
			else if (pixel_R == color_shoal && pixel_D == color_shoal)
				map.SetTile(offset, CMap::sand_shoal_border_convex_RD1);
				
			//concave shorelines		
			else if (pixel_RU == color_shoal)
				map.SetTile(offset, CMap::sand_shoal_border_concave_RU1);	
			else if (pixel_LU == color_shoal)
				map.SetTile(offset, CMap::sand_shoal_border_concave_LU1);	
			else if (pixel_LD == color_shoal)
				map.SetTile(offset, CMap::sand_shoal_border_concave_LD1);	
			else if (pixel_RD == color_shoal)
				map.SetTile(offset, CMap::sand_shoal_border_concave_RD1);
		
			//SAND SHORES
			//completely surrrounded ship
			else if (pixel_R == color_water && pixel_U == color_water && pixel_L == color_water && pixel_D == color_water)
				map.SetTile(offset, CMap::sand_shore_ship1);
				
			//four way crossing
			else if (pixel_RU == color_water && pixel_LU == color_water && pixel_LD == color_water && pixel_RD == color_water
						&& pixel_R != color_water && pixel_U != color_water && pixel_L != color_water && pixel_D != color_water)
				map.SetTile(offset, CMap::sand_shore_cross1);		
		
			//peninsula shorelines
			else if (pixel_R == color_water && pixel_U == color_water && pixel_D == color_water)
				map.SetTile(offset, CMap::sand_shore_peninsula_R1);
			else if (pixel_R == color_water && pixel_U == color_water && pixel_L == color_water)
				map.SetTile(offset, CMap::sand_shore_peninsula_U1);
			else if (pixel_U == color_water && pixel_L == color_water && pixel_D == color_water)
				map.SetTile(offset, CMap::sand_shore_peninsula_L1);
			else if (pixel_L == color_water && pixel_D == color_water && pixel_R == color_water)
				map.SetTile(offset, CMap::sand_shore_peninsula_D1);
				
			//three way T crossings
			else if (pixel_R == color_water && pixel_LU == color_water && pixel_LD == color_water
						&& pixel_U != color_water && pixel_L != color_water && pixel_D != color_water)
				map.SetTile(offset, CMap::sand_shore_T_R1);
			else if (pixel_U == color_water && pixel_RD == color_water && pixel_LD == color_water
						&& pixel_R != color_water && pixel_L != color_water && pixel_D != color_water)
				map.SetTile(offset, CMap::sand_shore_T_U1);
			else if (pixel_RU == color_water && pixel_L == color_water && pixel_RD == color_water
						&& pixel_R != color_water && pixel_U != color_water && pixel_D != color_water)
				map.SetTile(offset, CMap::sand_shore_T_L1);
			else if (pixel_RU == color_water && pixel_LU == color_water && pixel_D == color_water
						&& pixel_R != color_water && pixel_U != color_water && pixel_L != color_water)
				map.SetTile(offset, CMap::sand_shore_T_D1);
				
			//left handed panhandle
			else if (pixel_R == color_water && pixel_LU == color_water
						&& pixel_U != color_water && pixel_L != color_water && pixel_LD != color_water && pixel_D != color_water)
				map.SetTile(offset, CMap::sand_shore_panhandleL_R1);
			else if (pixel_U == color_water && pixel_LD == color_water 
						&& pixel_R != color_water && pixel_L != color_water && pixel_D != color_water && pixel_RD != color_water)
				map.SetTile(offset, CMap::sand_shore_panhandleL_U1);
			else if (pixel_L == color_water && pixel_RD == color_water 
						&& pixel_R != color_water && pixel_RU != color_water && pixel_U != color_water && pixel_D != color_water)
				map.SetTile(offset, CMap::sand_shore_panhandleL_L1);
			else if (pixel_RU == color_water && pixel_D == color_water
						&& pixel_R != color_water && pixel_U != color_water && pixel_LU != color_water && pixel_L != color_water)
				map.SetTile(offset, CMap::sand_shore_panhandleL_D1);
				
			//right handed panhandle
			else if (pixel_R == color_water && pixel_LD == color_water 
						&& pixel_U != color_water && pixel_LU != color_water && pixel_L != color_water && pixel_D != color_water)
				map.SetTile(offset, CMap::sand_shore_panhandleR_R1);
			else if (pixel_U == color_water && pixel_RD == color_water
						&& pixel_R != color_water && pixel_L != color_water && pixel_LD != color_water && pixel_D != color_water)
				map.SetTile(offset, CMap::sand_shore_panhandleR_U1);
			else if (pixel_RU == color_water && pixel_L == color_water
						&& pixel_R != color_water && pixel_U != color_water && pixel_D != color_water && pixel_RD != color_water)
				map.SetTile(offset, CMap::sand_shore_panhandleR_L1);
			else if (pixel_LU == color_water && pixel_D == color_water 
						&& pixel_R != color_water && pixel_RU != color_water && pixel_U != color_water && pixel_L != color_water)
				map.SetTile(offset, CMap::sand_shore_panhandleR_D1);
				
			//splitting strips
			else if (pixel_RU == color_water && pixel_LU == color_water && pixel_RD == color_water
						&& pixel_R != color_water && pixel_U != color_water && pixel_L != color_water && pixel_LD != color_water && pixel_D != color_water)
				map.SetTile(offset, CMap::sand_shore_split_RU1);
			else if (pixel_RU == color_water && pixel_LU == color_water && pixel_LD == color_water 
						&& pixel_R != color_water && pixel_U != color_water && pixel_L != color_water && pixel_D != color_water && pixel_RD != color_water)
				map.SetTile(offset, CMap::sand_shore_split_LU1);
			else if (pixel_LU == color_water && pixel_LD == color_water && pixel_RD == color_water 
						&& pixel_R != color_water && pixel_RU != color_water && pixel_U != color_water && pixel_L != color_water && pixel_D != color_water)
				map.SetTile(offset, CMap::sand_shore_split_LD1);
			else if (pixel_RU == color_water && pixel_LD == color_water && pixel_RD == color_water 
						&& pixel_R != color_water && pixel_U != color_water && pixel_LU != color_water && pixel_L != color_water && pixel_D != color_water)
				map.SetTile(offset, CMap::sand_shore_split_RD1);
				
			//choke points
			else if (pixel_RU == color_water && pixel_RD == color_water 
						&& pixel_R != color_water && pixel_U != color_water && pixel_LU != color_water && pixel_L != color_water && pixel_LD != color_water && pixel_D != color_water)
				map.SetTile(offset, CMap::sand_shore_choke_R1);
			else if (pixel_RU == color_water && pixel_LU == color_water 
						&& pixel_R != color_water && pixel_U != color_water && pixel_L != color_water && pixel_LD != color_water && pixel_D != color_water && pixel_RD != color_water)
				map.SetTile(offset, CMap::sand_shore_choke_U1);
			else if (pixel_LU == color_water && pixel_LD == color_water 
						&& pixel_R != color_water && pixel_RU != color_water && pixel_U != color_water && pixel_L != color_water && pixel_D != color_water && pixel_RD != color_water)
				map.SetTile(offset, CMap::sand_shore_choke_L1);
			else if (pixel_LD == color_water && pixel_RD == color_water 
						&& pixel_R != color_water && pixel_RU != color_water && pixel_U != color_water && pixel_LU != color_water && pixel_L != color_water && pixel_D != color_water)
				map.SetTile(offset, CMap::sand_shore_choke_D1);
				
			//strip shorelines
			else if (pixel_U == color_water && pixel_D == color_water)
				map.SetTile(offset, CMap::sand_shore_strip_H1);
			else if (pixel_R == color_water && pixel_L == color_water)
				map.SetTile(offset, CMap::sand_shore_strip_V1);	

			//bend shorelines
			else if (pixel_R == color_water && pixel_RU == color_water && pixel_U == color_water && pixel_LD == color_water)
				map.SetTile(offset, CMap::sand_shore_bend_RU1);
			else if (pixel_L == color_water && pixel_LU == color_water && pixel_U == color_water && pixel_RD == color_water)
				map.SetTile(offset, CMap::sand_shore_bend_LU1);
			else if (pixel_L == color_water && pixel_LD == color_water && pixel_D == color_water && pixel_RU == color_water)
				map.SetTile(offset, CMap::sand_shore_bend_LD1);
			else if (pixel_R == color_water && pixel_RD == color_water && pixel_D == color_water && pixel_LU == color_water)
				map.SetTile(offset, CMap::sand_shore_bend_RD1);		

			//diagonal choke points
			else if (pixel_RU == color_water && pixel_LD == color_water
						&& pixel_R != color_water && pixel_U != color_water && pixel_LU != color_water && pixel_L != color_water && pixel_D != color_water && pixel_RD != color_water)
				map.SetTile(offset, CMap::sand_shore_diagonal_R1);	
			else if (pixel_LU == color_water && pixel_RD == color_water
						&& pixel_R != color_water && pixel_RU != color_water && pixel_U != color_water && pixel_L != color_water && pixel_LD != color_water && pixel_D != color_water)
				map.SetTile(offset, CMap::sand_shore_diagonal_L1);				

			//straight edge shorelines
			else if (pixel_R == color_water 
						&& pixel_U != color_water && pixel_LU != color_water && pixel_L != color_water && pixel_LD != color_water && pixel_D != color_water)
				map.SetTile(offset, CMap::sand_shore_straight_R1);	
			else if (pixel_U == color_water
						&& pixel_R != color_water && pixel_L != color_water && pixel_LD != color_water && pixel_D != color_water && pixel_RD != color_water)
				map.SetTile(offset, CMap::sand_shore_straight_U1);	
			else if (pixel_L == color_water
						&& pixel_R != color_water && pixel_RU != color_water && pixel_U != color_water && pixel_D != color_water && pixel_RD != color_water)
				map.SetTile(offset, CMap::sand_shore_straight_L1);	
			else if (pixel_D == color_water
						&& pixel_R != color_water && pixel_RU != color_water && pixel_U != color_water && pixel_LU != color_water && pixel_L != color_water)
				map.SetTile(offset, CMap::sand_shore_straight_D1);	
				
			//convex shorelines
			else if (pixel_R == color_water && pixel_U == color_water)
				map.SetTile(offset, CMap::sand_shore_convex_RU1);
			else if (pixel_L == color_water && pixel_U == color_water)
				map.SetTile(offset, CMap::sand_shore_convex_LU1);
			else if (pixel_L == color_water && pixel_D == color_water)
				map.SetTile(offset, CMap::sand_shore_convex_LD1);
			else if (pixel_R == color_water && pixel_D == color_water)
				map.SetTile(offset, CMap::sand_shore_convex_RD1);
				
			//concave shorelines		
			else if (pixel_RU == color_water)
				map.SetTile(offset, CMap::sand_shore_concave_RU1);	
			else if (pixel_LU == color_water)
				map.SetTile(offset, CMap::sand_shore_concave_LU1);	
			else if (pixel_LD == color_water)
				map.SetTile(offset, CMap::sand_shore_concave_LD1);	
			else if (pixel_RD == color_water)
				map.SetTile(offset, CMap::sand_shore_concave_RD1);
			else
				map.SetTile(offset, CMap::sand_inland + map_random.NextRanged(5));	
			
			map.AddTileFlag(offset, Tile::BACKGROUND);
			map.AddTileFlag(offset, Tile::LIGHT_PASSES);
		}
		else if (pixel == color_grass) 
		{
			//grass SURROUNDED BY SAND
			//completely surrrounded ship
			if (pixel_R == color_sand && pixel_U == color_sand && pixel_L == color_sand && pixel_D == color_sand)
				map.SetTile(offset, CMap::grass_sand_border_ship1);
				
			//four way crossing
			else if (pixel_RU == color_sand && pixel_LU == color_sand && pixel_LD == color_sand && pixel_RD == color_sand
						&& pixel_R != color_sand && pixel_U != color_sand && pixel_L != color_sand && pixel_D != color_sand)
				map.SetTile(offset, CMap::grass_sand_border_cross1);		
		
			//peninsula shorelines
			else if (pixel_R == color_sand && pixel_U == color_sand && pixel_D == color_sand)
				map.SetTile(offset, CMap::grass_sand_border_peninsula_R1);
			else if (pixel_R == color_sand && pixel_U == color_sand && pixel_L == color_sand)
				map.SetTile(offset, CMap::grass_sand_border_peninsula_U1);
			else if (pixel_U == color_sand && pixel_L == color_sand && pixel_D == color_sand)
				map.SetTile(offset, CMap::grass_sand_border_peninsula_L1);
			else if (pixel_L == color_sand && pixel_D == color_sand && pixel_R == color_sand)
				map.SetTile(offset, CMap::grass_sand_border_peninsula_D1);
				
			//three way T crossings
			else if (pixel_R == color_sand && pixel_LU == color_sand && pixel_LD == color_sand
						&& pixel_U != color_sand && pixel_L != color_sand && pixel_D != color_sand)
				map.SetTile(offset, CMap::grass_sand_border_T_R1);
			else if (pixel_U == color_sand && pixel_RD == color_sand && pixel_LD == color_sand
						&& pixel_R != color_sand && pixel_L != color_sand && pixel_D != color_sand)
				map.SetTile(offset, CMap::grass_sand_border_T_U1);
			else if (pixel_RU == color_sand && pixel_L == color_sand && pixel_RD == color_sand
						&& pixel_R != color_sand && pixel_U != color_sand && pixel_D != color_sand)
				map.SetTile(offset, CMap::grass_sand_border_T_L1);
			else if (pixel_RU == color_sand && pixel_LU == color_sand && pixel_D == color_sand
						&& pixel_R != color_sand && pixel_U != color_sand && pixel_L != color_sand)
				map.SetTile(offset, CMap::grass_sand_border_T_D1);
				
			//left handed panhandle
			else if (pixel_R == color_sand && pixel_LU == color_sand
						&& pixel_U != color_sand && pixel_L != color_sand && pixel_LD != color_sand && pixel_D != color_sand)
				map.SetTile(offset, CMap::grass_sand_border_panhandleL_R1);
			else if (pixel_U == color_sand && pixel_LD == color_sand 
						&& pixel_R != color_sand && pixel_L != color_sand && pixel_D != color_sand && pixel_RD != color_sand)
				map.SetTile(offset, CMap::grass_sand_border_panhandleL_U1);
			else if (pixel_L == color_sand && pixel_RD == color_sand 
						&& pixel_R != color_sand && pixel_RU != color_sand && pixel_U != color_sand && pixel_D != color_sand)
				map.SetTile(offset, CMap::grass_sand_border_panhandleL_L1);
			else if (pixel_RU == color_sand && pixel_D == color_sand
						&& pixel_R != color_sand && pixel_U != color_sand && pixel_LU != color_sand && pixel_L != color_sand)
				map.SetTile(offset, CMap::grass_sand_border_panhandleL_D1);
				
			//right handed panhandle
			else if (pixel_R == color_sand && pixel_LD == color_sand 
						&& pixel_U != color_sand && pixel_LU != color_sand && pixel_L != color_sand && pixel_D != color_sand)
				map.SetTile(offset, CMap::grass_sand_border_panhandleR_R1);
			else if (pixel_U == color_sand && pixel_RD == color_sand
						&& pixel_R != color_sand && pixel_L != color_sand && pixel_LD != color_sand && pixel_D != color_sand)
				map.SetTile(offset, CMap::grass_sand_border_panhandleR_U1);
			else if (pixel_RU == color_sand && pixel_L == color_sand
						&& pixel_R != color_sand && pixel_U != color_sand && pixel_D != color_sand && pixel_RD != color_sand)
				map.SetTile(offset, CMap::grass_sand_border_panhandleR_L1);
			else if (pixel_LU == color_sand && pixel_D == color_sand 
						&& pixel_R != color_sand && pixel_RU != color_sand && pixel_U != color_sand && pixel_L != color_sand)
				map.SetTile(offset, CMap::grass_sand_border_panhandleR_D1);
				
			//splitting strips
			else if (pixel_RU == color_sand && pixel_LU == color_sand && pixel_RD == color_sand
						&& pixel_R != color_sand && pixel_U != color_sand && pixel_L != color_sand && pixel_LD != color_sand && pixel_D != color_sand)
				map.SetTile(offset, CMap::grass_sand_border_split_RU1);
			else if (pixel_RU == color_sand && pixel_LU == color_sand && pixel_LD == color_sand 
						&& pixel_R != color_sand && pixel_U != color_sand && pixel_L != color_sand && pixel_D != color_sand && pixel_RD != color_sand)
				map.SetTile(offset, CMap::grass_sand_border_split_LU1);
			else if (pixel_LU == color_sand && pixel_LD == color_sand && pixel_RD == color_sand 
						&& pixel_R != color_sand && pixel_RU != color_sand && pixel_U != color_sand && pixel_L != color_sand && pixel_D != color_sand)
				map.SetTile(offset, CMap::grass_sand_border_split_LD1);
			else if (pixel_RU == color_sand && pixel_LD == color_sand && pixel_RD == color_sand 
						&& pixel_R != color_sand && pixel_U != color_sand && pixel_LU != color_sand && pixel_L != color_sand && pixel_D != color_sand)
				map.SetTile(offset, CMap::grass_sand_border_split_RD1);
				
			//choke points
			else if (pixel_RU == color_sand && pixel_RD == color_sand 
						&& pixel_R != color_sand && pixel_U != color_sand && pixel_LU != color_sand && pixel_L != color_sand && pixel_LD != color_sand && pixel_D != color_sand)
				map.SetTile(offset, CMap::grass_sand_border_choke_R1);
			else if (pixel_RU == color_sand && pixel_LU == color_sand 
						&& pixel_R != color_sand && pixel_U != color_sand && pixel_L != color_sand && pixel_LD != color_sand && pixel_D != color_sand && pixel_RD != color_sand)
				map.SetTile(offset, CMap::grass_sand_border_choke_U1);
			else if (pixel_LU == color_sand && pixel_LD == color_sand 
						&& pixel_R != color_sand && pixel_RU != color_sand && pixel_U != color_sand && pixel_L != color_sand && pixel_D != color_sand && pixel_RD != color_sand)
				map.SetTile(offset, CMap::grass_sand_border_choke_L1);
			else if (pixel_LD == color_sand && pixel_RD == color_sand 
						&& pixel_R != color_sand && pixel_RU != color_sand && pixel_U != color_sand && pixel_LU != color_sand && pixel_L != color_sand && pixel_D != color_sand)
				map.SetTile(offset, CMap::grass_sand_border_choke_D1);
				
			//strip shorelines
			else if (pixel_U == color_sand && pixel_D == color_sand)
				map.SetTile(offset, CMap::grass_sand_border_strip_H1);
			else if (pixel_R == color_sand && pixel_L == color_sand)
				map.SetTile(offset, CMap::grass_sand_border_strip_V1);	

			//bend shorelines
			else if (pixel_R == color_sand && pixel_RU == color_sand && pixel_U == color_sand && pixel_LD == color_sand)
				map.SetTile(offset, CMap::grass_sand_border_bend_RU1);
			else if (pixel_L == color_sand && pixel_LU == color_sand && pixel_U == color_sand && pixel_RD == color_sand)
				map.SetTile(offset, CMap::grass_sand_border_bend_LU1);
			else if (pixel_L == color_sand && pixel_LD == color_sand && pixel_D == color_sand && pixel_RU == color_sand)
				map.SetTile(offset, CMap::grass_sand_border_bend_LD1);
			else if (pixel_R == color_sand && pixel_RD == color_sand && pixel_D == color_sand && pixel_LU == color_sand)
				map.SetTile(offset, CMap::grass_sand_border_bend_RD1);		

			//diagonal choke points
			else if (pixel_RU == color_sand && pixel_LD == color_sand
						&& pixel_R != color_sand && pixel_U != color_sand && pixel_LU != color_sand && pixel_L != color_sand && pixel_D != color_sand && pixel_RD != color_sand)
				map.SetTile(offset, CMap::grass_sand_border_diagonal_R1);	
			else if (pixel_LU == color_sand && pixel_RD == color_sand
						&& pixel_R != color_sand && pixel_RU != color_sand && pixel_U != color_sand && pixel_L != color_sand && pixel_LD != color_sand && pixel_D != color_sand)
				map.SetTile(offset, CMap::grass_sand_border_diagonal_L1);				

			//straight edge shorelines
			else if (pixel_R == color_sand 
						&& pixel_U != color_sand && pixel_LU != color_sand && pixel_L != color_sand && pixel_LD != color_sand && pixel_D != color_sand)
				map.SetTile(offset, CMap::grass_sand_border_straight_R1);	
			else if (pixel_U == color_sand
						&& pixel_R != color_sand && pixel_L != color_sand && pixel_LD != color_sand && pixel_D != color_sand && pixel_RD != color_sand)
				map.SetTile(offset, CMap::grass_sand_border_straight_U1);	
			else if (pixel_L == color_sand
						&& pixel_R != color_sand && pixel_RU != color_sand && pixel_U != color_sand && pixel_D != color_sand && pixel_RD != color_sand)
				map.SetTile(offset, CMap::grass_sand_border_straight_L1);	
			else if (pixel_D == color_sand
						&& pixel_R != color_sand && pixel_RU != color_sand && pixel_U != color_sand && pixel_LU != color_sand && pixel_L != color_sand)
				map.SetTile(offset, CMap::grass_sand_border_straight_D1);	
				
			//convex shorelines
			else if (pixel_R == color_sand && pixel_U == color_sand)
				map.SetTile(offset, CMap::grass_sand_border_convex_RU1);
			else if (pixel_L == color_sand && pixel_U == color_sand)
				map.SetTile(offset, CMap::grass_sand_border_convex_LU1);
			else if (pixel_L == color_sand && pixel_D == color_sand)
				map.SetTile(offset, CMap::grass_sand_border_convex_LD1);
			else if (pixel_R == color_sand && pixel_D == color_sand)
				map.SetTile(offset, CMap::grass_sand_border_convex_RD1);
				
			//concave shorelines		
			else if (pixel_RU == color_sand)
				map.SetTile(offset, CMap::grass_sand_border_concave_RU1);	
			else if (pixel_LU == color_sand)
				map.SetTile(offset, CMap::grass_sand_border_concave_LU1);	
			else if (pixel_LD == color_sand)
				map.SetTile(offset, CMap::grass_sand_border_concave_LD1);	
			else if (pixel_RD == color_sand)
				map.SetTile(offset, CMap::grass_sand_border_concave_RD1);		
				

			else
			map.SetTile(offset, CMap::grass_inland + 1 + map_random.NextRanged(4));
			map.AddTileFlag(offset, Tile::BACKGROUND);
			map.AddTileFlag(offset, Tile::LIGHT_PASSES);
		}	
		else if (pixel == color_rock) 
		{
			//ROCK SURROUNDED BY SAND
			//completely surrrounded ship
			if (pixel_R == color_sand && pixel_U == color_sand && pixel_L == color_sand && pixel_D == color_sand)
				map.SetTile(offset, CMap::rock_sand_border_ship1);
				
			//four way crossing
			else if (pixel_RU == color_sand && pixel_LU == color_sand && pixel_LD == color_sand && pixel_RD == color_sand
						&& pixel_R != color_sand && pixel_U != color_sand && pixel_L != color_sand && pixel_D != color_sand)
				map.SetTile(offset, CMap::rock_sand_border_cross1);		
		
			//peninsula shorelines
			else if (pixel_R == color_sand && pixel_U == color_sand && pixel_D == color_sand)
				map.SetTile(offset, CMap::rock_sand_border_peninsula_R1);
			else if (pixel_R == color_sand && pixel_U == color_sand && pixel_L == color_sand)
				map.SetTile(offset, CMap::rock_sand_border_peninsula_U1);
			else if (pixel_U == color_sand && pixel_L == color_sand && pixel_D == color_sand)
				map.SetTile(offset, CMap::rock_sand_border_peninsula_L1);
			else if (pixel_L == color_sand && pixel_D == color_sand && pixel_R == color_sand)
				map.SetTile(offset, CMap::rock_sand_border_peninsula_D1);
				
			//three way T crossings
			else if (pixel_R == color_sand && pixel_LU == color_sand && pixel_LD == color_sand
						&& pixel_U != color_sand && pixel_L != color_sand && pixel_D != color_sand)
				map.SetTile(offset, CMap::rock_sand_border_T_R1);
			else if (pixel_U == color_sand && pixel_RD == color_sand && pixel_LD == color_sand
						&& pixel_R != color_sand && pixel_L != color_sand && pixel_D != color_sand)
				map.SetTile(offset, CMap::rock_sand_border_T_U1);
			else if (pixel_RU == color_sand && pixel_L == color_sand && pixel_RD == color_sand
						&& pixel_R != color_sand && pixel_U != color_sand && pixel_D != color_sand)
				map.SetTile(offset, CMap::rock_sand_border_T_L1);
			else if (pixel_RU == color_sand && pixel_LU == color_sand && pixel_D == color_sand
						&& pixel_R != color_sand && pixel_U != color_sand && pixel_L != color_sand)
				map.SetTile(offset, CMap::rock_sand_border_T_D1);
				
			//left handed panhandle
			else if (pixel_R == color_sand && pixel_LU == color_sand
						&& pixel_U != color_sand && pixel_L != color_sand && pixel_LD != color_sand && pixel_D != color_sand)
				map.SetTile(offset, CMap::rock_sand_border_panhandleL_R1);
			else if (pixel_U == color_sand && pixel_LD == color_sand 
						&& pixel_R != color_sand && pixel_L != color_sand && pixel_D != color_sand && pixel_RD != color_sand)
				map.SetTile(offset, CMap::rock_sand_border_panhandleL_U1);
			else if (pixel_L == color_sand && pixel_RD == color_sand 
						&& pixel_R != color_sand && pixel_RU != color_sand && pixel_U != color_sand && pixel_D != color_sand)
				map.SetTile(offset, CMap::rock_sand_border_panhandleL_L1);
			else if (pixel_RU == color_sand && pixel_D == color_sand
						&& pixel_R != color_sand && pixel_U != color_sand && pixel_LU != color_sand && pixel_L != color_sand)
				map.SetTile(offset, CMap::rock_sand_border_panhandleL_D1);
				
			//right handed panhandle
			else if (pixel_R == color_sand && pixel_LD == color_sand 
						&& pixel_U != color_sand && pixel_LU != color_sand && pixel_L != color_sand && pixel_D != color_sand)
				map.SetTile(offset, CMap::rock_sand_border_panhandleR_R1);
			else if (pixel_U == color_sand && pixel_RD == color_sand
						&& pixel_R != color_sand && pixel_L != color_sand && pixel_LD != color_sand && pixel_D != color_sand)
				map.SetTile(offset, CMap::rock_sand_border_panhandleR_U1);
			else if (pixel_RU == color_sand && pixel_L == color_sand
						&& pixel_R != color_sand && pixel_U != color_sand && pixel_D != color_sand && pixel_RD != color_sand)
				map.SetTile(offset, CMap::rock_sand_border_panhandleR_L1);
			else if (pixel_LU == color_sand && pixel_D == color_sand 
						&& pixel_R != color_sand && pixel_RU != color_sand && pixel_U != color_sand && pixel_L != color_sand)
				map.SetTile(offset, CMap::rock_sand_border_panhandleR_D1);
				
			//splitting strips
			else if (pixel_RU == color_sand && pixel_LU == color_sand && pixel_RD == color_sand
						&& pixel_R != color_sand && pixel_U != color_sand && pixel_L != color_sand && pixel_LD != color_sand && pixel_D != color_sand)
				map.SetTile(offset, CMap::rock_sand_border_split_RU1);
			else if (pixel_RU == color_sand && pixel_LU == color_sand && pixel_LD == color_sand 
						&& pixel_R != color_sand && pixel_U != color_sand && pixel_L != color_sand && pixel_D != color_sand && pixel_RD != color_sand)
				map.SetTile(offset, CMap::rock_sand_border_split_LU1);
			else if (pixel_LU == color_sand && pixel_LD == color_sand && pixel_RD == color_sand 
						&& pixel_R != color_sand && pixel_RU != color_sand && pixel_U != color_sand && pixel_L != color_sand && pixel_D != color_sand)
				map.SetTile(offset, CMap::rock_sand_border_split_LD1);
			else if (pixel_RU == color_sand && pixel_LD == color_sand && pixel_RD == color_sand 
						&& pixel_R != color_sand && pixel_U != color_sand && pixel_LU != color_sand && pixel_L != color_sand && pixel_D != color_sand)
				map.SetTile(offset, CMap::rock_sand_border_split_RD1);
				
			//choke points
			else if (pixel_RU == color_sand && pixel_RD == color_sand 
						&& pixel_R != color_sand && pixel_U != color_sand && pixel_LU != color_sand && pixel_L != color_sand && pixel_LD != color_sand && pixel_D != color_sand)
				map.SetTile(offset, CMap::rock_sand_border_choke_R1);
			else if (pixel_RU == color_sand && pixel_LU == color_sand 
						&& pixel_R != color_sand && pixel_U != color_sand && pixel_L != color_sand && pixel_LD != color_sand && pixel_D != color_sand && pixel_RD != color_sand)
				map.SetTile(offset, CMap::rock_sand_border_choke_U1);
			else if (pixel_LU == color_sand && pixel_LD == color_sand 
						&& pixel_R != color_sand && pixel_RU != color_sand && pixel_U != color_sand && pixel_L != color_sand && pixel_D != color_sand && pixel_RD != color_sand)
				map.SetTile(offset, CMap::rock_sand_border_choke_L1);
			else if (pixel_LD == color_sand && pixel_RD == color_sand 
						&& pixel_R != color_sand && pixel_RU != color_sand && pixel_U != color_sand && pixel_LU != color_sand && pixel_L != color_sand && pixel_D != color_sand)
				map.SetTile(offset, CMap::rock_sand_border_choke_D1);
				
			//strip shorelines
			else if (pixel_U == color_sand && pixel_D == color_sand)
				map.SetTile(offset, CMap::rock_sand_border_strip_H1);
			else if (pixel_R == color_sand && pixel_L == color_sand)
				map.SetTile(offset, CMap::rock_sand_border_strip_V1);	

			//bend shorelines
			else if (pixel_R == color_sand && pixel_RU == color_sand && pixel_U == color_sand && pixel_LD == color_sand)
				map.SetTile(offset, CMap::rock_sand_border_bend_RU1);
			else if (pixel_L == color_sand && pixel_LU == color_sand && pixel_U == color_sand && pixel_RD == color_sand)
				map.SetTile(offset, CMap::rock_sand_border_bend_LU1);
			else if (pixel_L == color_sand && pixel_LD == color_sand && pixel_D == color_sand && pixel_RU == color_sand)
				map.SetTile(offset, CMap::rock_sand_border_bend_LD1);
			else if (pixel_R == color_sand && pixel_RD == color_sand && pixel_D == color_sand && pixel_LU == color_sand)
				map.SetTile(offset, CMap::rock_sand_border_bend_RD1);		

			//diagonal choke points
			else if (pixel_RU == color_sand && pixel_LD == color_sand
						&& pixel_R != color_sand && pixel_U != color_sand && pixel_LU != color_sand && pixel_L != color_sand && pixel_D != color_sand && pixel_RD != color_sand)
				map.SetTile(offset, CMap::rock_sand_border_diagonal_R1);	
			else if (pixel_LU == color_sand && pixel_RD == color_sand
						&& pixel_R != color_sand && pixel_RU != color_sand && pixel_U != color_sand && pixel_L != color_sand && pixel_LD != color_sand && pixel_D != color_sand)
				map.SetTile(offset, CMap::rock_sand_border_diagonal_L1);				

			//straight edge shorelines
			else if (pixel_R == color_sand 
						&& pixel_U != color_sand && pixel_LU != color_sand && pixel_L != color_sand && pixel_LD != color_sand && pixel_D != color_sand)
				map.SetTile(offset, CMap::rock_sand_border_straight_R1);	
			else if (pixel_U == color_sand
						&& pixel_R != color_sand && pixel_L != color_sand && pixel_LD != color_sand && pixel_D != color_sand && pixel_RD != color_sand)
				map.SetTile(offset, CMap::rock_sand_border_straight_U1);	
			else if (pixel_L == color_sand
						&& pixel_R != color_sand && pixel_RU != color_sand && pixel_U != color_sand && pixel_D != color_sand && pixel_RD != color_sand)
				map.SetTile(offset, CMap::rock_sand_border_straight_L1);	
			else if (pixel_D == color_sand
						&& pixel_R != color_sand && pixel_RU != color_sand && pixel_U != color_sand && pixel_LU != color_sand && pixel_L != color_sand)
				map.SetTile(offset, CMap::rock_sand_border_straight_D1);	
				
			//convex shorelines
			else if (pixel_R == color_sand && pixel_U == color_sand)
				map.SetTile(offset, CMap::rock_sand_border_convex_RU1);
			else if (pixel_L == color_sand && pixel_U == color_sand)
				map.SetTile(offset, CMap::rock_sand_border_convex_LU1);
			else if (pixel_L == color_sand && pixel_D == color_sand)
				map.SetTile(offset, CMap::rock_sand_border_convex_LD1);
			else if (pixel_R == color_sand && pixel_D == color_sand)
				map.SetTile(offset, CMap::rock_sand_border_convex_RD1);
				
			//concave shorelines		
			else if (pixel_RU == color_sand)
				map.SetTile(offset, CMap::rock_sand_border_concave_RU1);	
			else if (pixel_LU == color_sand)
				map.SetTile(offset, CMap::rock_sand_border_concave_LU1);	
			else if (pixel_LD == color_sand)
				map.SetTile(offset, CMap::rock_sand_border_concave_LD1);	
			else if (pixel_RD == color_sand)
				map.SetTile(offset, CMap::rock_sand_border_concave_RD1);		
				
			//ROCK SURROUNDED BY SHOAL
			//completely surrrounded ship
			else if (pixel_R == color_shoal && pixel_U == color_shoal && pixel_L == color_shoal && pixel_D == color_shoal)
				map.SetTile(offset, CMap::rock_shoal_border_ship1);
				
			//four way crossing
			else if (pixel_RU == color_shoal && pixel_LU == color_shoal && pixel_LD == color_shoal && pixel_RD == color_shoal
						&& pixel_R != color_shoal && pixel_U != color_shoal && pixel_L != color_shoal && pixel_D != color_shoal)
				map.SetTile(offset, CMap::rock_shoal_border_cross1);		
		
			//peninsula shorelines
			else if (pixel_R == color_shoal && pixel_U == color_shoal && pixel_D == color_shoal)
				map.SetTile(offset, CMap::rock_shoal_border_peninsula_R1);
			else if (pixel_R == color_shoal && pixel_U == color_shoal && pixel_L == color_shoal)
				map.SetTile(offset, CMap::rock_shoal_border_peninsula_U1);
			else if (pixel_U == color_shoal && pixel_L == color_shoal && pixel_D == color_shoal)
				map.SetTile(offset, CMap::rock_shoal_border_peninsula_L1);
			else if (pixel_L == color_shoal && pixel_D == color_shoal && pixel_R == color_shoal)
				map.SetTile(offset, CMap::rock_shoal_border_peninsula_D1);
				
			//three way T crossings
			else if (pixel_R == color_shoal && pixel_LU == color_shoal && pixel_LD == color_shoal
						&& pixel_U != color_shoal && pixel_L != color_shoal && pixel_D != color_shoal)
				map.SetTile(offset, CMap::rock_shoal_border_T_R1);
			else if (pixel_U == color_shoal && pixel_RD == color_shoal && pixel_LD == color_shoal
						&& pixel_R != color_shoal && pixel_L != color_shoal && pixel_D != color_shoal)
				map.SetTile(offset, CMap::rock_shoal_border_T_U1);
			else if (pixel_RU == color_shoal && pixel_L == color_shoal && pixel_RD == color_shoal
						&& pixel_R != color_shoal && pixel_U != color_shoal && pixel_D != color_shoal)
				map.SetTile(offset, CMap::rock_shoal_border_T_L1);
			else if (pixel_RU == color_shoal && pixel_LU == color_shoal && pixel_D == color_shoal
						&& pixel_R != color_shoal && pixel_U != color_shoal && pixel_L != color_shoal)
				map.SetTile(offset, CMap::rock_shoal_border_T_D1);
				
			//left handed panhandle
			else if (pixel_R == color_shoal && pixel_LU == color_shoal
						&& pixel_U != color_shoal && pixel_L != color_shoal && pixel_LD != color_shoal && pixel_D != color_shoal)
				map.SetTile(offset, CMap::rock_shoal_border_panhandleL_R1);
			else if (pixel_U == color_shoal && pixel_LD == color_shoal 
						&& pixel_R != color_shoal && pixel_L != color_shoal && pixel_D != color_shoal && pixel_RD != color_shoal)
				map.SetTile(offset, CMap::rock_shoal_border_panhandleL_U1);
			else if (pixel_L == color_shoal && pixel_RD == color_shoal 
						&& pixel_R != color_shoal && pixel_RU != color_shoal && pixel_U != color_shoal && pixel_D != color_shoal)
				map.SetTile(offset, CMap::rock_shoal_border_panhandleL_L1);
			else if (pixel_RU == color_shoal && pixel_D == color_shoal
						&& pixel_R != color_shoal && pixel_U != color_shoal && pixel_LU != color_shoal && pixel_L != color_shoal)
				map.SetTile(offset, CMap::rock_shoal_border_panhandleL_D1);
				
			//right handed panhandle
			else if (pixel_R == color_shoal && pixel_LD == color_shoal 
						&& pixel_U != color_shoal && pixel_LU != color_shoal && pixel_L != color_shoal && pixel_D != color_shoal)
				map.SetTile(offset, CMap::rock_shoal_border_panhandleR_R1);
			else if (pixel_U == color_shoal && pixel_RD == color_shoal
						&& pixel_R != color_shoal && pixel_L != color_shoal && pixel_LD != color_shoal && pixel_D != color_shoal)
				map.SetTile(offset, CMap::rock_shoal_border_panhandleR_U1);
			else if (pixel_RU == color_shoal && pixel_L == color_shoal
						&& pixel_R != color_shoal && pixel_U != color_shoal && pixel_D != color_shoal && pixel_RD != color_shoal)
				map.SetTile(offset, CMap::rock_shoal_border_panhandleR_L1);
			else if (pixel_LU == color_shoal && pixel_D == color_shoal 
						&& pixel_R != color_shoal && pixel_RU != color_shoal && pixel_U != color_shoal && pixel_L != color_shoal)
				map.SetTile(offset, CMap::rock_shoal_border_panhandleR_D1);
				
			//splitting strips
			else if (pixel_RU == color_shoal && pixel_LU == color_shoal && pixel_RD == color_shoal
						&& pixel_R != color_shoal && pixel_U != color_shoal && pixel_L != color_shoal && pixel_LD != color_shoal && pixel_D != color_shoal)
				map.SetTile(offset, CMap::rock_shoal_border_split_RU1);
			else if (pixel_RU == color_shoal && pixel_LU == color_shoal && pixel_LD == color_shoal 
						&& pixel_R != color_shoal && pixel_U != color_shoal && pixel_L != color_shoal && pixel_D != color_shoal && pixel_RD != color_shoal)
				map.SetTile(offset, CMap::rock_shoal_border_split_LU1);
			else if (pixel_LU == color_shoal && pixel_LD == color_shoal && pixel_RD == color_shoal 
						&& pixel_R != color_shoal && pixel_RU != color_shoal && pixel_U != color_shoal && pixel_L != color_shoal && pixel_D != color_shoal)
				map.SetTile(offset, CMap::rock_shoal_border_split_LD1);
			else if (pixel_RU == color_shoal && pixel_LD == color_shoal && pixel_RD == color_shoal 
						&& pixel_R != color_shoal && pixel_U != color_shoal && pixel_LU != color_shoal && pixel_L != color_shoal && pixel_D != color_shoal)
				map.SetTile(offset, CMap::rock_shoal_border_split_RD1);
				
			//choke points
			else if (pixel_RU == color_shoal && pixel_RD == color_shoal 
						&& pixel_R != color_shoal && pixel_U != color_shoal && pixel_LU != color_shoal && pixel_L != color_shoal && pixel_LD != color_shoal && pixel_D != color_shoal)
				map.SetTile(offset, CMap::rock_shoal_border_choke_R1);
			else if (pixel_RU == color_shoal && pixel_LU == color_shoal 
						&& pixel_R != color_shoal && pixel_U != color_shoal && pixel_L != color_shoal && pixel_LD != color_shoal && pixel_D != color_shoal && pixel_RD != color_shoal)
				map.SetTile(offset, CMap::rock_shoal_border_choke_U1);
			else if (pixel_LU == color_shoal && pixel_LD == color_shoal 
						&& pixel_R != color_shoal && pixel_RU != color_shoal && pixel_U != color_shoal && pixel_L != color_shoal && pixel_D != color_shoal && pixel_RD != color_shoal)
				map.SetTile(offset, CMap::rock_shoal_border_choke_L1);
			else if (pixel_LD == color_shoal && pixel_RD == color_shoal 
						&& pixel_R != color_shoal && pixel_RU != color_shoal && pixel_U != color_shoal && pixel_LU != color_shoal && pixel_L != color_shoal && pixel_D != color_shoal)
				map.SetTile(offset, CMap::rock_shoal_border_choke_D1);
				
			//strip shorelines
			else if (pixel_U == color_shoal && pixel_D == color_shoal)
				map.SetTile(offset, CMap::rock_shoal_border_strip_H1);
			else if (pixel_R == color_shoal && pixel_L == color_shoal)
				map.SetTile(offset, CMap::rock_shoal_border_strip_V1);	

			//bend shorelines
			else if (pixel_R == color_shoal && pixel_RU == color_shoal && pixel_U == color_shoal && pixel_LD == color_shoal)
				map.SetTile(offset, CMap::rock_shoal_border_bend_RU1);
			else if (pixel_L == color_shoal && pixel_LU == color_shoal && pixel_U == color_shoal && pixel_RD == color_shoal)
				map.SetTile(offset, CMap::rock_shoal_border_bend_LU1);
			else if (pixel_L == color_shoal && pixel_LD == color_shoal && pixel_D == color_shoal && pixel_RU == color_shoal)
				map.SetTile(offset, CMap::rock_shoal_border_bend_LD1);
			else if (pixel_R == color_shoal && pixel_RD == color_shoal && pixel_D == color_shoal && pixel_LU == color_shoal)
				map.SetTile(offset, CMap::rock_shoal_border_bend_RD1);		

			//diagonal choke points
			else if (pixel_RU == color_shoal && pixel_LD == color_shoal
						&& pixel_R != color_shoal && pixel_U != color_shoal && pixel_LU != color_shoal && pixel_L != color_shoal && pixel_D != color_shoal && pixel_RD != color_shoal)
				map.SetTile(offset, CMap::rock_shoal_border_diagonal_R1);	
			else if (pixel_LU == color_shoal && pixel_RD == color_shoal
						&& pixel_R != color_shoal && pixel_RU != color_shoal && pixel_U != color_shoal && pixel_L != color_shoal && pixel_LD != color_shoal && pixel_D != color_shoal)
				map.SetTile(offset, CMap::rock_shoal_border_diagonal_L1);				

			//straight edge shorelines
			else if (pixel_R == color_shoal 
						&& pixel_U != color_shoal && pixel_LU != color_shoal && pixel_L != color_shoal && pixel_LD != color_shoal && pixel_D != color_shoal)
				map.SetTile(offset, CMap::rock_shoal_border_straight_R1);	
			else if (pixel_U == color_shoal
						&& pixel_R != color_shoal && pixel_L != color_shoal && pixel_LD != color_shoal && pixel_D != color_shoal && pixel_RD != color_shoal)
				map.SetTile(offset, CMap::rock_shoal_border_straight_U1);	
			else if (pixel_L == color_shoal
						&& pixel_R != color_shoal && pixel_RU != color_shoal && pixel_U != color_shoal && pixel_D != color_shoal && pixel_RD != color_shoal)
				map.SetTile(offset, CMap::rock_shoal_border_straight_L1);	
			else if (pixel_D == color_shoal
						&& pixel_R != color_shoal && pixel_RU != color_shoal && pixel_U != color_shoal && pixel_LU != color_shoal && pixel_L != color_shoal)
				map.SetTile(offset, CMap::rock_shoal_border_straight_D1);	
				
			//convex shorelines
			else if (pixel_R == color_shoal && pixel_U == color_shoal)
				map.SetTile(offset, CMap::rock_shoal_border_convex_RU1);
			else if (pixel_L == color_shoal && pixel_U == color_shoal)
				map.SetTile(offset, CMap::rock_shoal_border_convex_LU1);
			else if (pixel_L == color_shoal && pixel_D == color_shoal)
				map.SetTile(offset, CMap::rock_shoal_border_convex_LD1);
			else if (pixel_R == color_shoal && pixel_D == color_shoal)
				map.SetTile(offset, CMap::rock_shoal_border_convex_RD1);
				
			//concave shorelines		
			else if (pixel_RU == color_shoal)
				map.SetTile(offset, CMap::rock_shoal_border_concave_RU1);	
			else if (pixel_LU == color_shoal)
				map.SetTile(offset, CMap::rock_shoal_border_concave_LU1);	
			else if (pixel_LD == color_shoal)
				map.SetTile(offset, CMap::rock_shoal_border_concave_LD1);	
			else if (pixel_RD == color_shoal)
				map.SetTile(offset, CMap::rock_shoal_border_concave_RD1);
		
			//ROCK SURROUNDED BY WATER
			//completely surrrounded ship
			else if (pixel_R == color_water && pixel_U == color_water && pixel_L == color_water && pixel_D == color_water)
				map.SetTile(offset, CMap::rock_shore_ship1);
				
			//four way crossing
			else if (pixel_RU == color_water && pixel_LU == color_water && pixel_LD == color_water && pixel_RD == color_water
						&& pixel_R != color_water && pixel_U != color_water && pixel_L != color_water && pixel_D != color_water)
				map.SetTile(offset, CMap::rock_shore_cross1);		
		
			//peninsula shorelines
			else if (pixel_R == color_water && pixel_U == color_water && pixel_D == color_water)
				map.SetTile(offset, CMap::rock_shore_peninsula_R1);
			else if (pixel_R == color_water && pixel_U == color_water && pixel_L == color_water)
				map.SetTile(offset, CMap::rock_shore_peninsula_U1);
			else if (pixel_U == color_water && pixel_L == color_water && pixel_D == color_water)
				map.SetTile(offset, CMap::rock_shore_peninsula_L1);
			else if (pixel_L == color_water && pixel_D == color_water && pixel_R == color_water)
				map.SetTile(offset, CMap::rock_shore_peninsula_D1);
				
			//three way T crossings
			else if (pixel_R == color_water && pixel_LU == color_water && pixel_LD == color_water
						&& pixel_U != color_water && pixel_L != color_water && pixel_D != color_water)
				map.SetTile(offset, CMap::rock_shore_T_R1);
			else if (pixel_U == color_water && pixel_RD == color_water && pixel_LD == color_water
						&& pixel_R != color_water && pixel_L != color_water && pixel_D != color_water)
				map.SetTile(offset, CMap::rock_shore_T_U1);
			else if (pixel_RU == color_water && pixel_L == color_water && pixel_RD == color_water
						&& pixel_R != color_water && pixel_U != color_water && pixel_D != color_water)
				map.SetTile(offset, CMap::rock_shore_T_L1);
			else if (pixel_RU == color_water && pixel_LU == color_water && pixel_D == color_water
						&& pixel_R != color_water && pixel_U != color_water && pixel_L != color_water)
				map.SetTile(offset, CMap::rock_shore_T_D1);
				
			//left handed panhandle
			else if (pixel_R == color_water && pixel_LU == color_water
						&& pixel_U != color_water && pixel_L != color_water && pixel_LD != color_water && pixel_D != color_water)
				map.SetTile(offset, CMap::rock_shore_panhandleL_R1);
			else if (pixel_U == color_water && pixel_LD == color_water 
						&& pixel_R != color_water && pixel_L != color_water && pixel_D != color_water && pixel_RD != color_water)
				map.SetTile(offset, CMap::rock_shore_panhandleL_U1);
			else if (pixel_L == color_water && pixel_RD == color_water 
						&& pixel_R != color_water && pixel_RU != color_water && pixel_U != color_water && pixel_D != color_water)
				map.SetTile(offset, CMap::rock_shore_panhandleL_L1);
			else if (pixel_RU == color_water && pixel_D == color_water
						&& pixel_R != color_water && pixel_U != color_water && pixel_LU != color_water && pixel_L != color_water)
				map.SetTile(offset, CMap::rock_shore_panhandleL_D1);
				
			//right handed panhandle
			else if (pixel_R == color_water && pixel_LD == color_water 
						&& pixel_U != color_water && pixel_LU != color_water && pixel_L != color_water && pixel_D != color_water)
				map.SetTile(offset, CMap::rock_shore_panhandleR_R1);
			else if (pixel_U == color_water && pixel_RD == color_water
						&& pixel_R != color_water && pixel_L != color_water && pixel_LD != color_water && pixel_D != color_water)
				map.SetTile(offset, CMap::rock_shore_panhandleR_U1);
			else if (pixel_RU == color_water && pixel_L == color_water
						&& pixel_R != color_water && pixel_U != color_water && pixel_D != color_water && pixel_RD != color_water)
				map.SetTile(offset, CMap::rock_shore_panhandleR_L1);
			else if (pixel_LU == color_water && pixel_D == color_water 
						&& pixel_R != color_water && pixel_RU != color_water && pixel_U != color_water && pixel_L != color_water)
				map.SetTile(offset, CMap::rock_shore_panhandleR_D1);
				
			//splitting strips
			else if (pixel_RU == color_water && pixel_LU == color_water && pixel_RD == color_water
						&& pixel_R != color_water && pixel_U != color_water && pixel_L != color_water && pixel_LD != color_water && pixel_D != color_water)
				map.SetTile(offset, CMap::rock_shore_split_RU1);
			else if (pixel_RU == color_water && pixel_LU == color_water && pixel_LD == color_water 
						&& pixel_R != color_water && pixel_U != color_water && pixel_L != color_water && pixel_D != color_water && pixel_RD != color_water)
				map.SetTile(offset, CMap::rock_shore_split_LU1);
			else if (pixel_LU == color_water && pixel_LD == color_water && pixel_RD == color_water 
						&& pixel_R != color_water && pixel_RU != color_water && pixel_U != color_water && pixel_L != color_water && pixel_D != color_water)
				map.SetTile(offset, CMap::rock_shore_split_LD1);
			else if (pixel_RU == color_water && pixel_LD == color_water && pixel_RD == color_water 
						&& pixel_R != color_water && pixel_U != color_water && pixel_LU != color_water && pixel_L != color_water && pixel_D != color_water)
				map.SetTile(offset, CMap::rock_shore_split_RD1);
				
			//choke points
			else if (pixel_RU == color_water && pixel_RD == color_water 
						&& pixel_R != color_water && pixel_U != color_water && pixel_LU != color_water && pixel_L != color_water && pixel_LD != color_water && pixel_D != color_water)
				map.SetTile(offset, CMap::rock_shore_choke_R1);
			else if (pixel_RU == color_water && pixel_LU == color_water 
						&& pixel_R != color_water && pixel_U != color_water && pixel_L != color_water && pixel_LD != color_water && pixel_D != color_water && pixel_RD != color_water)
				map.SetTile(offset, CMap::rock_shore_choke_U1);
			else if (pixel_LU == color_water && pixel_LD == color_water 
						&& pixel_R != color_water && pixel_RU != color_water && pixel_U != color_water && pixel_L != color_water && pixel_D != color_water && pixel_RD != color_water)
				map.SetTile(offset, CMap::rock_shore_choke_L1);
			else if (pixel_LD == color_water && pixel_RD == color_water 
						&& pixel_R != color_water && pixel_RU != color_water && pixel_U != color_water && pixel_LU != color_water && pixel_L != color_water && pixel_D != color_water)
				map.SetTile(offset, CMap::rock_shore_choke_D1);
				
			//strip shorelines
			else if (pixel_U == color_water && pixel_D == color_water)
				map.SetTile(offset, CMap::rock_shore_strip_H1);
			else if (pixel_R == color_water && pixel_L == color_water)
				map.SetTile(offset, CMap::rock_shore_strip_V1);	

			//bend shorelines
			else if (pixel_R == color_water && pixel_RU == color_water && pixel_U == color_water && pixel_LD == color_water)
				map.SetTile(offset, CMap::rock_shore_bend_RU1);
			else if (pixel_L == color_water && pixel_LU == color_water && pixel_U == color_water && pixel_RD == color_water)
				map.SetTile(offset, CMap::rock_shore_bend_LU1);
			else if (pixel_L == color_water && pixel_LD == color_water && pixel_D == color_water && pixel_RU == color_water)
				map.SetTile(offset, CMap::rock_shore_bend_LD1);
			else if (pixel_R == color_water && pixel_RD == color_water && pixel_D == color_water && pixel_LU == color_water)
				map.SetTile(offset, CMap::rock_shore_bend_RD1);		

			//diagonal choke points
			else if (pixel_RU == color_water && pixel_LD == color_water
						&& pixel_R != color_water && pixel_U != color_water && pixel_LU != color_water && pixel_L != color_water && pixel_D != color_water && pixel_RD != color_water)
				map.SetTile(offset, CMap::rock_shore_diagonal_R1);	
			else if (pixel_LU == color_water && pixel_RD == color_water
						&& pixel_R != color_water && pixel_RU != color_water && pixel_U != color_water && pixel_L != color_water && pixel_LD != color_water && pixel_D != color_water)
				map.SetTile(offset, CMap::rock_shore_diagonal_L1);				

			//straight edge shorelines
			else if (pixel_R == color_water 
						&& pixel_U != color_water && pixel_LU != color_water && pixel_L != color_water && pixel_LD != color_water && pixel_D != color_water)
				map.SetTile(offset, CMap::rock_shore_straight_R1);	
			else if (pixel_U == color_water
						&& pixel_R != color_water && pixel_L != color_water && pixel_LD != color_water && pixel_D != color_water && pixel_RD != color_water)
				map.SetTile(offset, CMap::rock_shore_straight_U1);	
			else if (pixel_L == color_water
						&& pixel_R != color_water && pixel_RU != color_water && pixel_U != color_water && pixel_D != color_water && pixel_RD != color_water)
				map.SetTile(offset, CMap::rock_shore_straight_L1);	
			else if (pixel_D == color_water
						&& pixel_R != color_water && pixel_RU != color_water && pixel_U != color_water && pixel_LU != color_water && pixel_L != color_water)
				map.SetTile(offset, CMap::rock_shore_straight_D1);	
				
			//convex shorelines
			else if (pixel_R == color_water && pixel_U == color_water)
				map.SetTile(offset, CMap::rock_shore_convex_RU1);
			else if (pixel_L == color_water && pixel_U == color_water)
				map.SetTile(offset, CMap::rock_shore_convex_LU1);
			else if (pixel_L == color_water && pixel_D == color_water)
				map.SetTile(offset, CMap::rock_shore_convex_LD1);
			else if (pixel_R == color_water && pixel_D == color_water)
				map.SetTile(offset, CMap::rock_shore_convex_RD1);
				
			//concave shorelines		
			else if (pixel_RU == color_water)
				map.SetTile(offset, CMap::rock_shore_concave_RU1);	
			else if (pixel_LU == color_water)
				map.SetTile(offset, CMap::rock_shore_concave_LU1);	
			else if (pixel_LD == color_water)
				map.SetTile(offset, CMap::rock_shore_concave_LD1);	
			else if (pixel_RD == color_water)
				map.SetTile(offset, CMap::rock_shore_concave_RD1);
			else
				map.SetTile(offset, CMap::rock_inland + map_random.NextRanged(5));	
			
			map.AddTileFlag(offset, Tile::SOLID | Tile::COLLISION | Tile::LIGHT_PASSES);
		}
		else if (pixel == color_shoal) 
		{
			//completely surrrounded ship
			if (pixel_R == color_water && pixel_U == color_water && pixel_L == color_water && pixel_D == color_water)
				map.SetTile(offset, CMap::shoal_shore_ship1);
				
			//four way crossing
			else if (pixel_RU == color_water && pixel_LU == color_water && pixel_LD == color_water && pixel_RD == color_water
						&& pixel_R != color_water && pixel_U != color_water && pixel_L != color_water && pixel_D != color_water)
				map.SetTile(offset, CMap::shoal_shore_cross1);		
		
			//peninsula shorelines
			else if (pixel_R == color_water && pixel_U == color_water && pixel_D == color_water)
				map.SetTile(offset, CMap::shoal_shore_peninsula_R1);
			else if (pixel_R == color_water && pixel_U == color_water && pixel_L == color_water)
				map.SetTile(offset, CMap::shoal_shore_peninsula_U1);
			else if (pixel_U == color_water && pixel_L == color_water && pixel_D == color_water)
				map.SetTile(offset, CMap::shoal_shore_peninsula_L1);
			else if (pixel_L == color_water && pixel_D == color_water && pixel_R == color_water)
				map.SetTile(offset, CMap::shoal_shore_peninsula_D1);
				
			//three way T crossings
			else if (pixel_R == color_water && pixel_LU == color_water && pixel_LD == color_water
						&& pixel_U != color_water && pixel_L != color_water && pixel_D != color_water)
				map.SetTile(offset, CMap::shoal_shore_T_R1);
			else if (pixel_U == color_water && pixel_RD == color_water && pixel_LD == color_water
						&& pixel_R != color_water && pixel_L != color_water && pixel_D != color_water)
				map.SetTile(offset, CMap::shoal_shore_T_U1);
			else if (pixel_RU == color_water && pixel_L == color_water && pixel_RD == color_water
						&& pixel_R != color_water && pixel_U != color_water && pixel_D != color_water)
				map.SetTile(offset, CMap::shoal_shore_T_L1);
			else if (pixel_RU == color_water && pixel_LU == color_water && pixel_D == color_water
						&& pixel_R != color_water && pixel_U != color_water && pixel_L != color_water)
				map.SetTile(offset, CMap::shoal_shore_T_D1);
				
			//left handed panhandle
			else if (pixel_R == color_water && pixel_LU == color_water
						&& pixel_U != color_water && pixel_L != color_water && pixel_LD != color_water && pixel_D != color_water)
				map.SetTile(offset, CMap::shoal_shore_panhandleL_R1);
			else if (pixel_U == color_water && pixel_LD == color_water 
						&& pixel_R != color_water && pixel_L != color_water && pixel_D != color_water && pixel_RD != color_water)
				map.SetTile(offset, CMap::shoal_shore_panhandleL_U1);
			else if (pixel_L == color_water && pixel_RD == color_water 
						&& pixel_R != color_water && pixel_RU != color_water && pixel_U != color_water && pixel_D != color_water)
				map.SetTile(offset, CMap::shoal_shore_panhandleL_L1);
			else if (pixel_RU == color_water && pixel_D == color_water
						&& pixel_R != color_water && pixel_U != color_water && pixel_LU != color_water && pixel_L != color_water)
				map.SetTile(offset, CMap::shoal_shore_panhandleL_D1);
				
			//right handed panhandle
			else if (pixel_R == color_water && pixel_LD == color_water 
						&& pixel_U != color_water && pixel_LU != color_water && pixel_L != color_water && pixel_D != color_water)
				map.SetTile(offset, CMap::shoal_shore_panhandleR_R1);
			else if (pixel_U == color_water && pixel_RD == color_water
						&& pixel_R != color_water && pixel_L != color_water && pixel_LD != color_water && pixel_D != color_water)
				map.SetTile(offset, CMap::shoal_shore_panhandleR_U1);
			else if (pixel_RU == color_water && pixel_L == color_water
						&& pixel_R != color_water && pixel_U != color_water && pixel_D != color_water && pixel_RD != color_water)
				map.SetTile(offset, CMap::shoal_shore_panhandleR_L1);
			else if (pixel_LU == color_water && pixel_D == color_water 
						&& pixel_R != color_water && pixel_RU != color_water && pixel_U != color_water && pixel_L != color_water)
				map.SetTile(offset, CMap::shoal_shore_panhandleR_D1);
				
			//splitting strips
			else if (pixel_RU == color_water && pixel_LU == color_water && pixel_RD == color_water
						&& pixel_R != color_water && pixel_U != color_water && pixel_L != color_water && pixel_LD != color_water && pixel_D != color_water)
				map.SetTile(offset, CMap::shoal_shore_split_RU1);
			else if (pixel_RU == color_water && pixel_LU == color_water && pixel_LD == color_water 
						&& pixel_R != color_water && pixel_U != color_water && pixel_L != color_water && pixel_D != color_water && pixel_RD != color_water)
				map.SetTile(offset, CMap::shoal_shore_split_LU1);
			else if (pixel_LU == color_water && pixel_LD == color_water && pixel_RD == color_water 
						&& pixel_R != color_water && pixel_RU != color_water && pixel_U != color_water && pixel_L != color_water && pixel_D != color_water)
				map.SetTile(offset, CMap::shoal_shore_split_LD1);
			else if (pixel_RU == color_water && pixel_LD == color_water && pixel_RD == color_water 
						&& pixel_R != color_water && pixel_U != color_water && pixel_LU != color_water && pixel_L != color_water && pixel_D != color_water)
				map.SetTile(offset, CMap::shoal_shore_split_RD1);
				
			//choke points
			else if (pixel_RU == color_water && pixel_RD == color_water 
						&& pixel_R != color_water && pixel_U != color_water && pixel_LU != color_water && pixel_L != color_water && pixel_LD != color_water && pixel_D != color_water)
				map.SetTile(offset, CMap::shoal_shore_choke_R1);
			else if (pixel_RU == color_water && pixel_LU == color_water 
						&& pixel_R != color_water && pixel_U != color_water && pixel_L != color_water && pixel_LD != color_water && pixel_D != color_water && pixel_RD != color_water)
				map.SetTile(offset, CMap::shoal_shore_choke_U1);
			else if (pixel_LU == color_water && pixel_LD == color_water 
						&& pixel_R != color_water && pixel_RU != color_water && pixel_U != color_water && pixel_L != color_water && pixel_D != color_water && pixel_RD != color_water)
				map.SetTile(offset, CMap::shoal_shore_choke_L1);
			else if (pixel_LD == color_water && pixel_RD == color_water 
						&& pixel_R != color_water && pixel_RU != color_water && pixel_U != color_water && pixel_LU != color_water && pixel_L != color_water && pixel_D != color_water)
				map.SetTile(offset, CMap::shoal_shore_choke_D1);
				
			//strip shorelines
			else if (pixel_U == color_water && pixel_D == color_water)
				map.SetTile(offset, CMap::shoal_shore_strip_H1);
			else if (pixel_R == color_water && pixel_L == color_water)
				map.SetTile(offset, CMap::shoal_shore_strip_V1);	

			//bend shorelines
			else if (pixel_R == color_water && pixel_RU == color_water && pixel_U == color_water && pixel_LD == color_water)
				map.SetTile(offset, CMap::shoal_shore_bend_RU1);
			else if (pixel_L == color_water && pixel_LU == color_water && pixel_U == color_water && pixel_RD == color_water)
				map.SetTile(offset, CMap::shoal_shore_bend_LU1);
			else if (pixel_L == color_water && pixel_LD == color_water && pixel_D == color_water && pixel_RU == color_water)
				map.SetTile(offset, CMap::shoal_shore_bend_LD1);
			else if (pixel_R == color_water && pixel_RD == color_water && pixel_D == color_water && pixel_LU == color_water)
				map.SetTile(offset, CMap::shoal_shore_bend_RD1);		

			//diagonal choke points
			else if (pixel_RU == color_water && pixel_LD == color_water
						&& pixel_R != color_water && pixel_U != color_water && pixel_LU != color_water && pixel_L != color_water && pixel_D != color_water && pixel_RD != color_water)
				map.SetTile(offset, CMap::shoal_shore_diagonal_R1);	
			else if (pixel_LU == color_water && pixel_RD == color_water
						&& pixel_R != color_water && pixel_RU != color_water && pixel_U != color_water && pixel_L != color_water && pixel_LD != color_water && pixel_D != color_water)
				map.SetTile(offset, CMap::shoal_shore_diagonal_L1);				

			//straight edge shorelines
			else if (pixel_R == color_water 
						&& pixel_U != color_water && pixel_LU != color_water && pixel_L != color_water && pixel_LD != color_water && pixel_D != color_water)
				map.SetTile(offset, CMap::shoal_shore_straight_R1);	
			else if (pixel_U == color_water
						&& pixel_R != color_water && pixel_L != color_water && pixel_LD != color_water && pixel_D != color_water && pixel_RD != color_water)
				map.SetTile(offset, CMap::shoal_shore_straight_U1);	
			else if (pixel_L == color_water
						&& pixel_R != color_water && pixel_RU != color_water && pixel_U != color_water && pixel_D != color_water && pixel_RD != color_water)
				map.SetTile(offset, CMap::shoal_shore_straight_L1);	
			else if (pixel_D == color_water
						&& pixel_R != color_water && pixel_RU != color_water && pixel_U != color_water && pixel_LU != color_water && pixel_L != color_water)
				map.SetTile(offset, CMap::shoal_shore_straight_D1);	
				
			//convex shorelines
			else if (pixel_R == color_water && pixel_U == color_water)
				map.SetTile(offset, CMap::shoal_shore_convex_RU1);
			else if (pixel_L == color_water && pixel_U == color_water)
				map.SetTile(offset, CMap::shoal_shore_convex_LU1);
			else if (pixel_L == color_water && pixel_D == color_water)
				map.SetTile(offset, CMap::shoal_shore_convex_LD1);
			else if (pixel_R == color_water && pixel_D == color_water)
				map.SetTile(offset, CMap::shoal_shore_convex_RD1);
				
			//concave shorelines		
			else if (pixel_RU == color_water)
				map.SetTile(offset, CMap::shoal_shore_concave_RU1);	
			else if (pixel_LU == color_water)
				map.SetTile(offset, CMap::shoal_shore_concave_LU1);	
			else if (pixel_LD == color_water)
				map.SetTile(offset, CMap::shoal_shore_concave_LD1);	
			else if (pixel_RD == color_water)
				map.SetTile(offset, CMap::shoal_shore_concave_RD1);		
			else
				map.SetTile(offset, CMap::shoal_inland + map_random.NextRanged(5));	
			
			map.AddTileFlag(offset, Tile::BACKGROUND);
			map.AddTileFlag(offset, Tile::LIGHT_PASSES);
		}
	}
}
