#define CLIENT_ONLY
#include "IslandsCommon.as"

//saving local values because the ones provied by sv aren't correct after a desync
u16 currentCenterBlockID = 0;
f32 islandOldAngle = 0;
Vec2f islandOldPos = Vec2f_zero;

void onInit( CBlob@ this )
{
	this.getCurrentScript().runFlags |= Script::tick_myplayer;
	currentCenterBlockID = 0;
	islandOldAngle = 0;
	islandOldPos = Vec2f_zero;
}

void onTick( CBlob@ this )
{
	if ( !this.isOnGround() )
		return;
		
	Island@ island = getIsland( this );
	if ( island !is null && island.centerBlock !is null )
	{
		u16 id = island.centerBlock.getNetworkID();
		if ( id != currentCenterBlockID || !this.wasOnGround() )//island changed: set cached values to current
		{
			islandOldPos = island.centerBlock.getPosition();
			islandOldAngle = island.centerBlock.getAngleDegrees();
			currentCenterBlockID = id;
		}
		
    	Vec2f pos = this.getPosition();
		f32 islandAngle = island.centerBlock.getAngleDegrees();
		Vec2f islandPos = island.centerBlock.getPosition();
		Vec2f islandDisplacement = islandPos - islandOldPos;
		f32 islandAngleDelta = islandAngle - islandOldAngle;
		Vec2f islandToBlob = pos - islandPos + islandDisplacement;
		islandToBlob.RotateBy( islandAngleDelta );
		
		islandOldPos = islandPos;
		islandOldAngle = islandAngle;
		this.setPosition( islandPos + islandToBlob );
	}
}