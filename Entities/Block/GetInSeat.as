#include "AccurateSoundPlay.as";

void onInit(CBlob@ this)
{
	this.set_string("seat label", "");
	this.set_u8("seat icon", 0);
	this.addCommandID("get in seat");
	this.Tag("hasSeat");
}

void GetButtonsFor(CBlob@ this, CBlob@ caller)
{
	string seatOwner = this.get_string("playerOwner");
	if (this.getDistanceTo(caller) > 6
		|| this.getShape().getVars().customData <= 0
		|| this.hasAttached()
		|| (this.hasTag("noEnemyEntry") && this.getTeamNum() != caller.getTeamNum()))
		return;

	CBitStream params;
	params.write_u16(caller.getNetworkID());
	CButton@ button = caller.CreateGenericButton(this.get_u8("seat icon"), Vec2f(0.0f, 0.0f), this, this.getCommandID("get in seat"), this.get_string("seat label"), params);
	if (button !is null)
	{
		button.radius = 3.3f;
	}
}

void onCommand(CBlob@ this, u8 cmd, CBitStream @params)
{
    if (cmd == this.getCommandID("get in seat"))
    {
		if (isServer())
		{
			CBlob@ caller = getBlobByNetworkID(params.read_netid());
			if (caller !is null)
			{
				this.server_AttachTo(caller, "SEAT");
			}
		}
	}
}

void onDie(CBlob@ this)
{
	if (isServer())
	{
		AttachmentPoint@ seat = this.getAttachmentPoint(0);
		CBlob@ b = seat.getOccupied();
		if (b !is null) b.server_Die();
	}
}

void onAttach(CBlob@ this, CBlob@ attached, AttachmentPoint @attachedPoint)
{
	directionalSoundPlay("GetInVehicle.ogg", this.getPosition());
}

void onDetach(CBlob@ this, CBlob@ detached, AttachmentPoint @attachedPoint)
{
	directionalSoundPlay("GetInVehicle.ogg", this.getPosition());
}