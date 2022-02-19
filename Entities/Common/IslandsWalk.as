//#define CLIENT_ONLY
#include "IslandsCommon.as";
#include "TileCommon.as";

//saving local values because the ones provied by sv aren't correct after a desync

void onInit(CBlob@ this)
{
	//this.getCurrentScript().runFlags |= Script::tick_myplayer;
	if (isClient() || (this.getPlayer() !is null && this.getPlayer().isBot()))
	{
		this.set_u16("isleCenterBlockID", 0);
		this.set_f32("isleOldAngle", 0);
		this.set_Vec2f("isleOldPos", Vec2f_zero);
	}
}

void onTick(CBlob@ this)
{
	if (!this.isOnGround())
		return;
	
	if (isClient() || (this.getPlayer() !is null && this.getPlayer().isBot()))
	{
		Island@ island = getIsland(this);
		if (island !is null && island.centerBlock !is null)
		{
			u16 id = island.centerBlock.getNetworkID();
			if (id != this.get_u16("isleCenterBlockID") || !this.wasOnGround())//island changed: set cached values to current
			{
				this.set_Vec2f("isleOldPos", island.centerBlock.getPosition());
				this.set_f32("isleOldAngle", island.centerBlock.getAngleDegrees());
				this.set_u16("isleCenterBlockID", id);
			}
			
			f32 islandAngle = island.centerBlock.getAngleDegrees();
			Vec2f islandPos = island.centerBlock.getPosition();
			Vec2f islandDisplacement = islandPos - this.get_Vec2f("isleOldPos");
			f32 islandAngleDelta = islandAngle - this.get_f32("isleOldAngle");
			Vec2f islandToBlob = this.getPosition() - islandPos + islandDisplacement;
			islandToBlob.RotateBy(islandAngleDelta);
			
			this.set_Vec2f("isleOldPos", islandPos);
			this.set_f32("isleOldAngle", islandAngle);

			CBlob@ islandBlock = getMap().getBlobAtPosition(islandPos + islandToBlob);
			if (isTouchingLand(this.getPosition()) ? islandBlock !is null : true) //Only move player if there is a block to move onto
				this.setPosition(islandPos + islandToBlob);
		}
	}
}