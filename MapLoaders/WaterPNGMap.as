// loads a .PNG map
// PNG loader base class - extend this to add your own PNG loading functionality!

bool LoadMap(CMap@ map, const string& in fileName)
{
	PNGLoader loader();
	return loader.loadShiprektMap(map, fileName);
}

// --------------------------------------

#include "MapBanner.as";
#include "CustomMap.as";
#include "Booty.as"

class PNGLoader
{
	PNGLoader()	{}

	CFileImage@ image;
	CMap@ map;

	bool loadShiprektMap(CMap@ _map, const string& in filename)
	{
		@map = _map;

		if (!isServer())
		{
			CMap::SetupMap(map, 0, 0);
			return true;
		} 
		SetupBooty(getRules());

		@image = CFileImage(filename);		
		if (image.isLoaded())
		{
			CMap::SetupMap(map, image.getWidth(), image.getHeight());
			SetScreenFlash(0, 0, 0, 0, 0.0f); // has to be done on server like this when map is loading, it will be synced in engine to new joined people.

			while (image.nextPixel())
			{
				SColor pixel = image.readPixel();
				int offset = image.getPixelOffset();
				Vec2f pixelPos = image.getPixelPosition();
				CMap::handlePixel(map, image, pixel, offset, pixelPos);
				getNet().server_KeepConnectionsAlive();
			}

			return true;
		}
		return false;
	}
}
