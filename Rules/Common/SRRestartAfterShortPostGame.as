// Next Map after ~X seconds of cool down

#define SERVER_ONLY

const int cooldown = 300;

void onRestart( CRules@ this )
{
    this.set_s32("restart_rules_after_game", getGameTime() + cooldown);
}

void onInit( CRules@ this )
{
	if (!this.exists("restart_rules_after_game_time")) {
		this.set_s32("restart_rules_after_game_time", cooldown);
	}
    onRestart(this);
}

void onTick( CRules@ this )
{
    if (this.isMatchRunning() && getGameTime() % 30 == 0)
    {
        this.set_s32("restart_rules_after_game", getGameTime() + this.get_s32("restart_rules_after_game_time"));
        return;
    }

    if (!this.isGameOver()) {//do nothing if the match is not over
        return;
    }

    s32 timeToEnd = this.get_s32("restart_rules_after_game") - getGameTime();

    if (timeToEnd <= 0)
    {
		this.SetGlobalMessage( "" );//patch
		string nextMap = getRandomMap( this );
		if ( nextMap != "" )
			LoadMap( nextMap );
		else
			LoadNextMap();//fallback to mapcycle
    }
}

string getRandomMap(CRules@ this)
{
	string[] maps;
	string currentMap = this.get_string( "currentMap" );
	u8 pCount = getPlayerCount();
	
	if ( pCount <= 8 || true )
	{
	 maps.push_back( "CenterIsles.png" );
	 maps.push_back( "CenterIsles4.png" );
	 maps.push_back( "CenterIsles5.png" ); 	    
	 maps.push_back( "Clover.png" );           
	 maps.push_back( "Tribute.png" );  
     maps.push_back( "Tow.png" ); 
     maps.push_back( "Hallway.png" );
     maps.push_back( "Lagoon.png" );
     maps.push_back( "Lagoon2.png" );
     maps.push_back( "Bowllake.png" );
     maps.push_back( "Bowllake2.png" );
     maps.push_back( "SandBars.png" );
	 maps.push_back( "Aggro.png" );
	 maps.push_back( "LandSlabs.png" );
	 maps.push_back( "Startle.png" );
	 maps.push_back( "Lanes.png" );
	 maps.push_back( "Steer.png" );  
	 maps.push_back( "Excellent.png" );
	 maps.push_back( "Firefight.png" );
	 maps.push_back( "Arenas.png" );
	 maps.push_back( "Expanse.png" );
	 maps.push_back( "Newmap.png" );
	 maps.push_back( "Runaway.png" );
	 maps.push_back( "Knight'sTale.png" );
	 }
	
	if ( pCount > 4 && pCount <= 10 )
		//maps.push_back( "TestMap.png" );
	
	if ( pCount > 8 )
		//maps.push_back( "TestMap2.png" );
		
	//remove current map
	if ( maps.length() > 1 )
	{
		int mIndex = maps.find( currentMap );
		if ( mIndex > -1 )
			maps.removeAt( mIndex );
	}
	
	string map = maps.length() > 0 ? maps[ XORRandom( maps.length() ) ] : "";
	
	while ( map == this.get_string( "currentMap" ) && maps.length() > 0 )
	{
		map = maps[ XORRandom( maps.length() ) ];
	}
	
	this.set_string( "currentMap", map );
	
	return map;
}