#include "BlockCommon.as"
#include "AccurateSoundPlay.as"

void onInit( CBlob@ this )
{
	this.set_string("seat label", "");
	this.set_u8("seat icon", 0);
	this.addCommandID("get in seat");
	this.Tag("seat");
}

void GetButtonsFor( CBlob@ this, CBlob@ caller )
{
	string seatOwner = this.get_string( "playerOwner" );
	if(this.getDistanceTo(caller) > Block::BUTTON_RADIUS_FLOOR 
		|| this.getShape().getVars().customData <= 0
		|| this.hasAttached()
		|| this.exists( "seatEnabled" ))
		return;

	CBitStream params;
	params.write_u16( caller.getNetworkID() );
	CButton@ button = caller.CreateGenericButton( this.get_u8("seat icon"), Vec2f(0.0f, 0.0f), this, this.getCommandID("get in seat"), this.get_string("seat label"), params );
}

void onCommand( CBlob@ this, u8 cmd, CBitStream @params )
{
    if (cmd == this.getCommandID("get in seat"))
    {
		if ( getNet().isServer() )
		{
			string seatOwner;
			this.get( "playerOwner", seatOwner );
			CBlob@ caller = getBlobByNetworkID( params.read_netid() );
			if ( true )
				this.server_AttachTo( caller, "SEAT" );
		}
	}
}

void onAttach( CBlob@ this, CBlob@ attached, AttachmentPoint @attachedPoint )
{
	directionalSoundPlay( "GetInVehicle.ogg", this.getPosition() );
}

void onDetach( CBlob@ this, CBlob@ detached, AttachmentPoint @attachedPoint )
{
	directionalSoundPlay( "GetInVehicle.ogg", this.getPosition() );
	this.getShape().getVars().onground = true;
}