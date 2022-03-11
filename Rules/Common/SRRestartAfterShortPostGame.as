// Next Map after ~X seconds of count down

#define SERVER_ONLY

void onTick(CRules@ this)
{
    if (this.get_u8("endCount") != 1) //do nothing if the match is not over
        return;
		
	//remove these comments to activate playercount dependent map loading
	/*string nextMap = getRandomMap(this);
	if (nextMap != "")
	{
		LoadMap(nextMap);
	}
	else*/
	{
		LoadNextMap();//fallback to mapcycle file
	}
}

string getRandomMap(CRules@ this)
{
	//DYNAMIC MAPS- DEPENDENT ON SERVER PLAYER AMOUNT
	//needs configuration for player counts
	string[] maps;
	string currentMap = getMap().getMapName().replace("Maps/", "");
	u8 pCount = getPlayerCount();
	
	if (pCount <= 8) //add maps to the cycle if less than nine players
	{
		maps.push_back("CenterIsles.png");
		maps.push_back("CenterIsles4.png");
		maps.push_back("CenterIsles5.png"); 	    
		maps.push_back("Clover.png");           
		maps.push_back("Tribute.png");  
		maps.push_back("Tow.png"); 
		maps.push_back("Hallway.png");
		maps.push_back("Lagoon.png");
		maps.push_back("Lagoon2.png");
		maps.push_back("Bowllake.png");
		maps.push_back("Bowllake2.png");
		maps.push_back("SandBars.png");
		maps.push_back("Aggro.png");
		maps.push_back("LandSlabs.png");
		maps.push_back("Startle.png");
		maps.push_back("Lanes.png");
		maps.push_back("Steer.png");  
		maps.push_back("Excellent.png");
		maps.push_back("Firefight.png");
		maps.push_back("Arenas.png");
		maps.push_back("Expanse.png");
		maps.push_back("Newmap.png");
		maps.push_back("Runaway.png");
		maps.push_back("Knight'sTale.png");
	}

	//add these maps to the cycle if less than eleven players, but more than four players
	/*if (pCount > 4 && pCount <= 10)
	{
		maps.push_back("TestMap.png");
	}*/

	//add these maps to the cycle if more than eight players
	/*if (pCount > 8)
	{
		maps.push_back("TestMap2.png");
	}*/
	
	if (maps.length() <= 0)
	{
		warn("SRRestartAfterShortPostGame.as: could not load random map");
		return "";
	}
	
	//remove current map
	if (maps.length() > 1)
	{
		int mIndex = maps.find(currentMap);
		if (mIndex > -1)
			maps.removeAt(mIndex);
	}
	
	//choose random map from list
	string map = maps[XORRandom(maps.length())];
	
	return map;
}
