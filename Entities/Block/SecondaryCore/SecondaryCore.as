// fzzle @ 25/03/17
#include "TeamColour.as"
#include "DestructCommon.as";

const u16 SELF_DESTRUCT_SECONDS = 8;
const float BLAST_RADIUS = 100.0f;
const float HEAL_AMOUNT = 0.1f;

void onInit(CBlob@ this)
{
	this.sendonlyvisible = false; //clients always know this blob's position

	this.set_f32("weight", 12.0f);
	
	this.Tag("secondaryCore");
	this.Tag("core");

	if (isClient())
	{
		//add an additional frame to the damage frames animation
		CSprite@ sprite = this.getSprite();
		Animation@ animation = sprite.getAnimation("default");
		if (animation !is null)
		{
			array<int> frames = {3};
			animation.AddFrames(frames);
		}
	}
}

void onTick(CBlob@ this)
{
	if (isClient() && this.hasTag("critical"))
	{
		//Ship@ ship = getShipSet().getShip(this.getShape().getVars().customData);
		//ship.vel *= 0.8f;

		if (!v_fastrender)
		{
			CParticle@ particle = ParticlePixel(this.getPosition(), getRandomVelocity(90, 4, 360), getTeamColor(this.getTeamNum()), true);
			if (particle !is null)
			{
				particle.Z = 670.0f;
				particle.timeout = XORRandom(3) + 2;
			}
		}
	}
}

f32 onHit(CBlob@ this, Vec2f point, Vec2f velocity, f32 damage, CBlob@ blob, u8 customData)
{
	if (damage >= this.getHealth())
	{
		if (this.hasTag("critical")) return 0.0f;

		CPlayer@ owner = getPlayerByUsername(this.get_string("playerOwner"));
		if (owner !is null)
			this.SetDamageOwnerPlayer(owner);
		
		this.Tag("critical");
		this.server_SetTimeToDie(SELF_DESTRUCT_SECONDS);
		
		if (isClient())
		{
			Vec2f pos = this.getPosition();
			directionalSoundPlay("ShipExplosion", pos);
			makeSmallExplosionParticle(pos);
		}

		this.AddScript("Block_Explode.as");

		const int color = this.getShape().getVars().customData;
		Ship@ ship = getShipSet().getShip(color);
		if (ship is null || ship.isMothership) return 0.0f;
		
		const u16 blocksLength = ship.blocks.length;
		if (blocksLength < 10) return 0.0f;

		for (u16 i = 0; i < blocksLength; ++i)
		{
			CBlob@ blob = getBlobByNetworkID(ship.blocks[i].blobID);
			if (blob !is null && this.getTeamNum() == blob.getTeamNum())
			{
				if (i % 4 == 0 && !blob.hasTag("coupling"))
				{
					blob.AddScript("Block_Explode.as");
				}
			}
		}

		return 0.0f;
	}

	return damage;
}

void onDie(CBlob@ this)
{
	if (this.getShape().getVars().customData > 0)
	{
		if (!this.hasTag("disabled"))
			Destruct::self(this, BLAST_RADIUS);
	}
}
