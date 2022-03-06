//#define CLIENT_ONLY
#include "ShipsCommon.as";

void onInit(CBlob@ this)
{
	//this.getCurrentScript().runFlags |= Script::tick_myplayer;
	if (isClient() || (this.getPlayer() !is null && this.getPlayer().isBot()))
	{
		this.set_u16("shipCenterBlockID", 0);
		this.set_f32("shipOldAngle", 0);
		this.set_Vec2f("shipOldPos", Vec2f_zero);
	}
}

void onTick(CBlob@ this)
{
	if (!this.isOnGround()) return;
	
	if (isClient() || (this.getPlayer() !is null && this.getPlayer().isBot()))
	{
		Ship@ ship = getShip(this);
		if (ship !is null && ship.centerBlock !is null)
		{
			u16 id = ship.centerBlock.getNetworkID();
			if (id != this.get_u16("shipCenterBlockID") || !this.wasOnGround())//ship changed: set cached values to current
			{
				this.set_Vec2f("shipOldPos", ship.centerBlock.getPosition());
				this.set_f32("shipOldAngle", ship.centerBlock.getAngleDegrees());
				this.set_u16("shipCenterBlockID", id);
			}
			
			f32 shipAngle = ship.centerBlock.getAngleDegrees();
			Vec2f shipPos = ship.centerBlock.getPosition();
			Vec2f shipDisplacement = shipPos - this.get_Vec2f("shipOldPos");
			f32 shipAngleDelta = shipAngle - this.get_f32("shipOldAngle");
			Vec2f shipToBlob = this.getPosition() - shipPos + shipDisplacement;
			shipToBlob.RotateBy(shipAngleDelta);
			
			this.set_Vec2f("shipOldPos", shipPos);
			this.set_f32("shipOldAngle", shipAngle);

			CBlob@ shipBlock = getMap().getBlobAtPosition(shipPos + shipToBlob);
			if (shipBlock !is null) //Only move player if there is a block to move onto
				this.setPosition(shipPos + shipToBlob);
		}
	}
}