//Move players with their ships

//Slightly buggy since the player's dont appear in the right spots. :/
//Supposed to function by sending the player's server position on the ship to the clients
//To make it appear in the same position RELATIVE to the ship but for the clients
//The result is that server and client is technically desynced but is in the correct locations relative to the ship.
//Except that its not 100% working for some bullshit reason I have no clue about
//I need a hero to fix it

#include "ShipsCommon.as";
#include "TileCommon.as";

shared class WalkInfo
{
	s32 shipID;
	f32 shipOldAngle;
	Vec2f shipOldPos;
	
	WalkInfo()
	{
		shipID = 0;
		shipOldAngle = 0;
		shipOldPos = Vec2f_zero;
	}
};

void onInit(CBlob@ this)
{
	WalkInfo walk;
	this.set("WalkInfo", @walk);

	this.getShape().getConsts().net_threshold_multiplier = -1.0f; //stop engine shape sync, because we do our own superior synchronization.

	this.addCommandID("client_set_player_position");
}

void onTick(CBlob@ this)
{
	server_SetPlayerPositionWithShipNew(this);

	if (this.isMyPlayer())
	{
		this.set_f32("camera rotation", getCamera().getRotation());
		this.Sync("camera rotation", false);
	}
}

void server_SetPlayerPositionWithShip(CBlob@ this)
{
	if (!isServer()) return;

	WalkInfo@ walk;
	if (!this.get("WalkInfo", @walk)) return;
	
	Vec2f pos = this.getPosition();
	const s32 overlappingShipID = this.get_s32("shipID");
	if (this.getShape().getVars().onground)
	{
		Ship@ ship = overlappingShipID > 0 ? getShipSet().getShip(overlappingShipID) : null;
		if (ship !is null)
		{
			if (ship.id != walk.shipID || !this.wasOnGround()) //ship changed: change cached values to current
			{
				walk.shipID = ship.id;
				walk.shipOldAngle = ship.angle;
				walk.shipOldPos = ship.origin_pos;
			}

			const f32 shipAngleDelta = ship.angle - walk.shipOldAngle;
			Vec2f shipToBlob = pos - walk.shipOldPos;
			shipToBlob.RotateBy(shipAngleDelta);

			walk.shipOldPos = ship.origin_pos;
			walk.shipOldAngle = ship.angle;

			CBlob@ shipBlock = getMap().getBlobAtPosition(ship.origin_pos + shipToBlob);
			if (isTouchingLand(pos) ? shipBlock !is null : true) //only move player if there is a block to move onto
				this.setPosition(ship.origin_pos + shipToBlob);

			pos = shipToBlob;
			pos.RotateBy(-ship.angle);
		}
	}
	else
	{
		this.setPosition(pos);
	}

	CBitStream params;
	params.write_s32(overlappingShipID);
	params.write_Vec2f(pos);
	this.SendCommand(this.getCommandID("client_set_player_position"), params);
}

void onCommand(CBlob@ this, u8 cmd, CBitStream@ params)
{
	WalkInfo@ walk;
	if (!this.get("WalkInfo", @walk)) return;

	if (cmd == this.getCommandID("client_set_player_position") && isClient())
	{
		//sync player position to clients
		const s32 overlappingShipID = params.read_s32();
		Vec2f offset = params.read_Vec2f();
		if (overlappingShipID > 0)
		{
			Ship@ ship = getShipSet().getShip(overlappingShipID);
			if (ship is null) return;

			offset.RotateBy(ship.angle);
			offset += ship.origin_pos;
		}

		this.setPosition(offset);
	}
}
