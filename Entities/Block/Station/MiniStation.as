// Mini Station
#include "ShipsCommon.as";

void onInit(CBlob@ this)
{
	this.Tag("ministation");
	this.Tag("noRenderHealth");
	this.set_u8("capture time", 10);
	
	CSprite@ sprite = this.getSprite();
    CSpriteLayer@ layer = sprite.addSpriteLayer("ministation", "Station.png", 16, 16);
    if (layer !is null)
    {
		layer.SetRelativeZ(1);
        layer.SetFrame(1);
    }
}

void onChangeTeam(CBlob@ this, const int oldTeam)
{
	CPlayer@ ourply = getLocalPlayer();
	if (ourply !is null)
	{
		if (this.getTeamNum() == ourply.getTeamNum())
		{
			Sound::Play("Captured.ogg");
		}
		else
		{
			Sound::Play("Captured2.ogg");
		}
	}
	
	Capture(this, this.getTeamNum());
}

void Capture(CBlob@ this, const int attackerTeam)
{
	Ship@ ship = getShip(this.getShape().getVars().customData);
	if (ship is null) return;

	if (!ship.isMothership)
	{
		//print ("setting team for " + ship.owner + "'s " + ship.id + " to " + attackerTeam );
		for (uint i = 0; i < ship.blocks.length; ++i)
		{
			CBlob@ b = getBlobByNetworkID(ship.blocks[i].blobID);
			if (b !is null)
			{
				b.server_setTeamNum(attackerTeam);
			}
		}
	}
}

f32 onHit(CBlob@ this, Vec2f worldPoint, Vec2f velocity, f32 damage, CBlob@ hitterBlob, u8 customData)
{
	return 0.0f;
}
