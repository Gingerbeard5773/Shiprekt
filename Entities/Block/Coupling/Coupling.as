//coupling
#include "AccurateSoundPlay.as";
void onInit(CBlob@ this)
{
	this.addCommandID("decouple");
	this.addCommandID("couple");
	this.Tag("coupling");
	this.Tag("ramming");
	this.Tag("removable");//for corelinked checks
	
	this.getCurrentScript().tickIfTag = "attempt attachment";
	
	this.set_f32("weight", 0.1f);
}

void GetButtonsFor(CBlob@ this, CBlob@ caller)
{
	if (this.getShape().getVars().customData <= 0)
		return;

	//only owners can directly destroy the coupling
	if (this.getDistanceTo(caller) < 6 && caller.getPlayer().getUsername() == this.get_string("playerOwner"))
	{
		CButton@ button = caller.CreateGenericButton(2, Vec2f(0.0f, 0.0f), this, this.getCommandID("decouple"), "Decouple");
		if (button !is null)
		{
			button.radius = 8.0f; //engine fix
			button.enableRadius = 8.0f;
		}
	}
}

void onTick(CBlob@ this)
{
	if (!isServer()) return;

	Vec2f pos = this.getPosition();
	CBlob@[] overlapping;
	getMap().getBlobsInRadius(pos, 4.0f, @overlapping);
	
	const u8 overlappingLength = overlapping.length;
	for (u8 i = 0; i < overlappingLength; i++)
	{
		CBlob@ b = overlapping[i];
		if (b.getShape().getVars().customData > 0 // is valid block
			&& (b.getPosition() - pos).LengthSquared() < 78) //avoid corner overlaps
		{
			CBlob@[] tempArray; tempArray.push_back(this);
			getRules().push("dirtyBlocks", tempArray);

			return;
		}
	}
}

void onEndCollision(CBlob@ this, CBlob@ blob)
{
	if (isServer() && blob.getShape().getVars().customData > 0)
	{
		this.Untag("attempt attachment"); //stop ticking if we arent colliding
	}
}

void onCommand(CBlob@ this, u8 cmd, CBitStream@ params)
{
	if (cmd == this.getCommandID("decouple") && isServer())
	{
		this.server_Die();
	}
	else if (cmd == this.getCommandID("couple") && isClient())
	{
		directionalSoundPlay("mechanical_click", this.getPosition());
	}
}
