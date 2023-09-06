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
	WalkInfo walk;
	this.set("WalkInfo", @walk);
}

void onTick(CBlob@ this)
{
	if (!this.get_bool("onGround")) return;
	
	WalkInfo@ walk;
	if (!this.get("WalkInfo", @walk)) return;
	
	const s32 overlappingShipID = this.get_s32("shipID");
	Ship@ ship = overlappingShipID > 0 ? getShipSet().getShip(overlappingShipID) : null;
	if (ship !is null && ship.centerBlock !is null)
	{
		Vec2f pos = this.getPosition();
		const u16 id = ship.centerBlock.getNetworkID();
		if (id != walk.shipCenterBlockID || !this.wasOnGround()) //ship changed: change cached values to current
		{
			walk.shipCenterBlockID = id;
			walk.shipOldAngle = ship.centerBlock.getAngleDegrees();
			walk.shipOldPos = ship.centerBlock.getPosition();
		}
		
		const f32 shipAngle = ship.centerBlock.getAngleDegrees();
		Vec2f shipPos = ship.centerBlock.getPosition();
		const Vec2f shipDisplacement = shipPos - walk.shipOldPos;
		const f32 shipAngleDelta = shipAngle - walk.shipOldAngle;
		Vec2f shipToBlob = pos - shipPos + shipDisplacement;
		shipToBlob.RotateBy(shipAngleDelta);
		
		walk.shipOldPos = shipPos;
		walk.shipOldAngle = shipAngle;

		CBlob@ shipBlock = getMap().getBlobAtPosition(shipPos + shipToBlob);
		if (isTouchingLand(pos) ? shipBlock !is null : true) //only move player if there is a block to move onto
			this.setPosition(shipPos + shipToBlob);
	}
}
