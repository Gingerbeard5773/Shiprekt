// Mini Station
#include "IslandsCommon.as";

void onInit(CBlob@ this)
{
	this.Tag("ministation"); 
	
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
	if (this.getTeamNum() >= 0 && this.getTeamNum() <= 10)
	{
		Sound::Play("Captured.ogg");
	}
	else
	{
		Sound::Play("Captured2.ogg");
	}
	
	Capture(this, this.getTeamNum());
}

void Capture(CBlob@ this, const int attackerTeam)
{
	Island@ isle = getIsland(this);
	if (isle is null) return;

	if (!isle.isMothership)
	{
		//print ("setting team for " + isle.owner + "'s " + isle.id + " to " + attackerTeam );
		for (uint i = 0; i < isle.blocks.length; ++i)
		{
			CBlob@ b = getBlobByNetworkID(isle.blocks[i].blobID);
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
