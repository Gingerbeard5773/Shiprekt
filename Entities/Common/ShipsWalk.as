//Move players with their ships

//Slightly buggy since players appear behind while the ships are moving. :/
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
	this.addCommandID("server_set_player_position");
}

void onTick(CBlob@ this)
{
	if (isServer() || this.isMyPlayer())
	{
		SetPlayerPositionWithShip(this);
	}

	if (this.isMyPlayer())
	{
		this.set_f32("camera rotation", getCamera().getRotation());
		this.Sync("camera rotation", false);
	}
}

void SetPlayerPositionWithShip(CBlob@ this)
{
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

	if (isServer())
	{
		CBitStream params;
		params.write_s32(overlappingShipID);
		params.write_Vec2f(pos);
		this.SendCommand(this.getCommandID("client_set_player_position"), params);
	}
}

void SetSynchronizedPosition(CBlob@ this, const s32&in overlappingShipID, Vec2f&in offset)
{
	if (overlappingShipID > 0)
	{
		Ship@ ship = getShipSet().getShip(overlappingShipID);
		if (ship is null) return;

		offset.RotateBy(ship.angle);
		offset += ship.origin_pos;
	}
	
	this.setPosition(offset);
}

void onCommand(CBlob@ this, u8 cmd, CBitStream@ params)
{
	if (cmd == this.getCommandID("client_set_player_position") && isClient())
	{
		const s32 overlappingShipID = params.read_s32();
		Vec2f offset = params.read_Vec2f();

		if (this.isMyPlayer())
		{
			client_FixDesyncs(this, overlappingShipID, offset);
			return;
		}

		SetSynchronizedPosition(this, overlappingShipID, offset);
	}
	else if (cmd == this.getCommandID("server_set_player_position") && isServer())
	{
		const s32 overlappingShipID = params.read_s32();
		Vec2f offset = params.read_Vec2f();
		
		SetSynchronizedPosition(this, overlappingShipID, offset);
	}
}

const f32 resync_threshold = 16.0f;
void client_FixDesyncs(CBlob@ this, const s32&in server_shipID, Vec2f&in server_offset)
{
	if (isServer()) return; //localhost doesnt need to fix desyncs

	WalkInfo@ walk;
	if (!this.get("WalkInfo", @walk)) return;

	const s32 client_ShipID = this.get_s32("shipID");
	
	//sync (server -> my player)
	//this is a fix for when we experience a network drop, so we dont get booted off the ship randomly. surprisingly effective
	if (client_ShipID != server_shipID && server_shipID > 0)
	{
		SetSynchronizedPosition(this, server_shipID, server_offset);
		return;
	}

	//sync (my player -> server)
	//because the server and client will ALWAYS end up doing different things, this tries to make sure we never get too desynchronized
	Vec2f client_offset = this.getPosition();
	Ship@ ship = client_ShipID > 0 ? getShipSet().getShip(client_ShipID) : null;
	if (ship !is null)
	{
		const f32 shipAngleDelta = ship.angle - walk.shipOldAngle;
		client_offset -= walk.shipOldPos;
		client_offset.RotateBy(shipAngleDelta - ship.angle);
	}

	if ((server_offset - client_offset).Length() > resync_threshold) //are we are desynced
	{
		CBitStream params;
		params.write_s32(client_ShipID);
		params.write_Vec2f(client_offset);
		this.SendCommand(this.getCommandID("server_set_player_position"), params);
	}
}
