#include "AccurateSoundPlay.as";
#include "ShipsCommon.as";

void onInit(CBlob@ this)
{
	this.set_string("seat label", "");
	this.set_u8("seat icon", 0);
	this.addCommandID("get in seat");
	this.addCommandID("clear attached");
	this.Tag("hasSeat");
}

void GetButtonsFor(CBlob@ this, CBlob@ caller)
{
	//string seatOwner = this.get_string("playerOwner");
	if (this.getDistanceTo(caller) > 6
		|| this.getShape().getVars().customData <= 0
		|| (this.hasTag("noEnemyEntry") && this.getTeamNum() != caller.getTeamNum()))
		return;
	
	CPlayer@ player = caller.getPlayer();
	if (this.hasAttached() && player !is null && getCaptainName(this.getTeamNum()) == player.getUsername())
	{
		//push someone out of a seat if you are captain
		CButton@ button = caller.CreateGenericButton(5, Vec2f_zero, this, this.getCommandID("clear attached"), "Push Crewmate Out");
		if (button !is null)
		{
			button.radius = 8.0f;
			button.enableRadius = 12.0f;
		}
	}
	else if (!this.hasAttached())
	{
		CBitStream params;
		params.write_netid(caller.getNetworkID());
		CButton@ button = caller.CreateGenericButton(this.get_u8("seat icon"), Vec2f_zero, this, this.getCommandID("get in seat"), this.get_string("seat label"), params);
		if (button !is null)
		{
			button.radius = 8.0f;
			button.enableRadius = 12.0f;
		}
	}
}

void onCommand(CBlob@ this, u8 cmd, CBitStream@ params)
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
	else if (cmd == this.getCommandID("clear attached"))
	{
		AttachmentPoint@ seat = this.getAttachmentPoint(0);
		CBlob@ crewmate = seat.getOccupied();
		if (crewmate !is null && crewmate.isMyPlayer() && crewmate.getTeamNum() == this.getTeamNum())
			crewmate.SendCommand(crewmate.getCommandID("get out"));
	}
}

void onDie(CBlob@ this)
{
	if (isServer())
	{
		CBlob@ b = this.getAttachmentPoint(0).getOccupied();
		if (b !is null)
		{
			CBitStream params;
			params.write_netid(b.getNetworkID());
			b.SendCommand(b.getCommandID("run over"), params);
		}
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
