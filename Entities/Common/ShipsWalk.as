//#define CLIENT_ONLY
#include "ShipsCommon.as";
#include "TileCommon.as";

shared class WalkInfo
{
	u16 shipCenterBlockID;
	f32 shipOldAngle;
	Vec2f shipOldPos;
	
	WalkInfo()
	{
		shipCenterBlockID = 0;
		shipOldAngle = 0;
		shipOldPos = Vec2f_zero;
	}
};

void onInit(CBlob@ this)
{
	//this.getCurrentScript().runFlags |= Script::tick_myplayer;
	WalkInfo walk;
	this.set("WalkInfo", @walk);
}

void onTick(CBlob@ this)
{
	if (!this.get_bool("onGround")) return;
	
	//if (isClient() || (this.getPlayer() !is null && this.getPlayer().isBot()))
	{
		WalkInfo@ walk;
		if (!this.get("WalkInfo", @walk)) return;
		
		Ship@ ship = getShip(this);
		if (ship !is null && ship.centerBlock !is null)
		{
			u16 id = ship.centerBlock.getNetworkID();
			if (id != walk.shipCenterBlockID || !this.wasOnGround()) //ship changed: set cached values to current
			{
				walk.shipCenterBlockID = id;
				walk.shipOldAngle = ship.centerBlock.getAngleDegrees();
				walk.shipOldPos = ship.centerBlock.getPosition();
			}
			
			const f32 shipAngle = ship.centerBlock.getAngleDegrees();
			Vec2f shipPos = ship.centerBlock.getPosition();
			const Vec2f shipDisplacement = shipPos - walk.shipOldPos;
			const f32 shipAngleDelta = shipAngle - walk.shipOldAngle;
			Vec2f shipToBlob = this.getPosition() - shipPos + shipDisplacement;
			shipToBlob.RotateBy(shipAngleDelta);
			
			walk.shipOldPos = shipPos;
			walk.shipOldAngle = shipAngle;

			CBlob@ shipBlock = getMap().getBlobAtPosition(shipPos + shipToBlob);
			if (isTouchingLand(this.getPosition()) ? shipBlock !is null : true) //Only move player if there is a block to move onto
				this.setPosition(shipPos + shipToBlob);
		}
	}
}
