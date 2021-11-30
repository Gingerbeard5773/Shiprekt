#define CLIENT_ONLY
#include "IslandsCommon.as"

//sets the scoreboard icons.
//note: the mothership kills and deaths are set in Mothership.as. the score at Booty.as

void onTick( CRules@ this )
{
	if ( getGameTime() % 30 != 0 )
		return;
	u16 minutes = getGameTime()/30/60;
	this.gamemode_info = "> Score: player Booty <> Kills: Cores destroyed as Captain <> Deaths: Cores lost as Captain <\n       Gametime: " + minutes + " minute" + ( minutes != 1 ? "s" : "" );
		
	//get captains
	string[] captains;
	CBlob@[] cores;
	getBlobsByTag( "mothership", @cores );
	for ( u8 i = 0; i < cores.length; i++ )
	{
		Island@ isle = getIsland( cores[i].getShape().getVars().customData );
		if ( isle !is null && isle.owner != "" )
			captains.push_back( isle.owner );
	}
	
	//set vars
	u8 pCount= getPlayersCount();
	for ( u8 i = 0; i < pCount; i++ )
	{
		CPlayer@ player = getPlayer(i);
		if ( captains.find( player.getUsername() ) > -1 )
			player.SetScoreboardVars( "ScoreboardIcons.png", 0, Vec2f( 16,16 ) );
		else
			player.UnsetScoreboardVars();
	}
}